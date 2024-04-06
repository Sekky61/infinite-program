const fuse = @import("fuse.zig");

const c = @cImport({
    @cInclude("fuse.h");
});
