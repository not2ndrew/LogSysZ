const std = @import("std");
const Pool = @import("pool.zig").Pool;
const Config = @import("Config").Config;
const Logger = @import("logger.zig").Logger;

// TODO: Not every log file starts with log.txt
// Get the file path instead of using this constant.
// And make sure that file path is comp time instead of runtime.
const LOG_FILE_NAME = "log.txt";

pub const RotationConfig = struct {
    max_file_size: usize = 100,
    max_files: u8 = 4,

    pub fn fileRotation(self: *RotationConfig, allocator: std.mem.Allocator) !void {
        const cwd = std.fs.cwd();
        var i = self.max_files - 1;

        while (i >= 1) : (i -= 1) {
            const old_name = try std.fmt.allocPrint(allocator, "log.{d}.txt", .{i});
            const new_name = try std.fmt.allocPrint(allocator, "log.{d}.txt", .{i + 1});
            defer allocator.free(old_name);
            defer allocator.free(new_name);

            cwd.rename(old_name, new_name) catch |err| switch (err) {
                error.FileNotFound => {},
                else => {
                    return err;
                },
            };
        }

        const first_name = "log.1.txt";

        cwd.rename(LOG_FILE_NAME, first_name) catch |err| switch (err) {
            error.FileNotFound => {},
            else => {
                return err;
            },
        };

        const new_file = try cwd.createFile(LOG_FILE_NAME, .{ .read = true });
        defer new_file.close();
    }
};
