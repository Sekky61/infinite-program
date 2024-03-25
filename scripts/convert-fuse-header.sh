zig translate-c -D_FILE_OFFSET_BITS=64 -DFUSE_USE_VERSION=316 /usr/local/include/fuse3/fuse.h -lc > src/fuse_header_structs.zig

# For better results, check out https://github.com/lassade/c2z
# zig build run --  -D_FILE_OFFSET_BITS=64 -DFUSE_USE_VERSION=316   /usr/local/include/fuse3/fuse.h

