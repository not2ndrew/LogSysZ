const std = @import("std");
const Pool = @import("pool.zig").Pool;
const Config = @import("Config").Config;
const Logger = @import("logger.zig").Logger;

pub const FileRotation = struct {
    max_file_size: usize = 100,
    files_created: u8 = 0,
    max_files: u8 = 4,
};
