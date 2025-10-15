const std = @import("std");
const Pool = @import("pool.zig").Pool;
const logger = @import("logger.zig");
const con = @import("config.zig");

const Config = con.Config;
const Output = con.Config.Output;
const Logger = logger.Logger;

const FILE_NAME = "access.log";

pub fn main() !void {
    var debugAlloc = std.heap.DebugAllocator(.{}){};
    defer _ = debugAlloc.deinit();

    const allocator = debugAlloc.allocator();

    const new_config = Config{ .output = Output{ .file = FILE_NAME } };

    try Pool.init(allocator, new_config);

    var pool = try Pool.getPool();
    defer pool.deinit();

    Logger.info("Hello World\n", .{});
    Logger.info("Goodbye\n", .{});
}
