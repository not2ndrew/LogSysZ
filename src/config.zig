const std = @import("std");
const logger = @import("logger.zig");

const Level = logger.Logger.Level;

/// This is your Configuration that handles many components
/// in this design system. Change them to your own preferences.\n
///
/// Use Config{} to get the struct.
pub const Config = struct {
    buffer_size: usize = 100,
    min_level: Level = Level.INFO,
    output: Output = Output.stdout,

    pub const Output = union(enum) {
        stderr,
        stdout,
        file: []const u8,
    };
};
