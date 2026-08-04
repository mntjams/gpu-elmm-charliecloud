# Running ELMM with poisson-solver in Charliecloud

This repository contains the Charliecloud setup needed to run `gpu-elmm` with the GPU-based `poisson-solver`.
Changes made to `ELMM` to use `poisson-solver` are in a [separate repository](https://github.com/mntjams/gpu-elmm).

## Precautions
Ensure that all commands are run from the same worker node as to not mismatch display driver / cuda driver versions (e.g., when using `SLURM`, prefix all commands by `srun -w some_worker`).

## Building the Container
First build the image, convert it into a read-only directory named `imgdir` and inject the NVIDIA driver.
Beware that the build can take ~20m, the conversion ~40m and the injection of NVIDIA drivers up to 10m (allocate your jobs with enough time limit).
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
First, clone `poisson-solver` and `gpu-elmm`:
```bash
cd mapped/
git clone https://gitlab.mff.cuni.cz/d3s/hpc/poisson-solver.git
git clone https://github.com/mntjams/gpu-elmm.git
cd ..
```

Then, on the same worker node where you built the container, run:
```bash
ch-run -b mapped:/opt/build imgdir -- /bin/bash -c "cd /opt/build/poisson-solver && unset CXX && cmake --preset release && cmake --build build/"
ch-run -b mapped:/opt/build imgdir -- /bin/bash -c "cd /opt/build/gpu-elmm/src && unset CC && ./make_release"
```

This will build the local version of `poisson-solver` and `gpu-elmm`.
To build the distributed version use the `release-mpi` preset for `poisson-solver` instead of `release` and for `gpu-elmm` run `./make_mpi_release` instead of `./make_release`.

## Running an Example
You can now try one of the `gpu-elmm` examples, e.g. (don't forget to allocate a gpu!):
```bash
ch-run -b mapped:/opt/build imgdir -- /bin/bash -c "cd /opt/build/gpu-elmm/examples/simple && ../../bin/gcc/release/ELMM"
```
