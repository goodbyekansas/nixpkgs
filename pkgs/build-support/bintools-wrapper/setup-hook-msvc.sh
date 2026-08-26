
bintoolsWrapper_addLinkVars () {
    # See ../setup-hooks/role.bash
    local role_post
    getHostRoleEnvHook

    if [[ -d "$1/lib64" && ! -L "$1/lib64" ]]; then
        export NIX_LDFLAGS_MSVC${role_post}+=" -libpath:$1/lib64"
    fi

    if [[ -d "$1/lib" ]]; then
        # Don't add the /lib directory if it actually doesn't contain any libraries. For instance,
        # Python and Haskell packages often only have directories like $out/lib/ghc-8.4.3/ or
        # $out/lib/python3.6/, so having them in LDFLAGS just makes the linker search unnecessary
        # directories and bloats the size of the environment variable space.
        local -a glob=( $1/lib/lib* )
        if [ "${#glob[*]}" -gt 0 ]; then
            export NIX_LDFLAGS_MSVC${role_post}+=" -libpath:$1/lib"
        fi
    fi
}

getTargetRole
getTargetRoleWrapper

addEnvHooks "$targetOffset" bintoolsWrapper_addLinkVars

for cmd in rc lib
do
    if
        PATH=$_PATH type -p "@targetPrefix@${cmd}" > /dev/null
    then
        export "${cmd^^}${role_post}=@targetPrefix@${cmd}";
    fi
done

# TODO: Make it possible to control if we
# are using MSVC-compatible tools or not
export AR${role_post}=$LIB${role_post}

# No local scope in sourced file
unset -v role_post cmd upper_case
