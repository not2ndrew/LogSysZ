const std = @import("std");
const Pool = @import("pool.zig").Pool;
const logger = @import("logger.zig");
const con = @import("config.zig");

const Config = con.Config{};
const Logger = logger.Logger;

pub fn main() !void {
    var debugAlloc = std.heap.DebugAllocator(.{}){};
    defer _ = debugAlloc.deinit();

    const allocator = debugAlloc.allocator();

    const new_config = con.Config{ .output = con.Config.Output{ .file = "main.txt" } };

    try Pool.init(allocator, new_config);
    Logger.init();

    var pool = try Pool.getPool();
    defer pool.deinit();

    Logger.info("Hello World\n", .{});
    Logger.info("Goodbye\n", .{});
}
