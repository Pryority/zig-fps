const c = @cImport({
    @cInclude("raylib.h");
});
const Map = @import("map.zig").Map;

pub const Hud = struct {
    pub fn drawMinimap(room: [Map.HEIGHT][Map.WIDTH]bool, playerX: i32, playerY: i32) void {
        const cellSize = 10;
        const mapOffsetX = c.GetScreenWidth() - Map.WIDTH * cellSize - 10;
        const mapOffsetY = 10;

        for (room, 0..) |row, y| {
            for (row, 0..) |cell, x| {
                const rectX = mapOffsetX + @as(i32, @intCast(x)) * cellSize;
                const rectY = mapOffsetY + @as(i32, @intCast(y)) * cellSize;
                if (cell) {
                    c.DrawRectangle(rectX, rectY, cellSize, cellSize, c.DARKGRAY); // Change wall color here
                } else {
                    c.DrawRectangleLines(rectX, rectY, cellSize, cellSize, c.LIGHTGRAY); // Change empty space color here
                }
            }
        }

        // Draw player position
        c.DrawRectangle(mapOffsetX + playerX * cellSize, mapOffsetY + playerY * cellSize, cellSize, cellSize, c.RED); // Player color
    }
};
