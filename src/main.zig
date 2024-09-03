const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
});

pub const Vector3 = c.Vector3;
const GameState = @import("game.zig").GameState;
const Map = @import("map.zig").Map;
const Player = @import("game.zig").Player;
const Window = @import("window.zig").Window;
const Hud = @import("HUD.zig").Hud;
const VectorMath = @import("lib/VectorMath.zig");
const TARGET_FPS = 60;
const GameStatePtr = *GameState;

pub fn main() !void {
    while (true) {
        try runGame();

        if (!shouldRestart()) {
            break;
        }
    }
}

fn runGame() !void {
    loadGameLib() catch @panic("Failed to load libzigfps.dylib");
    defer unloadGameLib() catch unreachable;

    const state = GameState.init();

    Window.init();

    c.SetTargetFPS(TARGET_FPS);
    defer c.CloseWindow();

    state.map.init();

    const cubePosition = c.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 };
    const cubeSize = c.Vector3{ .x = 2.0, .y = 2.0, .z = 2.0 };
    const mapPosition = c.Vector3{ .x = -10.0, .y = 0.0, .z = -10.0 };

    // Main game loop
    var ray = c.Ray{};
    var collision = c.RayCollision{};
    var cursorEnabled: bool = false;

    var activeCamera = state.camera.camera;

    while (!c.WindowShouldClose()) {
        if (c.IsKeyPressed(c.KEY_C)) {
            if (cursorEnabled) {
                c.DisableCursor();
            } else {
                c.EnableCursor();
            }
            cursorEnabled = !cursorEnabled;
        }
        // check for alt + enter
        if (c.IsKeyPressed(c.KEY_B)) {
            // see what display we are on right now
            const display = c.GetCurrentMonitor();

            if (c.IsWindowFullscreen()) {
                // if we are full screen, then go back to the windowed size
                c.SetWindowSize(c.GetScreenWidth(), c.GetScreenHeight());
            } else {
                // if we are not full screen, set the window size to match the monitor we are on
                c.SetWindowSize(c.GetMonitorWidth(display), c.GetMonitorHeight(display));
            }

            // toggle the state
            c.ToggleFullscreen();
        }
        c.BeginMode3D(activeCamera);

        // Update
        const oldCamPos = activeCamera.position;

        if (c.IsCursorHidden()) c.UpdateCamera(&state.camera.camera, c.CAMERA_FIRST_PERSON);

        state.player.position = c.Vector2{ .x = activeCamera.position.x, .y = activeCamera.position.z };

        const playerRadius: f32 = 0.2;

        var playerCellX = @as(i32, @intFromFloat(state.player.position.x - mapPosition.x));
        var playerCellY = @as(i32, @intFromFloat(state.player.position.y - mapPosition.z));

        // Out-of-limits security check
        playerCellX = @max(0, @min(playerCellX, Map.WIDTH - 1));
        playerCellY = @max(0, @min(playerCellY, Map.HEIGHT - 1));

        // Check map collisions
        if (checkCollision(state.map.room, state.player.position, playerRadius, mapPosition)) {
            activeCamera.position = oldCamPos;
        }

        // Update
        if (c.IsCursorHidden()) c.UpdateCamera(&activeCamera, c.CAMERA_FIRST_PERSON);

        // if (c.IsMouseButtonPressed(c.MOUSE_BUTTON_RIGHT)) {
        //     if (c.IsCursorHidden()) {
        //         c.EnableCursor();
        //     } else {
        //         c.DisableCursor();
        //     }
        // }

        var hit: bool = false;
        if (c.IsMouseButtonDown(c.MOUSE_BUTTON_LEFT)) {
            c.DisableCursor();
            hit = false;
            if (!collision.hit and !hit) {
                ray = c.GetMouseRay(c.GetMousePosition(), activeCamera);

                if (c.IsMouseButtonUp(c.MOUSE_BUTTON_LEFT)) {
                    // Check collision between ray and box
                    hit = true;
                    collision = c.GetRayCollisionBox(ray, c.BoundingBox{
                        .min = c.Vector3{ .x = cubePosition.x - cubeSize.x / 2, .y = cubePosition.y - cubeSize.y / 2, .z = cubePosition.z - cubeSize.z / 2 },
                        .max = c.Vector3{ .x = cubePosition.x + cubeSize.x / 2, .y = cubePosition.y + cubeSize.y / 2, .z = cubePosition.z + cubeSize.z / 2 },
                    });
                    std.debug.print("💥 RAYCAST COLLISION: {}\n", .{collision.point});
                }
            } else {
                collision.hit = false;
            }
        }

        // Draw
        c.BeginDrawing();
        defer c.EndDrawing();

        c.ClearBackground(c.RAYWHITE);

        c.BeginMode3D(activeCamera);
        state.map.draw(mapPosition);
        if (collision.hit) {
            c.DrawCube(cubePosition, cubeSize.x, cubeSize.y, cubeSize.z, c.RED);
            c.DrawCubeWires(cubePosition, cubeSize.x, cubeSize.y, cubeSize.z, c.MAROON);
            c.DrawCubeWires(cubePosition, cubeSize.x + 0.2, cubeSize.y + 0.2, cubeSize.z + 0.2, c.GREEN);

            // Draw hitmarker
            const hitPos = collision.point;
            std.debug.print("🎯 RAYCAST HIT: {}\n", .{collision.point});
            c.DrawSphere(hitPos, 0.1, c.YELLOW); // Draw a small yellow sphere at the hit position
        } else {
            c.DrawCube(cubePosition, cubeSize.x, cubeSize.y, cubeSize.z, c.GRAY);
            c.DrawCubeWires(cubePosition, cubeSize.x, cubeSize.y, cubeSize.z, c.DARKGRAY);
        }

        c.DrawRay(ray, c.MAROON);
        c.DrawGrid(10, 1.0);
        c.EndMode3D();

        c.DrawText("Try clicking on the box with your mouse!", 240, 10, 20, c.DARKGRAY);
        if (collision.hit) {
            c.DrawText("BOX SELECTED", (@divExact(800 - c.MeasureText("BOX SELECTED", 30), 2)), 45, 30, c.GREEN);
        }
        c.DrawText("Right click mouse to toggle camera controls", 10, 430, 10, c.GRAY);
        // Draw minimap
        Hud.drawMinimap(state.map.room, playerCellX, playerCellY);

        c.EndMode3D();
        c.DrawFPS(10, 10);
        c.DrawText(c.TextFormat("Time: %02.02f ms", c.GetFrameTime() * 1000), 10, 32, 16, c.BLACK);
    }
}

