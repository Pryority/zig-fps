const c = @cImport({
    @cInclude("raylib.h");
});
const VectorMath = @import("lib/VectorMath.zig");

pub const Map = struct {
    room: [Map.HEIGHT][Map.WIDTH]bool,
    pub const WIDTH = 20;
    pub const HEIGHT = 20;

    pub fn init(self: *Map) void {
        // Initialize the room with `false` (empty space)
        for (&self.room) |*row| {
            for (row) |*cell| {
                cell.* = false;
            }
        }

        // Set up walls on the edges
        for (0..Map.HEIGHT) |y| {
            self.room[y][0] = true; // Left wall
            self.room[y][Map.WIDTH - 1] = true; // Right wall
        }
        for (0..Map.WIDTH) |x| {
            self.room[0][x] = true; // Bottom wall
            self.room[Map.HEIGHT - 1][x] = true; // Top wall
        }
    }

    pub fn draw(self: *Map, mapPosition: c.Vector3) void {
        const edgeColors = [_]c.Color{
            c.RED, // Color for right edge
            c.GREEN, // Color for forward edge
            c.BLUE, // Color for back edge
            c.YELLOW, // Color for left edge
            c.ORANGE, // Color for top edge
            c.PINK, // Color for bottom edge
            c.LIME, // Color for right vertical edge
            c.VIOLET, // Color for forward vertical edge
            c.PURPLE, // Color for back vertical edge
            c.BROWN, // Color for left vertical edge
        };

        const edgeOrder = [_]struct {
            start: c.Vector3,
            end: c.Vector3,
            color: c.Color,
        }{
            // Horizontal lines on top
            .{ .start = c.Vector3{ .x = 1.0, .y = 0.0, .z = 0.0 }, .end = c.Vector3{ .x = 1.0, .y = 0.0, .z = 1.0 }, .color = edgeColors[0] },
            .{ .start = c.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 }, .end = c.Vector3{ .x = 0.0, .y = 1.0, .z = 1.0 }, .color = edgeColors[0] }, // Right edge
            .{ .start = c.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 }, .end = c.Vector3{ .x = 0.0, .y = 0.0, .z = 1.0 }, .color = edgeColors[1] }, // Forward edge
            .{ .start = c.Vector3{ .x = 1.0, .y = 0.0, .z = 1.0 }, .end = c.Vector3{ .x = 1.0, .y = 0.0, .z = 0.0 }, .color = edgeColors[2] }, // Back edge
            .{ .start = c.Vector3{ .x = 1.0, .y = 0.0, .z = 0.0 }, .end = c.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 }, .color = edgeColors[3] }, // Left edge

            // Vertical lines
            .{ .start = c.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 }, .end = c.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 }, .color = edgeColors[4] }, // Bottom to top
            .{ .start = c.Vector3{ .x = 1.0, .y = 0.0, .z = 0.0 }, .end = c.Vector3{ .x = 1.0, .y = 1.0, .z = 0.0 }, .color = edgeColors[5] }, // Right bottom to top
            .{ .start = c.Vector3{ .x = 0.0, .y = 0.0, .z = 1.0 }, .end = c.Vector3{ .x = 0.0, .y = 1.0, .z = 1.0 }, .color = edgeColors[6] }, // Forward bottom to top
            .{ .start = c.Vector3{ .x = 1.0, .y = 0.0, .z = 1.0 }, .end = c.Vector3{ .x = 1.0, .y = 1.0, .z = 1.0 }, .color = edgeColors[7] }, // Back bottom to top
            .{ .start = c.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 }, .end = c.Vector3{ .x = 1.0, .y = 1.0, .z = 0.0 }, .color = edgeColors[8] }, // Top front edge
            .{ .start = c.Vector3{ .x = 0.0, .y = 1.0, .z = 1.0 }, .end = c.Vector3{ .x = 1.0, .y = 1.0, .z = 1.0 }, .color = edgeColors[9] }, // Top back edge
        };

        for (self.room, 0..) |row, y| {
            for (row, 0..) |cell, x| {
                if (cell) {
                    const cellPos = c.Vector3{
                        .x = mapPosition.x + @as(f32, @floatFromInt(x)),
                        .y = mapPosition.y,
                        .z = mapPosition.z + @as(f32, @floatFromInt(y)),
                    };

                    // Draw cube
                    c.DrawCube(cellPos, 1.0, 1.0, 1.0, c.DARKGRAY);

                    // Draw edges with different colors
                    for (edgeOrder) |edge| {
                        c.DrawLine3D(VectorMath.addVector3(cellPos, edge.start), VectorMath.addVector3(cellPos, edge.end), edge.color);
                    }
                }
            }
        }
    }

    pub fn checkCollision(self: *Map, playerPos: c.Vector2, playerRadius: f32, mapPosition: c.Vector3) bool {
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

                if (self.room[x][y]) {
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
