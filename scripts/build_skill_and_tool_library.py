#!/usr/bin/env python3
"""
Builds the Zero-MCP NovaForge Skill & Native Tool Library:
1. Ports MIT-licensed pure game-dev skills & engine tool schemas from Summer into
   Zero-MCP `nova_*` native in-engine tool calls (excluding closed cloud/store lock-in).
2. Generates 15 NovaForge-exclusive skills (Colibri Multi-Brain Council, Hybrid C++/Blueprint,
   Blender Zero-Config PBR, Video-to-Motion Mocap, Live Cutscene Sequencer, Smart Objects,
   Voronoi 3D Destruction, Evolving Living NPCs, Visual Quality Tiers, All Genres/2.5D, etc.).
3. Compiles `library/registry.json` with bilingual (Persian + English) routing tags.
"""

import json
import os
import re
import shutil
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SUMMER_SRC = Path("/tmp/summer_mit")
LIB_SKILLS = REPO_ROOT / "library" / "skills"
LIB_TOOLS = REPO_ROOT / "library" / "tools"
KERNELS_DIR = REPO_ROOT / "addons" / "novaforge_engine" / "agent" / "kernels"

EXCLUDED_SKILL_PREFIXES = (
    "summer-",
    "in-game-purchases",
    "store-art",
    "store-listing",
    "grow-analytics",
    "navigate-summer",
    "using-summer",
    "running-in-the-cloud",
    "publish-your-game",
    "remote-deploy",
)

EXCLUDED_TOOL_PREFIXES = (
    "api-",
    "app-",
    "store-",
    "publish-build",
    "go-live",
    "get-board",
    "sync-items",
    "list-my-assets",
    "get-asset-download-url",
    "import-asset-by-id",
    "library-feedback",
)

