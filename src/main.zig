const std = @import("std");
const log = std.log;
const mem = std.mem;
const E = std.os.linux.E;
const fusebind = @import("bindings.zig");

const fu = @import("wrapper.zig");
const opos = fu.att;

fn myOpen(path: []const u8, _: *fu.FileInfo) i32 {
    log.info("myOpen: {s}", .{path});
    return 0;
}

const myOps = fu.Operations{
    .open = &myOpen,
};

pub fn main() !u8 {
    log.info("Zig hello FUSE", .{});

    const args = std.os.argv;
    const re = fu.main(args, myOps, null);

    return switch (re) {
        0 => 0,
        1 => error.FuseParseCmdline,
        2 => error.FuseMountpoint,
        3 => error.FuseNew,
        4 => error.FuseMount,
        5 => error.FuseDaemonize,
        6 => error.FuseSession,
        7 => error.FuseLoopCfg,
        8 => error.FuseEventLoop,
        else => error.FuseUnknown,
    };
}
