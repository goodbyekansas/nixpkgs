#! @shell@
set -eu -o pipefail +o posix
shopt -s nullglob

if (( "${NIX_DEBUG:-0}" >= 7 )); then
    set -x
fi

var_templates_list=(
    NIX_CFLAGS_MSVC_COMPILE
    NIX_CFLAGS_MSVC_COMPILE_BEFORE
    NIX_LDFLAGS_MSVC
)

source @out@/nix-support/utils.bash
accumulateRoles

# We need to mangle names for hygiene, but also take parameters/overrides
# from the environment.
for var in "${var_templates_list[@]}"; do
    mangleVarList "$var" ${role_suffixes[@]+"${role_suffixes[@]}"}
done

cInclude=1
link=true
nonFlagArgs=0

extraAfter=()
extraBefore=()

expandResponseParams "$@"
declare -ag positionalArgs=()
declare -i n=0
nParams=${#params[@]}
while (( "$n" < "$nParams" )); do
    p=${params[n]}
    p2=${params[n+1]:-} # handle `p` being last one
    n+=1
  case "$p" in
    /c|-c) link=false;;
    -nostdlib)
      ;;
    --) # Everything else is positional args!
        # See: https://github.com/llvm/llvm-project/commit/ed1d07282cc9d8e4c25d585e03e5c8a1b6f63a74

        # Any positional arg (i.e. any argument after `--`) will be
        # interpreted as a "non flag" arg:
        if [[ -v "params[$n]" ]]; then nonFlagArgs=1; fi

        positionalArgs=("${params[@]:$n}")
        params=("${params[@]:0:$((n - 1))}")
        break;
        ;;
  esac
done

if [ -e @out@/nix-support/cc-cflags-msvc ]; then
    NIX_CFLAGS_MSVC_COMPILE_@suffixSalt@="$(< @out@/nix-support/cc-cflags-msvc) $NIX_CFLAGS_MSVC_COMPILE_@suffixSalt@"
fi

if [[ "$cInclude" = 1 ]] && [ -e @out@/nix-support/libc-cflags-msvc ]; then
    NIX_CFLAGS_MSVC_COMPILE_@suffixSalt@="$(< @out@/nix-support/libc-cflags-msvc) $NIX_CFLAGS_MSVC_COMPILE_@suffixSalt@"
fi

if [ -e @out@/nix-support/cc-cflags-before-msvc ]; then
    NIX_CFLAGS_MSVC_COMPILE_BEFORE_@suffixSalt@="$(< @out@/nix-support/cc-cflags-before-msvc) $NIX_CFLAGS_MSVC_COMPILE_BEFORE_@suffixSalt@"
fi

extraBefore=($NIX_CFLAGS_MSVC_COMPILE_BEFORE_@suffixSalt@)
extraAfter=($NIX_CFLAGS_MSVC_COMPILE_@suffixSalt@)

if [[ "$cInclude" = 1 ]] && [ -e @bintools@/nix-support/libc-ldflags-msvc ]; then
  NIX_LDFLAGS_MSVC_@suffixSalt@="$(< @bintools@/nix-support/libc-ldflags-msvc) $NIX_LDFLAGS_MSVC_@suffixSalt@"
fi


if [ $link = true ]; then
  for op in $NIX_LDFLAGS_MSVC_@suffixSalt@; do
    extraAfter+=("-Xlinker" "$op")
  done
fi

# Finally, if we got any positional args, append them to `extraAfter`
# now:
if [[ "${#positionalArgs[@]}" -gt 0 ]]; then
    extraAfter+=(-- "${positionalArgs[@]}")
fi

if [[ -e @out@/nix-support/add-local-cc-cflags-before.sh ]]; then
    source @out@/nix-support/add-local-cc-cflags-before.sh
fi

# As a very special hack, if the arguments are just `-v', then don't
# add anything.  This is to prevent `gcc -v' (which normally prints
# out the version number and returns exit code 0) from printing out
# `No input files specified' and returning exit code 1.
if [ "$*" = -v ]; then
    extraAfter=()
    extraBefore=()
fi

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
