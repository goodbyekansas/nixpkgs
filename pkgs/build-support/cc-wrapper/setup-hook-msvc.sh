clangclWrapper_addIncludes() {
    local role_post
    getHostRoleEnvHook
    if [ -d "$1/include" ]; then
        export NIX_CFLAGS_MSVC_COMPILE${role_post}+=" -external:I$1/include"
        found=1
    fi
}

addEnvHooks "$targetOffset" clangclWrapper_addIncludes