fn checkCollision(room: [Map.HEIGHT][Map.WIDTH]bool, playerPos: c.Vector2, playerRadius: f32, mapPosition: c.Vector3) bool {
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

fn recompileAndReloadGameLib() !void {
    // Unload the current game library
    unloadGameLib() catch @panic("Failed to unload libzigfps.dylib");

    // Recompile the game library
    try recompileGameLib(std.heap.page_allocator);

    // Load the newly compiled game library
    loadGameLib() catch @panic("Failed to load libzigfps.dylib");
}

var game_dyn_lib: ?std.DynLib = null;
fn loadGameLib() !void {
    if (game_dyn_lib != null) return error.AlreadyLoaded;
    const dyn_lib = std.DynLib.open("zig-out/lib/libzigfps.dylib") catch {
        return error.OpenFail;
    };
    game_dyn_lib = dyn_lib;
    // gameReload = dyn_lib.lookup(@TypeOf(gameReload), "gameReload") orelse return error.LookupFail;
    // gameTick = dyn_lib.lookup(@TypeOf(gameTick), "gameTick") orelse return error.LookupFail;
    // gameDraw = dyn_lib.lookup(@TypeOf(gameDraw), "gameDraw") orelse return error.LookupFail;
    std.debug.print("Loaded libzig-fps.dylib\n", .{});
}

fn unloadGameLib() !void {
    if (game_dyn_lib) |*dyn_lib| {
        dyn_lib.close();
        game_dyn_lib = null;
    } else {
        return error.AlreadyUnloaded;
    }
}

fn recompileGameLib(allocator: std.mem.Allocator) !void {
    const process_args = [_][]const u8{ "zig", "build", "-Dgame_only=true", "--search-prefix", "zig-out" };
    var build_process = std.process.Child.init(&process_args, allocator);
    try build_process.spawn();
    const term = try build_process.wait();
    switch (term) {
        .Exited => |exited| {
            if (exited == 2) return error.RecompileFail;
        },
        else => return,
    }
}

fn shouldRestart() bool {
    std.debug.print("determining if should restart", .{});
    return c.IsKeyDown(c.KEY_R);
}
