const std = @import("std");
const con = @import("config.zig");
const logger = @import("logger.zig");
const rotation = @import("log_rotation.zig").FileRotation{};

const Allocator = std.mem.Allocator;
const File = std.fs.File;

const Logger = logger.Logger;

const Config = con.Config;
const Level = con.Level;
const Output = Config.Output;

pub const PoolError = error {
    PoolNotCreatedYet,
    PoolAlreadyCreated,
};

pub var initialized = false;
var pool: Pool = undefined;

pub const Pool = struct {
    writer: File.Writer,
    writer_buffer: []u8,
    file: File,
    config: Config,
    allocator: Allocator,
    owns_file: bool,

    pub fn init(allocator: Allocator, config: Config) !void {
        if (initialized) return PoolError.PoolAlreadyCreated;

        initialized = true;

        const writer_buffer = try allocator.alloc(u8, config.buffer_size);
        errdefer allocator.free(writer_buffer);

        const file = switch (config.output) {
            Output.stderr => File.stderr(),
            Output.stdout => File.stdout(),
            Output.file => |path| blk: {
                const file_output = try std.fs.cwd().openFile(path, .{ .mode = .read_write });
                break :blk file_output;
            }
        };

        var writer = File.Writer.init(file, writer_buffer);

        const owns_file = switch (config.output) {
            Output.file => true,
            else => false,
        };

        if (owns_file) writer.pos = try file.getEndPos();

        pool = Pool{
            .writer = writer,
            .writer_buffer = writer_buffer,
            .file = file,
            .config = config,
            .allocator = allocator,
            .owns_file = owns_file,
        };
    }

    pub fn deinit(self: *Pool) void {
        if (!initialized) return;

        initialized = false;
        self.allocator.free(self.writer_buffer);
        if (self.owns_file) self.file.close();
    }

    pub fn getPool() !*Pool {
        if (!initialized) return PoolError.PoolNotCreatedYet;
        return &pool;
    }
};
