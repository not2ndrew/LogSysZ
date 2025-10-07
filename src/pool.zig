const std = @import("std");
const con = @import("config.zig");
const logger = @import("logger.zig");

const Allocator = std.mem.Allocator;

const Logger = logger.Logger;

const Config = con.Config;
const Level = con.Level;
const Output = Config.Output;

pub const PoolError = error {
    PoolNotCreatedYet,
    PoolAlreadyCreated,
};

pub var initialized = false;
pub var pool: Pool = undefined;

pub const Pool = struct {
    file: std.fs.File,
    config: Config,
    allocator: Allocator,
    buffer: []u8,
    owns_file: bool,

    pub fn init(allocator: Allocator, config: Config) !void {
        if (initialized) return PoolError.PoolAlreadyCreated;

        initialized = true;
        const buffer = try allocator.alloc(u8, config.buffer_size);
        errdefer allocator.free(buffer);

        const File = std.fs.File;

        const file = switch (config.output) {
            Output.stderr => File.stderr(),
            Output.stdout => File.stdout(),
            Output.file => |path| blk: {
                const file_output = try std.fs.cwd().openFile(path, .{ .mode = .read_write });
                break :blk file_output;
            }
        };

        const owns_file = switch (config.output) {
            Output.file => true,
            else => false,
        };

        pool = Pool{
            .file = file,
            .config = config,
            .allocator = allocator,
            .buffer = buffer,
            .owns_file = owns_file,
        };
    }

    pub fn deinit(self: *Pool) void {
        if (!initialized) return;

        initialized = false;
        self.allocator.free(self.buffer);
        if (self.owns_file) self.file.close();
    }

    pub fn getPool() !Pool {
        if (!initialized) return PoolError.PoolNotCreatedYet;
        return pool;
    }
};
