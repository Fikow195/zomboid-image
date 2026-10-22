#!/bin/bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
sandbox="$(mktemp -d)"
trap 'rm -rf "${sandbox}"' EXIT

mkdir -p "${sandbox}/usr/local/lib/pterohost"

printf '%s\n' \
    '#!/bin/bash' \
    'pterohost_setup_nss() { :; }' \
    'printf "[pterohost] visible\\n"' \
    > "${sandbox}/entrypoint.sh"

printf '%s\n' \
    '#!/bin/bash' \
    'printf "Powered by Pterohost - https://pterohost.com\\n"' \
    'printf "Images: https://github.com/Pterohost/pterodactyl-images\\n"' \
    > "${sandbox}/sysinfo.sh"

printf '%s\n' \
    '#!/bin/bash' \
    'pterohost_log() { printf "[pterohost] %s\\n" "$*"; }' \
    > "${sandbox}/usr/local/lib/pterohost/steam-update.sh"

printf '%s\n' \
    '#!/bin/bash' \
    'pterohost_panel_argv() { printf "[pterohost] %s\\n" "$*"; }' \
    > "${sandbox}/usr/local/lib/pterohost/launch.sh"

printf '%s\n' \
    '#!/bin/bash' \
    'pterohost_ident_sync() { printf "[pterohost] %s\\n" "$*"; }' \
    > "${sandbox}/usr/local/lib/pterohost/identity.sh"

chmod 0755 \
    "${sandbox}/entrypoint.sh" \
    "${sandbox}/sysinfo.sh" \
    "${sandbox}/usr/local/lib/pterohost/steam-update.sh" \
    "${sandbox}/usr/local/lib/pterohost/launch.sh" \
    "${sandbox}/usr/local/lib/pterohost/identity.sh"

bash "${repo_root}/scripts/rebrand.sh" "${sandbox}"

if grep -R -E '\[pterohost\]|Powered by Pterohost|pterohost\.com|github\.com/Pterohost/pterodactyl-images' \
    "${sandbox}/entrypoint.sh" \
    "${sandbox}/sysinfo.sh" \
    "${sandbox}/usr/local/lib/pterohost"; then
    printf 'FAIL: user-visible upstream branding remains\n' >&2
    exit 1
fi

grep -Fq '[ElysiumUp]' "${sandbox}/entrypoint.sh"
grep -Fq 'Powered by ElysiumUp' "${sandbox}/sysinfo.sh"
grep -Fq 'https://github.com/Fikow195/zomboid-image' "${sandbox}/sysinfo.sh"

# Internal compatibility names are deliberately unchanged.
grep -Fq 'pterohost_setup_nss()' "${sandbox}/entrypoint.sh"
grep -Fq 'pterohost_log()' "${sandbox}/usr/local/lib/pterohost/steam-update.sh"
grep -Fq 'pterohost_panel_argv()' "${sandbox}/usr/local/lib/pterohost/launch.sh"
grep -Fq 'pterohost_ident_sync()' "${sandbox}/usr/local/lib/pterohost/identity.sh"

test -x "${sandbox}/entrypoint.sh"
test -x "${sandbox}/usr/local/lib/pterohost/steam-update.sh"

bash -n "${repo_root}/scripts/rebrand.sh"
bash -n "${repo_root}/scripts/verify-image.sh"

grep -Fq 'ghcr.io/pterohost/pterodactyl-images@sha256:' "${repo_root}/Dockerfile"
if grep -Eq '^[[:space:]]*(ENTRYPOINT|CMD)[[:space:]]' "${repo_root}/Dockerfile"; then
    printf 'FAIL: Dockerfile overrides inherited ENTRYPOINT or CMD\n' >&2
    exit 1
fi

printf 'All rebranding contract tests passed.\n'
