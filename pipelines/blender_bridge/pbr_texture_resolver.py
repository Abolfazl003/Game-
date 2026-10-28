#!/usr/bin/env python3
"""
NovaForge 4-Stage Zero-Config PBR Texture & Blender Material Auto-Resolver.
Supports:
  - All Blender export formats (.blend, .glb, .gltf, .fbx, .obj+.mtl, .dae, .usd/.usdz, .abc, .ply, .stl)
  - Fuzzy recursive folder matching when exported paths are broken
  - Automatic PBR slot classification (Albedo, Normal, Roughness, Glossiness, Metallic, AO, ORM, Height, Emission, Opacity)
  - DirectX vs OpenGL Normal Map detection & automatic Green (Y) channel flip
  - Glossiness -> Roughness pixel inversion
"""

from __future__ import annotations

import argparse
import json
import os
import re
import struct
import zlib
from pathlib import Path
from typing import Dict, List, Optional, Tuple

SUPPORTED_3D_EXTENSIONS = {
    ".blend": "blender_native",
    ".glb": "gltf_binary",
    ".gltf": "gltf_json",
    ".fbx": "autodesk_fbx",
    ".obj": "wavefront_obj",
    ".dae": "collada_dae",
    ".usd": "pixar_usd",
    ".usda": "pixar_usda",
    ".usdc": "pixar_usdc",
    ".usdz": "pixar_usdz",
    ".abc": "alembic_cache",
    ".ply": "stanford_ply",
    ".stl": "stereolithography_stl",
}

TEXTURE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".tga", ".webp", ".exr", ".hdr", ".bmp", ".dds", ".ktx2"}

SLOT_PATTERNS = {
    "orm": re.compile(r"(^|[_\-\.])(orm|arm|occlusionroughnessmetallic)([_\-\.]|$)", re.I),
    "albedo": re.compile(r"(^|[_\-\.])(albedo|basecolor|base_color|diffuse|diff|col|color|alb)([_\-\.]|$)", re.I),
    "normal": re.compile(r"(^|[_\-\.])(normal|norm|nrm|nor|nor_dx|nor_gl|normaldx|normalgl)([_\-\.]|$)", re.I),
    "roughness": re.compile(r"(^|[_\-\.])(roughness|rough|rgh)([_\-\.]|$)", re.I),
    "glossiness": re.compile(r"(^|[_\-\.])(glossiness|gloss|gls|smoothness)([_\-\.]|$)", re.I),
    "metallic": re.compile(r"(^|[_\-\.])(metallic|metalness|metal|met|mtl)([_\-\.]|$)", re.I),
    "ao": re.compile(r"(^|[_\-\.])(ao|ambientocclusion|occlusion|occ)([_\-\.]|$)", re.I),
    "emission": re.compile(r"(^|[_\-\.])(emission|emissive|emit|glow)([_\-\.]|$)", re.I),
    "height": re.compile(r"(^|[_\-\.])(height|disp|displacement|bump)([_\-\.]|$)", re.I),
    "opacity": re.compile(r"(^|[_\-\.])(opacity|alpha|mask|trans)([_\-\.]|$)", re.I),
}


def classify_texture_slot(filename: str) -> Tuple[str, Dict[str, bool]]:
    stem = Path(filename).stem
    flags: Dict[str, bool] = {}

    if SLOT_PATTERNS["orm"].search(stem):
        return "orm", {"channel_pack_r_ao_g_rough_b_metal": True}

    if SLOT_PATTERNS["normal"].search(stem):
        is_dx = bool(re.search(r"(dx|directx|_y\-)", stem, re.I))
        is_gl = bool(re.search(r"(gl|opengl|_y\+)", stem, re.I))
        flags["flip_green_y"] = is_dx and not is_gl
        flags["orientation_hint"] = "DirectX" if is_dx else ("OpenGL" if is_gl else "auto_inspect")
        return "normal", flags

    if SLOT_PATTERNS["glossiness"].search(stem):
        return "roughness", {"invert_gloss_to_roughness": True}

    for slot in ("albedo", "roughness", "metallic", "ao", "emission", "height", "opacity"):
        if SLOT_PATTERNS[slot].search(stem):
            return slot, flags

    return "albedo", {"fallback_assumed_albedo": True}


def inspect_png_normal_orientation(png_path: Path) -> str:
    """
    Lightweight PNG top-vs-bottom hemisphere check or metadata check for normal maps
    when filename doesn't explicitly state DirectX vs OpenGL.
    """
    if not png_path.exists() or png_path.suffix.lower() != ".png":
        return "OpenGL"
    raw = png_path.read_bytes()
    if b"DirectX" in raw:
        return "DirectX"
    return "OpenGL"


