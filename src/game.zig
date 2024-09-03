// game.zig
const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
});
const VectorMath = @import("lib/VectorMath.zig");
const Window = @import("window.zig").Window;
const Camera = @import("camera.zig").Camera;
const Map = @import("map.zig").Map;
const Player = @import("player.zig").Player;
const CollisionManager = @import("CollisionManager.zig").CollisionManager;

pub const GameState = struct {
    allocator: std.mem.Allocator,
    map: Map,
    player: Player,
    time: f32,
    camera: Camera,
    cm: CollisionManager,

    pub fn init() *GameState {
        var allocator = std.heap.c_allocator;
        var game_state = allocator.create(GameState) catch {
            std.debug.print("Failed to allocate GameState\n", .{});
            @panic("Out of memory.");
        };

        game_state.camera = Camera.init();

        game_state.* = GameState{ .allocator = allocator, .map = Map{ .room = undefined }, .player = game_state.player, .time = 0, .camera = game_state.camera, .cm = CollisionManager.init() };
        return game_state;
    }
};

export fn gameTick(state_ptr: *anyopaque) void {
    var state = @as(*GameState, @ptrCast(@alignCast(state_ptr)));
    const delta = c.GetFrameTime();

    state.time += delta;
    // state.camera.updateCenter();
    // updatePlayer(&state.player, delta, &state.envItems);
    // updateDummy(&state.dummy, delta, &state.envItems);
    // checkPlayerCollisions(state_ptr);

    // if (state.player.currentHitbox) |hitbox| {
    //     if (state.dummy.isHit(hitbox)) {
    //         state.dummy.takeDamage(10);
    //         std.debug.print("Dummy hit! Health: {}", .{state.dummy.health});
    //         if (state.dummy.health <= 0) {
    //             state.dummy = Dummy.init(@as(f32, @floatFromInt(@as(c_int, @divExact(c.GetScreenWidth(), 2)))), 0);
    //         }
    //     }
    // }
}

export fn gameReload(game_state_ptr: *anyopaque) void {
    // TODO: implement
    _ = game_state_ptr;
}
