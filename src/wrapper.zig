//! FUSE bindings for Zig.
//! If you are looking for the documentation of the original C library, see [libfuse](https://libfuse.github.io/doxygen/index.html).

pub const c = @import("bindings.zig");
pub const std = @import("std");
const mem = std.mem;

var user_ops: Operations = undefined;

/// Main function of FUSE.
///
/// Parses command line options, registers the operations, mounts and starts event loop.
pub fn main(argv: [][*:0]u8, op: Operations, private_data: anytype) i32 {
    const len: c_int = @intCast(argv.len);
    user_ops = op;
    const c_ops = create_operations();
    return c.fuse_main_real(len, @ptrCast(argv), @ptrCast(&c_ops), @sizeOf(c.fuse_operations), private_data);
}

/// Create C fuse operations from Zig operations.
fn create_operations() c.fuse_operations {
    return mem.zeroInit(c.fuse_operations, .{
        .open = open,
        .read = read,

        .init = init,
        .getattr = getattr,
        .readdir = readdir,
    });
}

const filename: [:0]const u8 = "hello";
const contents = "Hello World\n";
const E = std.os.linux.E;
const log = std.log;

fn cErr(err: E) c_int {
    const n: c_int = @intFromEnum(err);

    return -n;
}

fn init(
    _: [*c]c.fuse_conn_info,
    cfg: [*c]c.fuse_config,
) callconv(.C) ?*anyopaque {
    log.info("internal init", .{});
    cfg.*.kernel_cache = 0;
    return null;
}

fn getattr(
    path: [*c]const u8,
    stat: ?*c.stat,
    _: ?*c.fuse_file_info,
) callconv(.C) c_int {
    var st = mem.zeroes(c.stat);
    const p = mem.span(path);

    if (mem.eql(u8, "/", p)) {
        log.info("stat of root: {s}", .{p});
        // Query for the root - for example, if mounted at /tmp/x, and `cd /tmp` or `ls /tmp` is executed,
        // this will be called.
        st.st_mode = c.S_IFDIR | 0o0755;
        st.st_nlink = 2;
    } else if (mem.eql(u8, filename, p[1..])) {
        log.info("stat of file: {s}", .{p});
        log.info("cl: {}", .{contents.len});
        st.st_mode = c.S_IFREG | 0o0444;
        st.st_nlink = 1;
        st.st_size = contents.len + 10000;
        st.st_uid = 1000;
    } else {
        log.info("stat of unknown: {s}", .{p});
        return cErr(E.NOENT);
    }

    stat.?.* = st;

    return 0;
}

const Stat = @import("std").os.linux.Stat;

fn readdir(
    path: [*c]const u8,
    buf: ?*anyopaque,
    filler: c.fuse_fill_dir_t,
    _: c.off_t,
    _: ?*c.fuse_file_info,
    _: c.fuse_readdir_flags,
) callconv(.C) c_int {
    const p = mem.span(path);

    log.info("readdir: {s}", .{p});

    if (!mem.eql(u8, "/", p))
        return cErr(E.NOENT);

    const names = [_][:0]const u8{ ".", "..", filename, "boo" };

    for (names) |n| {
        const ret = filler.?(buf, n, null, 0, .{ .bits = 0 });

        if (ret > 0)
            log.err("readdir: {s}: {}", .{ p, ret });
    }

    return 0;
}

/// File info structure.
///
/// This structure serves as a context for the file operations.
pub const FileInfo = struct {
    flags: std.os.linux.O,
    writepage: bool,
    direct_io: bool,
    keep_cache: bool,
    parallel_direct_writes: bool,
    flush: bool,
    nonseekable: bool,
    cache_readdir: bool,
    noflush: bool,
    fh: u64,
    lock_owner: u64,
    poll_events: u32,

    pub fn from_c(fi_c: *c.fuse_file_info) FileInfo {
        const fi: c.fuse_file_info_packed = @bitCast(fi_c.*);
        return FileInfo{
            .flags = @bitCast(fi.flags),
            .writepage = fi.writepage != 0,
            .direct_io = fi.direct_io != 0,
            .keep_cache = fi.keep_cache != 0,
            .parallel_direct_writes = fi.parallel_direct_writes != 0,
            .flush = fi.flush != 0,
            .nonseekable = fi.nonseekable != 0,
            .cache_readdir = fi.cache_readdir != 0,
            .noflush = fi.noflush != 0,
            .fh = fi.fh,
            .lock_owner = fi.lock_owner,
            .poll_events = fi.poll_events,
        };
    }
};

pub const Operations = struct {
    open: *const fn (path: []const u8, fi: ?FileInfo) i32,
    read: *const fn (path: []const u8, buf: []u8, offset: i64, fi: ?FileInfo) i32,
};

fn open(
    path: [*c]const u8,
    file_info: ?*c.fuse_file_info,
) callconv(.C) c_int {
    var fi: ?FileInfo = null;
    if (file_info) |info| {
        fi = FileInfo.from_c(info);
    }
    const path_slice: [:0]const u8 = std.mem.span(path);
    return user_ops.open(path_slice, fi);
}

fn read(
    path: [*c]const u8,
    buf: [*c]u8,
    size: usize,
    offset: c.off_t,
    file_info: ?*c.fuse_file_info,
) callconv(.C) c_int {
    log.info("internal read: {s}", .{path});
    var fi: ?FileInfo = null;
    if (file_info) |info| {
        fi = FileInfo.from_c(info);
    }
    const path_slice: [:0]const u8 = std.mem.span(path);
    const ptr: [*]u8 = @ptrCast(@alignCast(buf));
    const slice = ptr[0..size];
    return user_ops.read(path_slice, slice, offset, fi);
}
