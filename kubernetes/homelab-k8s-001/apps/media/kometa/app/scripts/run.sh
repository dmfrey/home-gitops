#!/usr/bin/env bash

kometa () {
    echo "*** kometa: $1 ***"

    python3 kometa.py \
        --run \
        --read-only-config \
        --run-libraries "$1"
}

kometa "Movies"
# kometa "TV Shows"
