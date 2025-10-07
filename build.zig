const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const main_mod = b.addModule("LogSysZ", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
    });

    const core_mod = b.addModule("core", .{
        .root_source_file = b.path("src/core.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Test Files
    const lib_unit_tests = b.addTest(.{ .root_module = core_mod });
    lib_unit_tests.root_module.addImport("core", core_mod);

    const test_step = b.step("test", "Run unit tests");
    const tests_dir = std.fs.cwd().openDir("tests", .{ .iterate = true }) catch |err| {
        if (err == error.FileNotFound) return;
        unreachable;
    };

    var test_files = tests_dir.iterate();

    // Add test zig files from tests directory.
    while (test_files.next() catch unreachable) |entry| {
        if (entry.kind == .file) {
            const extension = std.fs.path.extension(entry.name);

            if (std.mem.eql(u8, extension, ".zig")) {
                const path = b.fmt("tests/{s}", .{entry.name});

                const test_mod = b.addModule(entry.name, .{
                    .root_source_file = b.path(path),
                    .target = target,
                    .optimize = optimize,
                    .imports = &.{
                        .{ .name = "core", .module = core_mod },
                    }
                });

                const test_exe = b.addTest(.{ .root_module = test_mod });
                const run_test = b.addRunArtifact(test_exe);

                test_step.dependOn(&run_test.step);
            }

        }
    }

    // Executable
    const exe = b.addExecutable(.{
        .name = "LogSysZ",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "LogSysZ", .module = main_mod },
            },
        }),
    });

    // Test Files
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
