#ifndef NOVA_FRACTURE_HPP
#define NOVA_FRACTURE_HPP

#include <vector>
#include <cstdint>

namespace nova {

struct Vec3 {
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;

    Vec3 operator+(const Vec3& o) const { return {x + o.x, y + o.y, z + o.z}; }
    Vec3 operator-(const Vec3& o) const { return {x - o.x, y - o.y, z - o.z}; }
    Vec3 operator*(float s) const { return {x * s, y * s, z * s}; }
};

enum class DestructibleMaterial {
    GLASS = 0,
    WOOD = 1,
    STONE = 2,
    METAL = 3,
    EXPLOSIVE_BARREL = 4
};

struct ConvexShard3D {
    std::vector<Vec3> vertices;
    std::vector<uint32_t> indices; /* Triangle indices (3 per face) */
    Vec3 centroid;
    Vec3 impulse_velocity;
    float mass = 1.0f;
};

class VoronoiFracturer {
public:
    /* Generates watertight 3D Voronoi convex shards inside an AABB around the impact point,
       computing Jolt Physics mass & outward blast impulse vectors per material preset. */
    static std::vector<ConvexShard3D> fracture_box(
        const Vec3& min_bounds,
        const Vec3& max_bounds,
        const Vec3& impact_point,
        float impact_force,
        uint32_t shard_count,
        DestructibleMaterial material,
        uint32_t random_seed = 1337
    );
};

} // namespace nova

#endif /* NOVA_FRACTURE_HPP */