NOVAFORGE_CUSTOM_SKILLS = [
    {
        "slug": "colibri-multi-brain-council",
        "summary": "Orchestrate multiple local AI brains (Director, C++/Blueprint Coder, 3D Artist, Mocap Animator, QA Critic) via Colibrì VRAM/RAM/NVMe streaming.",
        "category": "ai-architecture",
        "tags_fa": ["چند مغز", "کولیبری", "هوش مصنوعی لوکال", "شورای هوش مصنوعی", "حافظه"],
        "tags_en": ["colibri", "multi-brain", "council", "local-ai", "moe", "vram-relay"],
        "body": """# Colibrì Multi-Brain Council (Zero-MCP Local Orchestration)

NovaForge runs a **5-Brain Specialist Council** directly inside the engine without MCP:
1. **DirectorBrain (`NOVA_BRAIN_DIRECTOR`)**: Breaks the user's Persian/English prompt into mechanics, camera mode, scene tree, and asset requirements.
2. **CoderBrain (`NOVA_BRAIN_CODER_CPP_BP`)**: Synthesizes hybrid `BlueprintGraph` nodes, `GDExtension` C++20 modules, and `GDScript` controllers.
3. **Artist3DBrain (`NOVA_BRAIN_ARTIST_3D_TEX`)**: Drives local Image-to-3D, Blender material auto-binding, lighting, and Visual Quality Tier presets.
4. **AnimatorCinematicsBrain (`NOVA_BRAIN_ANIMATOR_MOCAP`)**: Runs Auto-Rigging, Video-to-Motion IK cleanup, and the In-Engine Cutscene Sequencer.
5. **CriticQABrain (`NOVA_BRAIN_CRITIC_QA`)**: Executes `nova_scene_audit`, headless/viewport playtesting, and merges all specialist outputs into **one verified result**.

## Memory Rule
Always invoke `NovaBrainCouncil.run_council_task(prompt, active_modalities)` so `libnova_core` streams MoE experts from NVMe SSD and flushes GPU VRAM (`colibri_flush_vram_for_renderer`) before returning control to Godot's Vulkan renderer.
""",
    },
    {
        "slug": "blueprint-cpp-hybrid",
        "summary": "Build gameplay simultaneously with Visual Blueprint Node Graphs, Native C++20 GDExtension, and GDScript.",
        "category": "scripting-architecture",
        "tags_fa": ["بلوپرینت", "سی پلاس پلاس", "کدنویسی", "گراف", "اسکریپت"],
        "tags_en": ["blueprint", "cpp", "c++", "visual-scripting", "gdextension", "transpiler"],
        "body": """# Hybrid Blueprint + C++20 + GDScript Workflow

Every gameplay mechanic in NovaForge can be authored or AI-generated as a **Visual Blueprint Graph** (`res://addons/novaforge_engine/blueprint/blueprint_resource.gd`) and compiled cleanly to either **GDScript** or **Native C++20 (`GDExtension`)**.

## Core Nodes
- `Event_BeginPlay`, `Event_Tick`, `Event_OnAttackInput`, `Event_OnInteract`, `Event_OnCutsceneTrigger`
- `Flow_Branch`, `Flow_Sequence`
- `MoveCharacter`, `PlayMeleeCombo`, `ApplyDamage`, `DodgeRoll`, `SpawnVFX`, `FractureObject`, `TriggerCutscene`

Use `nova_compile_blueprint(graph_path, target="cpp"|"gdscript")` to hot-compile any Blueprint graph.
""",
    },
    {
        "slug": "blender-zero-config-materials",
        "summary": "Import .blend, .glb, .gltf, .fbx, .obj, .dae, .usd, .abc, .ply, .stl with 100% automatic PBR texture discovery & DirectX/OpenGL normal auto-fix.",
        "category": "asset-pipeline",
        "tags_fa": ["بلندر", "تکسچر", "متریال", "فرمت", "ایمپورت", "نرمال مپ"],
        "tags_en": ["blender", "blend", "fbx", "glb", "usd", "alembic", "pbr", "auto-texture", "normal-map"],
        "body": """# Universal Blender Importer & Zero-Config Auto-Material Binder

Never ask the user to manually wire textures. When importing any 3D file (`.blend`, `.glb`, `.gltf`, `.fbx`, `.obj`, `.dae`, `.usd/.usdz`, `.abc`, `.ply`, `.stl`):
1. Call `nova_import_blender_asset(path)` which runs the **4-Stage Smart PBR Resolver**:
   - Unpacks embedded textures.
   - Fuzzy-scans `textures/`, `maps/`, `materials/`, and sibling folders to heal broken absolute paths.
   - Classifies `_Albedo/_BaseColor`, `_Normal` (auto-detecting DirectX vs OpenGL green channel orientation and flipping Y when needed), `_Roughness` vs `_Glossiness` (auto-inverting gloss), `_Metallic`, `_AO`, `_ORM` (channel-packed R=AO, G=Roughness, B=Metallic), `_Emission`, and `_Opacity`.
   - Invokes `pipelines/blender_bridge/blend_extractor.py` when procedural Blender `Principled BSDF` shader graphs need headless PBR baking.
""",
    },
    {
        "slug": "video-to-motion-mocap",
        "summary": "Extract 3D world-space root motion, body joints, fingers, face, Foot-Locking IK, and automatic combat hitbox keyframes from any video.",
        "category": "animation-mocap",
        "tags_fa": ["ویدیو", "انیمیشن", "دویدن", "جنگیدن", "فایت", "موشن کپچر", "حرکت"],
        "tags_en": ["video-to-motion", "mocap", "foot-locking", "ik", "combat-tagging", "retarget"],
        "body": """# AI Video-to-Motion & Physics Mocap Studio

When a user supplies a reference video (`.mp4`, `.mov`, `.webm`) of a specific run style, martial-arts combo, or gesture:
1. Run `nova_video_to_motion(video_path, target_skeleton_path, motion_kind)`.
2. The pipeline (`pipelines/mocap/video_to_motion.py`) extracts 52-bone 3D world-space trajectories + root motion + finger curl + facial blendshapes.
3. Physics cleanup removes jitter (Savitzky-Golay filter), enforces anatomical joint limits, and locks planted feet via **Foot-Locking IK** (zero moonwalking/sliding).
4. **Auto-Combat Tagging** detects peak limb angular/linear velocity frames and automatically inserts `Hitbox3D` active windows, `vfx-hit-spark` triggers, and impact SFX events onto the generated Godot `Animation` resource.
""",
    },
    {
        "slug": "in-engine-cutscene-sequencer",
        "summary": "Author Blender-grade Pose/IK, Bezier Graph Editor, NLA layers, and seamless real-time cutscenes directly in-engine ('این تیکه کات‌سینه').",
        "category": "cinematics",
        "tags_fa": ["کات سین", "انیمیشن سازی", "بلندر", "دوربین سینمایی", "تایم لاین"],
        "tags_en": ["cutscene", "sequencer", "pose-mode", "ik", "graph-editor", "nla", "seamless-camera"],
        "body": """# In-Engine Blender-Grade Animation & Live Cutscene Director

Never require pre-rendered `.mp4` videos from Blender for story moments. When the user marks a moment as a cutscene (*"این تیکه کات‌سینه"*):
1. Spawn a `CutsceneTrigger3D` + `CutsceneDirector` timeline via `nova_create_cutscene(...)`.
2. Lock player input smoothly while blending the active gameplay `Camera3D` transform into the `CutsceneCameraRig` (zero black screen!).
3. Drive character poses via **In-Engine Pose/IK**, **Bezier Graph Curves**, **NLA Animation Layers**, focal rack-focus DOF, time-dilation slow-mo, and optional **QTE** prompts, then blend seamlessly back to gameplay!
""",
    },
    {
        "slug": "smart-interactive-objects",
        "summary": "Click any 3D prop in the viewport to open the Smart Context Menu: doors/chests with auto-hinge, pickups, weapons, physics traps, or custom AI prompts.",
        "category": "interactive-world",
        "tags_fa": ["آبجکت", "کلیک", "منو", "اینترکت", "تعامل", "در", "سلاح"],
        "tags_en": ["smart-object", "interactable", "context-menu", "door-hinge", "pickup", "equip"],
        "body": """# Smart Context-Click Object Behaviors

Any `Node3D` / `MeshInstance3D` in the scene can be configured with one click via `SmartObjectBehavior3D`:
- **Interactable**: Auto-detects bounding-box hinge edge for doors/chests, adds `[E]` prompt + outline shader, supports Pickup/Inventory, Weapon Equip, Lever/Button, Ladder, and Seat.
- **Custom Prompt Box**: Synthesizes bespoke Blueprint/GDScript logic directly onto the clicked object.
""",
    },
    {
        "slug": "voronoi-3d-destruction",
        "summary": "Real-time 3D Voronoi mesh fracturing with Jolt Physics rigid shards for glass, wood, stone, metal, and explosive barrels.",
        "category": "physics-destruction",
        "tags_fa": ["تخریب", "شکستن", "سلاح", "انفجار", "تیکه تیکه", "فیزیک"],
        "tags_en": ["destruction", "fracture", "voronoi", "shatter", "jolt-physics", "explosive"],
        "body": """# Real-Time 3D Voronoi Mesh Destruction

Enable destructibility on any prop via `nova_configure_smart_object(node_path, destructible=true, material="STONE"|"GLASS"|"WOOD"|"METAL"|"EXPLOSIVE_BARREL", shard_count=16)`:
- Uses the C++20 `VoronoiFracturer` kernel (`libnova_core`) or GDScript fallback to slice the mesh around the exact weapon/bullet impact point into watertight convex Jolt `RigidBody3D` shards with radial blast impulses, debris VFX, and acoustic SFX.
""",
    },
    {
        "slug": "living-evolving-npcs",
        "summary": "Modular checkbox NPC traits + Evolving Life & Nemesis AI where NPC careers, wealth, families, scars, and combat tactics progress alongside game time.",
        "category": "npc-ai",
        "tags_fa": ["ان پی سی", "زندگی", "هوشمند", "پیشرفت", "حافظه", "انتقام", "دیالوگ"],
        "tags_en": ["npc", "living-world", "evolving-life", "nemesis", "memory", "daily-routine", "free-talk"],
        "body": """# Living & Evolving NPCs (Modular Checkbox System + World Life Tick)

Attach `LivingNPCBrain3D` to any character and toggle only the options needed:
- **Roles**: Citizen, Merchant/Blacksmith, Guard, Companion, Enemy, Boss, Faction Leader.
- **Senses & Combat**: Vision cone, acoustic hearing, tactical flanking, limb-specific locational damage.
- **Free-Talk AI + Local TTS**: Dynamic character-consistent speech & lip-sync.
- **Evolving Life & Nemesis AI (`enable_evolving_life = true`)**: Managed off-screen at near-zero CPU cost by `NovaWorldLife`. As chapters/days advance, NPCs earn/lose wealth, upgrade shops, form alliances/families, remember player kindness or betrayal, gain visible battle scars, and adapt counters against the player's most frequent attack combos!
""",
    },
    {
        "slug": "visual-quality-tiers",
        "summary": "Switch instantly between AAA Unreal-Grade (Vulkan SDFGI/SSR/Volumetric/ACES), Standard Unity-Style, and Indie Stylized (Cel-Shade, Low-Poly, HD-2D, PSX).",
        "category": "rendering-quality",
        "tags_fa": ["کیفیت", "گرافیک", "آنریل", "یونیتی", "ایندی", "پیکسلی", "کارتونی"],
        "tags_en": ["quality-tier", "aaa", "unreal-grade", "unity-style", "indie", "cel-shaded", "hd-2d", "psx"],
        "body": """# One-Click Optional Visual Quality & Art-Style Tiers

Call `NovaQuality.apply_quality_tier(tier_name)` to reconfigure `WorldEnvironment`, directional shadow cascades, MSAA/FSR upscaling, shader overrides, and AI 3D polygon budgets simultaneously:
- `AAA_UNREAL`: Forward+, SDFGI, SSR, SSIL, Volumetric Fog, ACES Filmic tonemap, 4K PBR, High-Poly LOD0.
- `STANDARD_UNITY`: Balanced LightmapGI + crisp real-time shadows, clean PBR, 60+ FPS target.
- `INDIE_CEL_ANIME`: Toon shader (`shaders/cel_toon_outline.gdshader`) with crisp ink outlines.
- `INDIE_LOWPOLY_COZY`: Warm gradient sky, soft ambient occlusion, flat-shaded low-poly decimation.
- `INDIE_HD2D`: Sprite3D pixel characters in full 3D lit environments with tilt-shift depth-of-field.
- `INDIE_PSX_RETRO`: Vertex jitter snapping + affine UV + Bayer dithering (`shaders/psx_retro.gdshader`).
""",
    },
    {
        "slug": "all-genre-perspectives",
        "summary": "Runtime-switchable camera perspectives (FPS, TPS Over-Shoulder, TPS Souls Lock-On, 2.5D Side/Spline, HD-2D, Isometric/RTS, 2D, Fixed) + 10 Genre Kits.",
        "category": "genres-cameras",
        "tags_fa": ["ژانر", "اول شخص", "سوم شخص", "۲.۵ بعدی", "ایزومتریک", "سبک بازی"],
        "tags_en": ["fps", "tps", "2.5d", "hd-2d", "isometric", "rts", "souls-like", "fighting", "racing", "survival"],
        "body": """# All Camera Perspectives & Multi-Genre Gameplay Kits

Use `PerspectiveCameraRig3D` + `GenreKitAssembler` (`addons/novaforge_engine/genres/`) to instantiate or hot-swap perspectives mid-gameplay (e.g., transitioning seamlessly from 3D TPS to 2.5D side-scrolling boss arena) and mix any of the 10 built-in genre kits: Action/Souls-like, Shooter, 2.5D/3D Fighting, Platformer, Survival/Crafting, RPG, Vehicle/Racing, Horror/Stealth, RTS/Tower Defense, and Roguelike.
""",
    },
    {
        "slug": "elemental-weather-chemistry",
        "summary": "Dynamic weather, 24h day/night cycle, and systemic Fire/Water/Wind/Lightning chemistry reactions.",
        "category": "world-systems",
        "tags_fa": ["آب و هوا", "باران", "آتش", "برف", "شب و روز", "عناصر"],
        "tags_en": ["weather", "day-night", "elemental-chemistry", "fire", "water", "lightning", "wind"],
        "body": """# Dynamic Weather & Elemental Chemistry System

`ElementalWorldSystem` (`addons/novaforge_engine/world/elemental_weather_system.gd`) couples weather with systemic physics:
- Fire ignites dry grass/wood and spreads along Wind direction.
- Rain/Water extinguishes Fire, spawns steam VFX, and increases surface wetness/slipperiness.
- Lightning conducts through wet surfaces and water bodies to shock nearby Hurtboxes.
""",
    },
    {
        "slug": "open-world-chunk-streaming",
        "summary": "Stream large open worlds in spatial chunks with Auto-LOD mesh optimization and background NPC simulation.",
        "category": "world-systems",
        "tags_fa": ["جهان باز", "استریم مپ", "نقشه بزرگ", "بهینه سازی", "فریم ریت"],
        "tags_en": ["open-world", "chunk-streaming", "auto-lod", "culling", "terrain"],
        "body": """# Open-World Spatial Chunk Streaming & Auto-LOD

`WorldChunkStreamer3D` partitions large maps into `Chunk(gx, gz)` cells around the active player camera, streaming high-detail scenes within the near ring, low-poly LOD proxies in the mid ring, and handing off unloaded NPCs to `NovaWorldLife` background simulation.
""",
    },
    {
        "slug": "world-persistence-timemachine",
        "summary": "Save/Load full living-world state (fractured objects + evolved NPCs) & revert editor AI changes via Project Time-Machine snapshots.",
        "category": "persistence-tooling",
        "tags_fa": ["سیو", "لود", "ذخیره بازی", "تایم ماشین", "برگشت به قبل"],
        "tags_en": ["save-load", "world-persistence", "time-machine", "snapshot", "undo"],
        "body": """# Smart Living-World Persistence & Editor Time-Machine

- **In-Game Save/Load (`WorldPersistenceManager`)**: Serializes player inventory, destroyed Voronoi prop IDs, quest flags, and every `LivingNPCBrain3D` biography/wealth/scar/memory delta into compact binary/JSON save slots.
- **Editor Time-Machine (`NovaTimeMachine`)**: Automatically records lightweight project snapshots before every Multi-Brain AI operation for instant 1-click rollback.
""",
    },
    {
        "slug": "persian-rtl-smart-ui",
        "summary": "Build responsive HUDs, menus, radial wheels, controller/touch bindings, and native Persian RTL UI with HarfBuzz shaping & local AI localization.",
        "category": "ui-localization",
        "tags_fa": ["فارسی", "رابط کاربری", "منو", "راست به چپ", "ترجمه", "دسته بازی"],
        "tags_en": ["persian", "rtl", "ui", "hud", "localization", "gamepad", "touch-controls"],
        "body": """# Smart UI Builder, Native Persian RTL & Auto-Localization

Configured with Godot 4's `ICU / HarfBuzz / Graphite` text driver so Persian typography, ligatures, and bidirectional numbers render flawlessly. Use `SmartUIBuilder` to generate health/stamina HUDs, minimaps, dialogue subtitles, and multi-language translation tables offline.
""",
    },
    {
        "slug": "one-click-colibri-ship",
        "summary": "One-click multi-platform game export (Windows, Linux, macOS, Android, iOS, Web) bundling the lightweight Colibrì C runtime for living-NPC games.",
        "category": "export-release",
        "tags_fa": ["خروجی", "اکسپورت", "ساخت بازی", "ویندوز", "اندروید", "انتشار"],
        "tags_en": ["export", "build", "installer", "colibri-runtime", "windows", "android", "web"],
        "body": """# One-Click Game Packager & Embedded Colibrì Ship Pipeline

`OneClickExporter` (`addons/novaforge_engine/world/one_click_exporter.gd`) runs `nova_scene_audit`, strips editor-only caches, compiles active Blueprints to native C++/GDScript, and—if any `LivingNPCBrain3D` uses runtime AI dialogue—bundles `libnova_core` + quantized micro-weights directly alongside the exported executable.
""",
    },
]