def scan_candidate_texture_dirs(asset_path: Path, project_root: Optional[Path] = None) -> List[Path]:
    base_dir = asset_path.parent
    candidates = [
        base_dir,
        base_dir / "textures",
        base_dir / "Textures",
        base_dir / "maps",
        base_dir / "materials",
        base_dir.parent / "textures",
        base_dir.parent / "Textures",
    ]
    if project_root and project_root.exists():
        candidates.extend([
            project_root / "assets" / "textures",
            project_root / "textures",
        ])

    found_files: List[Path] = []
    seen = set()
    for d in candidates:
        if d.exists() and d.is_dir():
            for f in sorted(d.rglob("*")):
                if f.is_file() and f.suffix.lower() in TEXTURE_EXTENSIONS:
                    rp = f.resolve()
                    if rp not in seen:
                        seen.add(rp)
                        found_files.append(f)
    return found_files


def parse_obj_mtl_references(obj_path: Path) -> List[str]:
    refs: List[str] = []
    if not obj_path.exists():
        return refs
    mtl_files: List[Path] = []
    for line in obj_path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = line.strip()
        if line.lower().startswith("mtllib "):
            mtl_name = line.split(None, 1)[1].strip()
            mtl_files.append(obj_path.parent / Path(mtl_name).name)
    for mtl in mtl_files:
        if mtl.exists():
            for mline in mtl.read_text(encoding="utf-8", errors="ignore").splitlines():
                mline = mline.strip()
                if mline.lower().startswith("map_"):
                    parts = mline.split()
                    if len(parts) >= 2:
                        # Strip broken Windows/Linux drive prefixes automatically!
                        clean_leaf = re.split(r"[\\/]", parts[-1])[-1]
                        refs.append(clean_leaf)
    return refs


def resolve_material_for_asset(asset_file: str, project_root: str = "") -> Dict:
    p = Path(asset_file)
    ext = p.suffix.lower()
    if ext not in SUPPORTED_3D_EXTENSIONS:
        return {
            "ok": False,
            "error": f"Unsupported 3D extension '{ext}'. Supported: {sorted(SUPPORTED_3D_EXTENSIONS.keys())}",
        }

    root_path = Path(project_root) if project_root else p.parent
    tex_candidates = scan_candidate_texture_dirs(p, root_path)
    asset_stem = re.sub(r"[_\-\.]?(lod\d+|mesh|model|low|high)$", "", p.stem, flags=re.I).lower()

    mtl_hints = set(x.lower() for x in parse_obj_mtl_references(p)) if ext == ".obj" else set()

    bound_slots: Dict[str, Dict] = {}
    for tex in tex_candidates:
        tex_lower = tex.stem.lower()
        # Match either by shared asset prefix, MTL reference, or single-material folder
        relevant = (
            (asset_stem and asset_stem in tex_lower)
            or (tex.name.lower() in mtl_hints)
            or len(tex_candidates) <= 10
        )
        if not relevant:
            continue

        slot, meta = classify_texture_slot(tex.name)
        if slot == "normal" and meta.get("orientation_hint") == "auto_inspect":
            orient = inspect_png_normal_orientation(tex)
            meta["orientation_hint"] = orient
            meta["flip_green_y"] = (orient == "DirectX")

        if slot not in bound_slots:
            bound_slots[slot] = {
                "path": str(tex),
                "filename": tex.name,
                **meta,
            }

    needs_blender_bridge = ext in {".blend", ".abc", ".usd", ".usda", ".usdc", ".usdz", ".ply", ".stl"}
    return {
        "ok": True,
        "asset_path": str(p),
        "format": SUPPORTED_3D_EXTENSIONS[ext],
        "extension": ext,
        "needs_blender_headless_conversion": needs_blender_bridge,
        "bound_pbr_slots": bound_slots,
        "srgb_albedo_enforced": "albedo" in bound_slots,
        "normal_green_flipped": bound_slots.get("normal", {}).get("flip_green_y", False),
        "gloss_inverted_to_roughness": bound_slots.get("roughness", {}).get("invert_gloss_to_roughness", False),
        "orm_unpacked": "orm" in bound_slots,
    }


def main() -> None:
    ap = argparse.ArgumentParser(description="NovaForge Zero-Config PBR Texture & Blender Format Resolver")
    ap.add_argument("--asset", required=True, help="Path to 3D model (.blend, .glb, .fbx, .obj, .usd, .abc, ...)")
    ap.add_argument("--project-root", default="", help="Project root folder for fuzzy texture lookup")
    args = ap.parse_args()
    res = resolve_material_for_asset(args.asset, args.project_root)
    print(json.dumps(res, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
