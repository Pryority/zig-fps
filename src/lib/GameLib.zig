const std = @import("std");

var game_dyn_lib: ?std.DynLib = null;

pub fn load() !void {
    if (game_dyn_lib != null) return error.AlreadyLoaded;
    const dyn_lib = std.DynLib.open("zig-out/lib/libzigfps.dylib") catch {
        return error.OpenFail;
    };
    game_dyn_lib = dyn_lib;
    std.debug.print("Loaded libzig-fps.dylib\n", .{});
}

pub fn unload() !void {
    if (game_dyn_lib) |*dyn_lib| {
        dyn_lib.close();
        game_dyn_lib = null;
    } else {
        return error.AlreadyUnloaded;
    }
}

pub fn recompile(allocator: std.mem.Allocator) !void {
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
