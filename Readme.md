
## Instalation

Requires the `libfuse` shared library (`libfuse.so`).

Developed on version 3.16.2

## Development

### Dependencies

Requires the dev headers for `libfuse` (`fuse.h`).

I recommend going to [libfuse Github](https://github.com/libfuse/libfuse) and following the instructions there.

However, I will reiterate the steps here:

- Pick a release from Github and download it.
- Extract it 

```bash
mkdir build
cd build
meson setup ..
ninja
sudo ninja install
```

The lib files should be installed. Check the log to see where.

### Learn

- [libfuse Wiki](https://github.com/libfuse/libfuse/wiki)
- [API Docs (Doxygen)](https://libfuse.github.io/doxygen/)
- Inspired by [this article by Richard Palethorpe](https://richiejp.com/zig-fuse-one)

