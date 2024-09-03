const c = @cImport({
    @cInclude("raylib.h");
});
const Map = @import("Map.zig").Map;

pub const CollisionManager = struct {
    pub fn init() CollisionManager {
        return CollisionManager{};
    }
    pub fn checkCollision(room: [Map.HEIGHT][Map.WIDTH]bool, playerPos: c.Vector2, playerRadius: f32, mapPosition: c.Vector3) bool {
        const cellX = @as(i32, @intFromFloat(playerPos.x - mapPosition.x));
        const cellY = @as(i32, @intFromFloat(playerPos.y - mapPosition.z));

        // Ensure cellX and cellY are non-negative before casting
        const startX = @as(usize, @intCast(@max(0, cellX - 1)));
        const endX = @as(usize, @intCast(@min(cellX + 2, Map.WIDTH)));
        const startY = @as(usize, @intCast(@max(0, cellY - 1)));
        const endY = @as(usize, @intCast(@min(cellY + 2, Map.HEIGHT)));

        for (startY..endY) |y| {
            for (startX..endX) |x| {
                // Ensure x and y are within bounds
                if (x >= Map.WIDTH or y >= Map.HEIGHT) continue;

                if (room[x][y]) {
                    const wallRect = c.Rectangle{
                        .x = mapPosition.x + @as(f32, @floatFromInt(x)),
                        .y = mapPosition.z + @as(f32, @floatFromInt(y)),
                        .width = 1.0,
                        .height = 1.0,
                    };
                    if (c.CheckCollisionCircleRec(playerPos, playerRadius, wallRect)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
};