NOVA_EXTRA_TOOLS = [
    ("nova_compile_blueprint", "Compile a visual Blueprint graph into GDScript or C++20 GDExtension code.", ["scripting", "blueprint", "cpp"]),
    ("nova_import_blender_asset", "Import .blend/.glb/.fbx/.obj/.dae/.usd/.abc/.ply/.stl and auto-bind PBR textures.", ["3d", "blender", "materials"]),
    ("nova_image_to_3d", "Generate a watertight 3D mesh + PBR texture + 3 LODs locally from an image or text prompt.", ["3d", "local-ai", "character"]),
    ("nova_auto_rig_character", "Fit a 52-bone Humanoid Skeleton3D with geodesic skin weights and retarget animations.", ["rigging", "skeleton", "animation"]),
    ("nova_video_to_motion", "Extract 3D root motion, body/finger/face animation, Foot-Locking IK & hitbox tags from video.", ["mocap", "video", "combat"]),
    ("nova_create_cutscene", "Create a live in-engine cutscene trigger, camera rail, rack-focus DOF & seamless gameplay blend.", ["cutscene", "cinematics", "camera"]),
    ("nova_configure_smart_object", "Attach interactive door/pickup/weapon/lever or Voronoi 3D destruction behaviors to a 3D prop.", ["smart-object", "destruction", "jolt"]),
    ("nova_configure_living_npc", "Configure modular NPC senses, combat tactics, free-talk voice & Evolving Life / Nemesis AI.", ["npc", "evolving-life", "ai"]),
    ("nova_set_visual_quality", "Switch visual tier between AAA_UNREAL, STANDARD_UNITY, INDIE_CEL_ANIME, INDIE_LOWPOLY_COZY, INDIE_HD2D, INDIE_PSX_RETRO.", ["rendering", "quality", "shaders"]),
    ("nova_set_camera_perspective", "Switch camera & movement rig between FPS, TPS_SHOULDER, TPS_SOULS, SIDE_2_5D, HD_2D, ISOMETRIC, PURE_2D, FIXED_CINEMATIC.", ["camera", "genre", "2.5d"]),
    ("nova_run_council_prompt", "Dispatch a prompt across the 5-Brain Local AI Council via Colibrì tiered memory.", ["council", "colibri", "local-ai"]),
    ("nova_time_machine_snapshot", "Create or restore an instant project snapshot before/after AI edits.", ["undo", "snapshot", "safety"]),
]


