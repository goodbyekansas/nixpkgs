#! @shell@
set -eu -o pipefail +o posix
shopt -s nullglob

if (( "${NIX_DEBUG:-0}" >= 7 )); then
    set -x
fi

var_templates_list=(
    NIX_LDFLAGS_MSVC
)

source @out@/nix-support/utils.bash
accumulateRoles

# We need to mangle names for hygiene, but also take parameters/overrides
# from the environment.
for var in "${var_templates_list[@]}"; do
    mangleVarList "$var" ${role_suffixes[@]+"${role_suffixes[@]}"}
done


extraAfter=()
extraBefore=()

expandResponseParams "$@"

if [ -e @out@/nix-support/libc-ldflags-msvc ]; then
  NIX_LDFLAGS_MSVC_@suffixSalt@="$(< @out@/nix-support/libc-ldflags-msvc) $NIX_LDFLAGS_MSVC_@suffixSalt@"
fi

extraAfter=($NIX_LDFLAGS_MSVC_@suffixSalt@)

if (( "${NIX_DEBUG:-0}" >= 1 )); then
    # Old bash workaround, see ld-wrapper for explanation.
    echo "extra flags before to @prog@:" >&2
    printf "  %q\n" ${extraBefore+"${extraBefore[@]}"}  >&2
    echo "original flags to @prog@:" >&2
    printf "  %q\n" ${params+"${params[@]}"} >&2
    echo "extra flags after to @prog@:" >&2
    printf "  %q\n" ${extraAfter+"${extraAfter[@]}"} >&2
fi

exec @prog@ \
   ${extraBefore+"${extraBefore[@]}"} \
   ${params+"${params[@]}"} \
   ${extraAfter+"${extraAfter[@]}"}
