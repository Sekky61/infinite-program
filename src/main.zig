const std = @import("std");
const log = std.log;
const mem = std.mem;
const E = std.os.linux.E;
const fusebind = @import("bindings.zig");

const fu = @import("wrapper.zig");
const opos = fu.att;

fn myOpen(path: []const u8, fi: ?fu.FileInfo) i32 {
    log.info("myOpen: {s}", .{path});
    if (fi) |fi_nonnull| {
        inline for (std.meta.fields(@TypeOf(fi_nonnull))) |f| {
            std.log.debug(f.name ++ " {any}", .{@as(f.type, @field(fi_nonnull, f.name))});
        }
    }
    // get context
    const ctx = fu.c.fuse_get_context();
    // log uid
    log.info("uid: {}", .{ctx.*.uid});

    return 0;
}

fn myRead(path: []const u8, buf: []u8, offset: i64, _: ?fu.FileInfo) i32 {
    log.info("myRead: {s}", .{path});

    const size = buf.len;
    const off: usize = @intCast(offset);
    const contents = "hello world\n";

    log.info("read: {s},size={},offset={}", .{ path, size, offset });

    if (off >= contents.len)
        return 0;

    const s = if (off + size > contents.len)
        contents.len - off
    else
        size;

    @memcpy(buf[0..s], contents[off..]);

    return @intCast(s);
}

const myOps = fu.Operations{
    .open = &myOpen,
    .read = &myRead,
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
