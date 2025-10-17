const std = @import("std");
const Level = @import("logger.zig").Logger.Level;

pub const Config = struct {
    buffer_size: usize = 100,
    min_level: Level = Level.INFO,
    output: Output = Output.stdout,
    format: Format = Format.standard,

    pub const Output = union(enum) {
        stderr,
        stdout,
        file: []const u8,
    };
    
    pub const Format = enum {
        standard,
        json,
    };
};
