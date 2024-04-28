pub const c = @import("bindings.zig");

pub fn main(argv: [][*:0]u8, op: c.fuse_operations, private_data: anytype) i32 {
    const len: c_int = @intCast(argv.len);
    return c.fuse_main_real(len, @ptrCast(argv), @ptrCast(&op), @sizeOf(c.fuse_operations), private_data);
}