def rewrite_to_zero_mcp(text: str) -> str:
    text = re.sub(r"\bsummer_([a-z0-9_]+)", r"nova_\1", text)
    text = text.replace("Summer MCP", "NovaForge Zero-MCP Native Bus")
    text = text.replace("summerengine.com", "local://novaforge-hub")
    return text


def extract_frontmatter_summary(md_text: str, fallback: str) -> tuple[str, str]:
    desc = fallback
    cat = "gameplay"
    m_desc = re.search(r'^description:\s*"?([^"\n]+)"?', md_text, re.MULTILINE)
    if m_desc:
        desc = m_desc.group(1).strip()
    m_cat = re.search(r'^category:\s*"?([^"\n]+)"?', md_text, re.MULTILINE)
    if m_cat:
        cat = m_cat.group(1).strip()
    return desc, cat


def main() -> None:
    LIB_SKILLS.mkdir(parents=True, exist_ok=True)
    LIB_TOOLS.mkdir(parents=True, exist_ok=True)
    KERNELS_DIR.mkdir(parents=True, exist_ok=True)

    skills_index = []
    tools_index = []

    # 1. Port open-source MIT game-development skills
    if (SUMMER_SRC / "library" / "skills").exists():
        for entry in sorted((SUMMER_SRC / "library" / "skills").iterdir()):
            if not entry.is_dir():
                continue
            slug = entry.name
            if any(slug.startswith(p) for p in EXCLUDED_SKILL_PREFIXES):
                continue

            dest_dir = LIB_SKILLS / slug
            dest_dir.mkdir(parents=True, exist_ok=True)

            skill_md = entry / "SKILL.md"
            summary = f"Game development skill: {slug}"
            category = "game-development"
            if skill_md.exists():
                raw = skill_md.read_text(encoding="utf-8", errors="replace")
                summary, category = extract_frontmatter_summary(raw, summary)
                adapted = rewrite_to_zero_mcp(raw)
                (dest_dir / "SKILL.md").write_text(adapted, encoding="utf-8")

            res_yaml = entry / "resource.yaml"
            if res_yaml.exists():
                raw_y = res_yaml.read_text(encoding="utf-8", errors="replace")
                (dest_dir / "resource.yaml").write_text(rewrite_to_zero_mcp(raw_y), encoding="utf-8")

            skills_index.append({
                "id": f"skill/{slug}",
                "slug": slug,
                "category": category,
                "summary": summary,
                "origin": "mit-adapted",
                "tags": slug.split("-") + [category],
            })

    # 2. Add NovaForge Custom Skills (with Persian + English routing tags)
    for item in NOVAFORGE_CUSTOM_SKILLS:
        slug = item["slug"]
        dest_dir = LIB_SKILLS / slug
        dest_dir.mkdir(parents=True, exist_ok=True)
        frontmatter = (
            f"---\n"
            f"name: {slug}\n"
            f'description: "{item["summary"]}"\n'
            f"license: MIT\n"
            f"category: {item['category']}\n"
            f"execution: zero-mcp-native\n"
            f"---\n\n"
        )
        (dest_dir / "SKILL.md").write_text(frontmatter + item["body"], encoding="utf-8")
        skills_index.append({
            "id": f"skill/{slug}",
            "slug": slug,
            "category": item["category"],
            "summary": item["summary"],
            "origin": "novaforge-native",
            "tags": item["tags_en"] + item["tags_fa"],
        })

    # 3. Port pure engine tool descriptors to Zero-MCP `nova_*` tools
    if (SUMMER_SRC / "library" / "tools").exists():
        for entry in sorted((SUMMER_SRC / "library" / "tools").iterdir()):
            if not entry.is_dir():
                continue
            slug = entry.name
            if any(slug.startswith(p) for p in EXCLUDED_TOOL_PREFIXES):
                continue
            res_yaml = entry / "resource.yaml"
            if not res_yaml.exists():
                continue
            raw_y = res_yaml.read_text(encoding="utf-8", errors="replace")
            m_sum = re.search(r"^summary:\s*(.+)$", raw_y, re.MULTILINE)
            summary = m_sum.group(1).strip() if m_sum else f"Native engine tool {slug}"
            nova_tool_name = "nova_" + slug.replace("-", "_")
            tools_index.append({
                "tool_name": nova_tool_name,
                "slug": slug,
                "summary": rewrite_to_zero_mcp(summary),
                "transport": "direct-in-engine-bus (zero-mcp)",
            })

    for t_name, t_sum, t_tags in NOVA_EXTRA_TOOLS:
        tools_index.append({
            "tool_name": t_name,
            "slug": t_name.replace("nova_", "").replace("_", "-"),
            "summary": t_sum,
            "tags": t_tags,
            "transport": "direct-in-engine-bus (zero-mcp)",
        })

    # 4. Copy & localize MIT scene_audit, seeing_probe, and autopilot kernels
    kernel_files = [
        ("assets/audit/scene_audit.gd", "scene_audit.gd"),
        ("assets/seeing/seeing_probe.gd", "seeing_probe.gd"),
        ("assets/autopilot/autopilot.gd", "autopilot.gd"),
        ("assets/autopilot/probe_base.gd", "probe_base.gd"),
    ]
    for rel_src, dst_name in kernel_files:
        src_p = SUMMER_SRC / rel_src
        if src_p.exists():
            txt = src_p.read_text(encoding="utf-8", errors="replace")
            (KERNELS_DIR / dst_name).write_text(rewrite_to_zero_mcp(txt), encoding="utf-8")

    # 5. Write unified registry
    registry = {
        "engine": "NovaForge AI Game Engine",
        "version": "1.0.0",
        "architecture": "Zero-MCP Native In-Engine Bus + Colibri Multi-Brain Council",
        "total_skills": len(skills_index),
        "total_native_tools": len(tools_index),
        "skills": skills_index,
        "tools": tools_index,
    }
    (REPO_ROOT / "library" / "registry.json").write_text(
        json.dumps(registry, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    (LIB_TOOLS / "native_tools_catalog.json").write_text(
        json.dumps(tools_index, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"Built {len(skills_index)} skills and {len(tools_index)} Zero-MCP native engine tools!")


if __name__ == "__main__":
    main()
