const std = @import("std");
const core = @import("core");
const testing = std.testing;

const Pool = core.Pool;
const Logger = core.Logger;
const Config = core.Config;

const Level = Logger.Level;

const temp_path = "temp.txt";
const file_config = Config{
    .min_level = Level.INFO,
    .buffer_size = 100,
    .output = Config.Output{ .file = temp_path },
};


// ===== HELPER FUNCTIONS =====
fn initPoolAndGet() !*Pool {
    try Pool.init(testing.allocator, file_config);
    return try Pool.getPool();
}

fn createTempFile() !void {
    var dir = std.fs.cwd();
    _ = try dir.createFile(temp_path, .{ .read = true });
}

fn deleteTempFile() void {
    std.fs.cwd().deleteFile(temp_path) catch unreachable;
}

fn readFileContents(allocator: std.mem.Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile(temp_path, .{});
    const file_size = try file.getEndPos();
    const buf = try allocator.alloc(u8, file_size);

    var reader = std.fs.File.Reader.init(file, buf);
    try reader.interface.readSliceAll(buf);

    return buf;
}

// ===== TEST CASES =====
test "Intialize Pool" {
    try createTempFile();
    defer deleteTempFile();

    var pool = try initPoolAndGet();
    defer pool.deinit();

    try testing.expectEqual(pool.writer.interface.buffer.len, 100);
    try testing.expect(pool.owns_file);
}

test "Logger Writes to File" {
    try createTempFile();
    defer deleteTempFile();

    var pool = try initPoolAndGet();
    defer pool.deinit();

    Logger.info("Hello World\n", .{});

    const contents = try readFileContents(testing.allocator);
    defer testing.allocator.free(contents);

    const found = std.mem.containsAtLeast(u8, contents, 1, "Hello World");
    try testing.expect(found);
}

test "Changing Config Level" {
    const config = Config{
        .min_level = Level.INFO,
        .buffer_size = 50,
        .output = Config.Output.stdout, 
    };

    try Pool.init(testing.allocator, config);
    var pool = try Pool.getPool();
    defer pool.deinit();

    try testing.expect(std.mem.eql(u8, @tagName(pool.config.min_level), @tagName(Level.INFO)));

    pool.config.min_level = Level.ERROR;

    try testing.expect(std.mem.eql(u8, @tagName(pool.config.min_level), @tagName(Level.ERROR)));
}
