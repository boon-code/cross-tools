# Cross-Toolchain

Simple bash script to install binutils and gdb for a specific architecture.

## Install a tool-chain

To download and compile some cross-tool-chain, you only need to execute `setup.sh` on your linux host:

    [you@your-host cross-tools]$ ./setup.sh all

This command will download and build _binutils_ and _GDB_ for `Renesas SuperH` architecture
in your `/tmp` folder. Following environment variable can be modified to change various
properties:

- `BINUTILS_VERSION`: Version number of _binutils_ to use
- `GDB_VERSION`:      Version of _GDB_ to use
- `MAKE_PARALLEL`:    Number of concurrent tasks that may run (typically you want to set it to _number of CPU's + 1_)
- `TARGET`:           Target architecture short-name (see _binutils_, _GDB_ for a list of supported architectures)
- `WORKDIR`:          Working directory where to build your tool-chain (default: `/tmp`)

For example to change the working directory to `./workdir` and your target architecture to sh64-elf
use following command:

    [you@your-host cross-tools]$ mkdir -p workdir  # ensure it exists...
    [you@your-host cross-tools]$ WORKDIR=./workdir TARGET=sh64-elf ./setup.sh all

## Using the tool-chain:

During build, a minimal bash script `environment-$TARGET` (where $TARGET is your choosen architecture)
has been generated in your choosen working directory. You can _source_ the file into your shell to override
your default tool-chain (by prepending `$PATH`) like this (assuming that `WORKDIR` has been set to `./workdir`
and `TARGET` has been set to `sh64-elf`):

    [you@your-host cross-tools]$ source ./workdir/environment-sh64-elf
    (X) [you@your-host cross-tools]$ # Now you binutils and GDB as you wish...
    ...
    ...
    (X) [you@your-host cross-tools]$ # To disable cross-tools run (deactivate alias or cross_deactivate)
    (X) [you@your-host cross-tools]$ deactivate
    [you@your-host cross-tools]$ # Back to normal...

## Credits

The idea has been adopted from https://github.com/blukat29/docker-cross
