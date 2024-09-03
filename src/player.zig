const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
});

pub const Player = struct {
    position: c.Vector2,
    camera: *c.Camera3D, // Reference to the camera

    pub fn performRaycast(self: *Player) void {
        const mouse_ray = c.GetMouseRay(c.GetMousePosition(), self.camera.*); // Dereference the pointer
        const mouse_pos = c.GetMousePosition();
        std.debug.print("Mouse Position: x: {}, y: {}\n", .{ mouse_pos.x, mouse_pos.y });
        std.debug.print("Ray Origin: x: {}, y: {}, z: {}\n", .{ mouse_ray.position.x, mouse_ray.position.y, mouse_ray.position.z });

        // Define the ground as a quad
        const p1 = c.Vector3{ .x = -10.0, .y = 0.0, .z = -10.0 };
        const p2 = c.Vector3{ .x = 10.0, .y = 0.0, .z = -10.0 };
        const p3 = c.Vector3{ .x = 10.0, .y = 0.0, .z = 10.0 };
        const p4 = c.Vector3{ .x = -10.0, .y = 0.0, .z = 10.0 };

        // Perform ray collision with the ground
        const hit_info = c.GetRayCollisionQuad(mouse_ray, p1, p2, p3, p4);

        if (hit_info.hit) {
            std.debug.print("Hit position: ({})\n", .{hit_info});
            // Process hit information here (e.g., damage or interaction)
        }
    }
};
