const c = @cImport({
    @cInclude("raylib.h");
});

pub const Camera = struct {
    camera: c.Camera3D,
    cursorEnabled: bool = false,
    fullscreenEnabled: bool = false,

    pub fn init() Camera {
        return Camera{ .camera = c.Camera3D{ .position = .{ .x = 2.0, .y = 2.0, .z = 2.0 }, .target = .{ .x = 0.0, .y = 1.8, .z = 0.0 }, .up = .{ .x = 0.0, .y = 1.0, .z = 0.0 }, .fovy = 45.0, .projection = c.CAMERA_PERSPECTIVE } };
    }
    pub fn toggleFullscreen(self: *Camera) void {
        const display = c.GetCurrentMonitor();

        if (c.IsWindowFullscreen()) {
            c.SetWindowSize(c.GetScreenWidth(), c.GetScreenHeight());
        } else {
            c.SetWindowSize(c.GetMonitorWidth(display), c.GetMonitorHeight(display));
        }
        self.fullscreenEnabled = !self.fullscreenEnabled;
        c.ToggleFullscreen();
    }

    pub fn handleCursor(self: *Camera) void {
        if (c.IsKeyPressed(c.KEY_C)) {
            if (self.cursorEnabled) {
                c.DisableCursor();
            } else {
                c.EnableCursor();
            }
            self.cursorEnabled = !self.cursorEnabled;
        }
    }
};
