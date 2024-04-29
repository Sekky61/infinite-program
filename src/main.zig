const std = @import("std");
const log = std.log;
const mem = std.mem;
const E = std.os.linux.E;
const fusebind = @import("bindings.zig");

const fu = @import("wrapper.zig");
const opos = fu.att;

const contents = "hello world, hello everybody\n";
const filename = "hello";

fn cErr(err: E) c_int {
    const n: c_int = @intFromEnum(err);

    return -n;
}

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

fn myReadDir(path: []const u8, buf: ?*anyopaque, filler: fu.c.fuse_fill_dir_t, _: i64, _: ?fu.FileInfo, _: fu.ReadDirFlags) i32 {
    log.info("readdir: {s}", .{path});

    if (!mem.eql(u8, "/", path))
        return 2;

    const names = [_][:0]const u8{ ".", "..", filename, "boo" };

    for (names) |n| {
        const ret = filler.?(buf, n, null, 0, .{ .bits = 0 });

        if (ret > 0)
            log.err("readdir: {s}: {}", .{ path, ret });
    }

    return 0;
}

fn myGetAttr(path: []const u8, stat: ?*fu.Stat, _: ?fu.FileInfo) i32 {
    var st = mem.zeroes(fu.Stat);

    if (mem.eql(u8, "/", path)) {
        log.info("stat of root: {s}", .{path});
        // Query for the root - for example, if mounted at /tmp/x, and `cd /tmp` or `ls /tmp` is executed,
        // this will be called.
        st.mode = fu.c.S_IFDIR | 0o0755;
        st.nlink = 2;
    } else if (mem.eql(u8, filename, path[1..])) {
        log.info("stat of file: {s}", .{path});
        log.info("cl: {}", .{contents.len});
        st.mode = fu.c.S_IFREG | 0o0445;
        st.blksize = 512;
        st.blocks = 1;
        st.nlink = 1;
        st.size = contents.len;
        st.uid = 1000;
    } else {
        log.info("stat of unknown: {s}", .{path});
        st.mode = fu.c.S_IFREG | 0o0444;
        st.nlink = 1;
        st.blksize = 512;
        st.blocks = 1;
        st.size = contents.len;
        st.uid = 1000;
    }

    stat.?.* = st;

    return 0;
}

fn myInit() ?*anyopaque {
    log.info("myInit", .{});

    return null;
}

const myOps = fu.Operations{
    .open = &myOpen,
    .read = &myRead,
    .readdir = &myReadDir,
    .getattr = &myGetAttr,
    .init = &myInit,
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
