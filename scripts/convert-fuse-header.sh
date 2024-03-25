zig translate-c -D_FILE_OFFSET_BITS=64 -DFUSE_USE_VERSION=316 /usr/local/include/fuse3/fuse.h -lc > src/fuse31.zig

