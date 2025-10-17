const std = @import("std");
const Pool = @import("pool.zig").Pool;
const Logger = @import("logger.zig").Logger;

pub const RotationConfig = struct {
    max_file_size: usize = 100,
    max_files: u8 = 4,

    pub fn fileRotation(self: *RotationConfig, file_name: []const u8, allocator: std.mem.Allocator) !void {
        const cwd = std.fs.cwd();

        const dot_index = std.mem.lastIndexOf(u8, file_name, ".") orelse return;
        const name = file_name[0..dot_index];
        const file_type = file_name[dot_index + 1..];

        // Perform Log Rotation
        var i = self.max_files;
        while (i > 1) : (i -= 1) {
            const old_name = try std.fmt.allocPrint(allocator, "{s}.{d}.{s}", .{name, i - 1, file_type});
            const new_name = try std.fmt.allocPrint(allocator, "{s}.{d}.{s}", .{name, i, file_type});
            defer allocator.free(old_name);
            defer allocator.free(new_name);

            cwd.rename(old_name, new_name) catch |err| switch (err) {
                error.FileNotFound => {},
                else => return err,
            };
        }

        const first_name = try std.fmt.allocPrint(allocator, "{s}.1.{s}", .{name, file_type});
        defer allocator.free(first_name);

        cwd.rename(file_name, first_name) catch |err| switch (err) {
            error.FileNotFound => {},
            else => return err,
        };

        const new_file = try cwd.createFile(file_name, .{ .read = true });
        defer new_file.close();
    }
};
