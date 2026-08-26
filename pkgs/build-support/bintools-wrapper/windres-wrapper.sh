#! @shell@
# shellcheck shell=bash

if (( "${NIX_DEBUG:-0}" >= 7 )); then
    set -x
fi

exec "@prog@" \
    -I@libc_dev@/crt/include \
    -I@libc_dev@/sdk/include/um \
    -I@libc_dev@/sdk/include/ucrt \
    -I@libc_dev@/sdk/include/shared \
    "$@"
