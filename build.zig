const std = @import("std");

fn makeOdinTargetString(allocator: std.mem.Allocator, target: std.Target.Query) !?[]const u8 {
    if (target.cpu_arch == null) {
        return null;
    }
    if (target.cpu_arch.? == .wasm32) {
        return "freestanding_wasm32";
    }

    const arch_string = switch (target.cpu_arch.?) {
        .x86_64 => "amd64",
        .x86 => "i386",
        .arm => "arm32",
        .aarch64 => "arm64",
        else => @panic("unhandled cpu arch"),
    };

    return switch (target.os_tag.?) {
        .windows => try std.fmt.allocPrint(allocator, "windows_{s}", .{arch_string}),
        .linux => try std.fmt.allocPrint(allocator, "linux_{s}", .{arch_string}),
        .macos => try std.fmt.allocPrint(allocator, "darwin_{s}", .{arch_string}),
        else => std.debug.panic("can't build for {}", .{target}),
    };
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    // const optimize = b.standardOptimizeOption(.{});

    const odin_compile = b.addSystemCommand(&.{"odin"});
    {
        odin_compile.addArgs(&.{ "build", "src", "-no-entry-point", "-build-mode:obj", "-out:zig-out/odin.o" });
        if (try makeOdinTargetString(b.allocator, target.query)) |odin_target_string| {
            const target_flag = try std.mem.concat(b.allocator, u8, &.{ "-target:", odin_target_string });
            odin_compile.addArg(target_flag);
        }
    }
}
