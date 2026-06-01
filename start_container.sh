#!/bin/bash

set -ueo pipefail

srun -p gpu-short-teach -w volta04 --gpus=1 --pty ch-run -b mapped:/opt/build imgdir -- /bin/bash
