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

    try Pool.init(allocator, Config);

    var pool = try Pool.getPool();
    defer pool.deinit();

    Logger.info("Hello World\n", .{});
}
