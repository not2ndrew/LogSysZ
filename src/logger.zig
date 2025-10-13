const std = @import("std");
const con = @import("config.zig");
const Pool = @import("pool.zig").Pool;
var RotationConfig = @import("log_rotation.zig").RotationConfig{};

const Output = con.Config.Output;
const Config = con.Config{};

const Allocator = std.mem.Allocator;
const File = std.fs.File;
const time = std.time;

var Mutex = std.Thread.Mutex{};

pub const Logger = struct {
    var cached_timestamp: [19]u8 = undefined; // "[YYYY-MM-DD HH:MM:SS]"
    var cached_seconds: i64 = 0;

    pub const Level = enum {
        DEBUG,
        INFO,
        WARNING,
        ERROR,
        FATAL,
    };

    pub fn debug(comptime fmt: []const u8, comptime args: anytype) void {
        log(Level.DEBUG, fmt, args);
    }

    pub fn info(comptime fmt: []const u8, comptime args: anytype) void {
        log(Level.INFO, fmt, args);
    }

    pub fn warning(comptime fmt: []const u8, comptime args: anytype) void {
        log(Level.WARNING, fmt, args);
    }

    pub fn err(comptime fmt: []const u8, comptime args: anytype) void {
        log(Level.ERROR, fmt, args);
    }

    pub fn fatal(comptime fmt: []const u8, comptime args: anytype) void {
        log(Level.FATAL, fmt, args);
    }

    // The general format of each Log Message should be
    // [Year-Month-Day Hour:Minutes:Seconds] [Level] [Log Message]
    pub fn log(comptime level: Level, comptime fmt: []const u8, comptime args: anytype) void {
        if (@intFromEnum(level) < @intFromEnum(Config.min_level)) return;
        const pool = Pool.getPool() catch return;

        if (pool.owns_file) {
            const file_size = pool.file.getEndPos() catch return;

            if (file_size > RotationConfig.max_file_size) {
                RotationConfig.fileRotation(pool.allocator) catch return;
                // std.debug.print("Log exceeded file size\n", .{});
                // return;
            }
        }

        Mutex.lock();
        defer Mutex.unlock();

        getCachedDateTime();

        const writer_interface = &pool.writer.interface;

        writer_interface.print("[{s} {s}] [{s}]: ", .{cached_timestamp[0..10], cached_timestamp[11..], @tagName(level)}) catch {
            std.debug.print("Writing Date-Time Error\n", .{});
            return;
        };
        writer_interface.print(fmt, args) catch {
            std.debug.print("Writing log Error\n", .{});
            return;
        };
        writer_interface.flush() catch {
            std.debug.print("Flushing Error\n", .{});
        };
    }

    /// This modifies the date buffer and time buffer to UTC time relative to UTC 1970-01-01.\n
    /// Make sure the amount of bytes used for date_buf and time_buf is 10 and 8 respectively.
    fn getCachedDateTime() void {
        const now = time.timestamp();

        if (now != cached_seconds) {
            const int_now: u64 = @intCast(now);

            getDate(cached_timestamp[0..10], int_now);
            getTime(cached_timestamp[11..], int_now);
            cached_timestamp[10] = ' ';
        }
    }

    // The format of time is HH:MM:SS
    fn getTime(buf: []u8, timestamp: u64) void {
        const s_per_min = time.s_per_min;
        const s_per_hour = time.s_per_hour;
        const s_per_day = time.s_per_day;

        var remaining_sec = @mod(timestamp, s_per_day);

        const hour: u8 = @truncate(remaining_sec / s_per_hour);
        remaining_sec = remaining_sec % s_per_hour;

        const min: u8 = @truncate(remaining_sec / s_per_min);
        remaining_sec =  remaining_sec % s_per_min;

        const sec: u8 = @truncate(remaining_sec);

        writeTwoDigits(buf, 0, hour);
        buf[2] = ':';
        writeTwoDigits(buf, 3, min);
        buf[5] = ':';
        writeTwoDigits(buf, 6, sec);
    }

    // The format of date is YYYY-MM-DD
    fn getDate(buf: []u8, timestamp: u64) void {
        const s_per_day = time.s_per_day;
        const epoch_year = time.epoch.epoch_year;

        const days_since_epoch = timestamp / s_per_day;
        const remaining_days = days_since_epoch % 365;

        const current_year: u16 = @truncate(epoch_year + days_since_epoch / 365);

        // TODO: Not every month is 30 days long.
        const current_month: u8 = @truncate(remaining_days / 30);
        const month: time.epoch.Month = @enumFromInt(current_month);
        const days_per_month = time.epoch.getDaysInMonth(current_year, month);

        const current_day: u8 = @truncate(days_per_month - remaining_days % 30);

        writeYear(buf, current_year);
        buf[4] = '-';
        writeTwoDigits(buf, 5, current_month);
        buf[7] = '-';
        writeTwoDigits(buf, 8, current_day);
    }

    fn writeYear(buf: []u8, value: u16) void {
        const base = 10;
        var num = value;
        var i: usize = 0;

        while (i < 4) {
            const digit: u8 = @truncate(@mod(num, base));
            buf[3 - i] = '0' + digit;

            num = @divFloor(num, base);
            i += 1;
        }
    }

    fn writeTwoDigits(buf: []u8, index: usize, value: u8) void {
        const leading_num: u8 = value / 10;
        const sub_num = value % 10;
        buf[index] = '0' + leading_num;
        buf[index + 1] = '0' + sub_num;
    }
};
