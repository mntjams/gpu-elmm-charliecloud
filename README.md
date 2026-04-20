# Running ELMM with poisson-solver in Charliecloud

This repository contains the Charliecloud setup needed to run `ELMM` with the GPU based `poisson-solver` instead of the CPU based `PoisFFT`.
Changes made to `ELMM` itself (specifically the build system) to run with `poisson-solver` are in a separate repository.

## Precautions
Ensure that all commands are run from the same node as to not mismatch display driver / cuda driver versions.

## Building the Container
First build the image, convert it into a read-only directory named `imgdir` and inject the NVIDIA driver.
```bash
ch-image build -t atmos -f Dockerfile.atmos .
ch-convert -i ch-image -o dir atmos imgdir
ch-fromhost --nvidia imgdir
```
Afterwards, create the `read-write` directory your container will use
```bash
mkdir mapped
```

## Compiling the Source
```bash
ch-run -b mapped:/opt/build imgdir -- /bin/bash -c "cd /opt/build/poisson-solver && unset CC && unset CXX && cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=Yes -B build-release/ && make -C build-release/"
ch-run -b mapped:/opt/build imgdir -- /bin/bash -c "cd /opt/build/gpu-elmm/src && unset CC && unset CXX && ./make_release"
```
By default the non-distributed version is built.
You can build the distributed version by adding `-DUSE_MPI=Yes` into the `cmake` command.
Alternatively, you can do all this in interactive mode.

Start an interactive shell inside the container
```bash
ch-run -b mapped:/opt/build imgdir -- /bin/bash
cd /opt/build
```

Clone the (updated) `ELMM` and `poisson-solver` repositories
```bash
git clone https://github.com/mntjams/gpu-elmm
git clone https://gitlab.mff.cuni.cz/d3s/hpc/poisson-solver
```

Afterwards, compile the `poisson-solver`
```bash
cd poisson-solver

# Unset the host compilers
unset CC
unset CXX

cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=Yes -B build-release/
make -C build-release/
```

At last, compile `ELMM` and exit
```bash
cd ../gpu-elmm/src
./make_release
exit
```

# How to Run Testing Example
```bash
cp -r channel-simple mapped/elmm/examples/channel-simple
# TODO - `channel-simple` has all BCs set to periodic, this differs from the original `channel-simple`
# as that one had bottom and top NeumannStag.
# This solver type is not yet implemented in `poisson-solver` so I had to change it for now.
ch-run -b mapped:/opt/build imgdir -- /bin/bash -c "cd /opt/build/gpu-elmm/examples/channel-simple && ../../bin/gcc/release/ELMM"
```
