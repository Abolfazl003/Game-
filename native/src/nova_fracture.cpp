#include "nova_fracture.hpp"

#include <cmath>
#include <algorithm>

namespace nova {

namespace {

float dot3(const Vec3& a, const Vec3& b) {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

Vec3 cross3(const Vec3& a, const Vec3& b) {
    return {
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    };
}

float length3(const Vec3& v) {
    return std::sqrt(dot3(v, v));
}

Vec3 normalize3(const Vec3& v) {
    float len = length3(v);
    if (len < 1e-6f) return {0.0f, 1.0f, 0.0f};
    return v * (1.0f / len);
}

struct PolygonFace {
    std::vector<Vec3> loop;
};

struct ConvexCell {
    std::vector<PolygonFace> faces;
};

ConvexCell make_box_cell(const Vec3& mn, const Vec3& mx) {
    Vec3 v000{mn.x, mn.y, mn.z};
    Vec3 v100{mx.x, mn.y, mn.z};
    Vec3 v110{mx.x, mx.y, mn.z};
    Vec3 v010{mn.x, mx.y, mn.z};
    Vec3 v001{mn.x, mn.y, mx.z};
    Vec3 v101{mx.x, mn.y, mx.z};
    Vec3 v111{mx.x, mx.y, mx.z};
    Vec3 v011{mn.x, mx.y, mx.z};

    ConvexCell c;
    c.faces.push_back({{v000, v010, v110, v100}}); // -Z
    c.faces.push_back({{v001, v101, v111, v011}}); // +Z
    c.faces.push_back({{v000, v001, v011, v010}}); // -X
    c.faces.push_back({{v100, v110, v111, v101}}); // +X
    c.faces.push_back({{v000, v100, v101, v001}}); // -Y
    c.faces.push_back({{v010, v011, v111, v110}}); // +Y
    return c;
}

/* Clips a 3D convex polyhedron against half-space dot(p - plane_pt, plane_normal) <= 0
   (plane_normal points OUTWARD from kept region) and builds the interior cut cap polygon. */
void clip_cell_by_plane(ConvexCell& cell, const Vec3& plane_pt, const Vec3& plane_normal) {
    std::vector<PolygonFace> next_faces;
    std::vector<Vec3> cut_points;
    const float eps = 1e-5f;

    for (const auto& face : cell.faces) {
        if (face.loop.size() < 3) continue;
        std::vector<Vec3> clipped;
        size_t n = face.loop.size();
        for (size_t i = 0; i < n; ++i) {
            const Vec3& cur = face.loop[i];
            const Vec3& nxt = face.loop[(i + 1) % n];
            float d_cur = dot3(cur - plane_pt, plane_normal);
            float d_nxt = dot3(nxt - plane_pt, plane_normal);

            bool in_cur = (d_cur <= eps);

            if (in_cur) {
                clipped.push_back(cur);
            }
            if ((d_cur < -eps && d_nxt > eps) || (d_cur > eps && d_nxt < -eps)) {
                float t = d_cur / (d_cur - d_nxt);
                Vec3 inter = cur + (nxt - cur) * t;
                clipped.push_back(inter);
                cut_points.push_back(inter);
            } else if (std::fabs(d_cur) <= eps) {
                cut_points.push_back(cur);
            }
        }
        if (clipped.size() >= 3) {
            next_faces.push_back({std::move(clipped)});
        }
    }

    /* Deduplicate and sort cut cap vertices radially around cap center */
    std::vector<Vec3> unique_cap;
    for (const auto& p : cut_points) {
        bool dup = false;
        for (const auto& q : unique_cap) {
            if (length3(p - q) < 1e-4f) {
                dup = true;
                break;
            }
        }
        if (!dup) unique_cap.push_back(p);
    }

    if (unique_cap.size() >= 3) {
        Vec3 center{0.0f, 0.0f, 0.0f};
        for (const auto& p : unique_cap) center = center + p;
        center = center * (1.0f / static_cast<float>(unique_cap.size()));

        Vec3 u_axis = normalize3(unique_cap[0] - center);
        Vec3 v_axis = normalize3(cross3(plane_normal, u_axis));

        std::sort(unique_cap.begin(), unique_cap.end(), [&](const Vec3& a, const Vec3& b) {
            Vec3 da = a - center;
            Vec3 db = b - center;
            float ang_a = std::atan2(dot3(da, v_axis), dot3(da, u_axis));
            float ang_b = std::atan2(dot3(db, v_axis), dot3(db, u_axis));
            return ang_a < ang_b;
        });

        next_faces.push_back({std::move(unique_cap)});
    }

    cell.faces = std::move(next_faces);
}

uint32_t xorshift32(uint32_t& state) {
    uint32_t x = state ? state : 1337u;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    state = x;
    return x;
}

float rand01(uint32_t& state) {
    return static_cast<float>(xorshift32(state) & 0x00FFFFFFu) / static_cast<float>(0x01000000u);
}

float material_density_multiplier(DestructibleMaterial mat) {
    switch (mat) {
        case DestructibleMaterial::GLASS: return 0.6f;
        case DestructibleMaterial::WOOD: return 0.9f;
        case DestructibleMaterial::STONE: return 2.4f;
        case DestructibleMaterial::METAL: return 4.2f;
        case DestructibleMaterial::EXPLOSIVE_BARREL: return 1.1f;
    }
    return 1.0f;
}

float material_blast_multiplier(DestructibleMaterial mat) {
    switch (mat) {
        case DestructibleMaterial::GLASS: return 1.6f;
        case DestructibleMaterial::WOOD: return 1.2f;
        case DestructibleMaterial::STONE: return 0.75f;
        case DestructibleMaterial::METAL: return 0.5f;
        case DestructibleMaterial::EXPLOSIVE_BARREL: return 3.5f;
    }
    return 1.0f;
}

} // namespace

std::vector<ConvexShard3D> VoronoiFracturer::fracture_box(
    const Vec3& min_bounds,
    const Vec3& max_bounds,
    const Vec3& impact_point,
    float impact_force,
    uint32_t shard_count,
    DestructibleMaterial material,
    uint32_t random_seed
) {
    if (shard_count < 2) shard_count = 2;
    if (shard_count > 128) shard_count = 128;

    uint32_t rng = random_seed;
    Vec3 span = max_bounds - min_bounds;

    /* Bias 50% of Voronoi seeds tighter around impact_point for realistic radial shattering */
    std::vector<Vec3> sites;
    sites.reserve(shard_count);
    for (uint32_t i = 0; i < shard_count; ++i) {
        Vec3 random_pt{
            min_bounds.x + rand01(rng) * span.x,
            min_bounds.y + rand01(rng) * span.y,
            min_bounds.z + rand01(rng) * span.z
        };
        if (i < shard_count / 2) {
            Vec3 clamped_impact{
                std::clamp(impact_point.x, min_bounds.x, max_bounds.x),
                std::clamp(impact_point.y, min_bounds.y, max_bounds.y),
                std::clamp(impact_point.z, min_bounds.z, max_bounds.z)
            };
            random_pt = clamped_impact * 0.65f + random_pt * 0.35f;
        }
        sites.push_back(random_pt);
    }

    std::vector<ConvexShard3D> shards;
    shards.reserve(shard_count);

    float density = material_density_multiplier(material);
    float blast_mult = material_blast_multiplier(material);

    for (uint32_t i = 0; i < shard_count; ++i) {
        ConvexCell cell = make_box_cell(min_bounds, max_bounds);

        for (uint32_t j = 0; j < shard_count; ++j) {
            if (i == j) continue;
            Vec3 mid = (sites[i] + sites[j]) * 0.5f;
            Vec3 normal = normalize3(sites[j] - sites[i]);
            clip_cell_by_plane(cell, mid, normal);
            if (cell.faces.empty()) break;
        }

        if (cell.faces.empty()) continue;

        ConvexShard3D shard;
        Vec3 accum{0.0f, 0.0f, 0.0f};
        size_t total_verts = 0;

        for (const auto& f : cell.faces) {
            if (f.loop.size() < 3) continue;
            uint32_t base_idx = static_cast<uint32_t>(shard.vertices.size());
            for (const auto& v : f.loop) {
                shard.vertices.push_back(v);
                accum = accum + v;
                total_verts++;
            }
            for (size_t k = 1; k + 1 < f.loop.size(); ++k) {
                shard.indices.push_back(base_idx);
                shard.indices.push_back(base_idx + static_cast<uint32_t>(k));
                shard.indices.push_back(base_idx + static_cast<uint32_t>(k + 1));
            }
        }

        if (total_verts < 4 || shard.indices.empty()) continue;

        shard.centroid = accum * (1.0f / static_cast<float>(total_verts));
        Vec3 radial = shard.centroid - impact_point;
        float dist = std::max(0.15f, length3(radial));
        Vec3 dir = normalize3(radial + Vec3{0.0f, 0.25f, 0.0f});

        shard.mass = std::max(0.1f, (span.x * span.y * span.z / static_cast<float>(shard_count)) * density);
        shard.impulse_velocity = dir * ((impact_force * blast_mult) / (dist * std::sqrt(shard.mass)));
        shards.push_back(std::move(shard));
    }

    return shards;
}

} // namespace nova
