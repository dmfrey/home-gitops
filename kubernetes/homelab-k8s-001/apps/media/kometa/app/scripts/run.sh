#!/usr/bin/env bash

echo "*** kometa: Movies + TV Shows ***"

python3 kometa.py \
    --run \
    --read-only-config \
    --run-libraries "Movies,TV Shows"
