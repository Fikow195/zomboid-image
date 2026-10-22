#!/bin/bash
# Change only user-visible branding. Internal pterohost_* functions, variables,
# paths, configuration keys and persistence markers intentionally stay intact.

set -euo pipefail

root="${1:-/}"
root="${root%/}"

entrypoint="${root}/entrypoint.sh"
sysinfo="${root}/sysinfo.sh"
steam_update="${root}/usr/local/lib/pterohost/steam-update.sh"
launch="${root}/usr/local/lib/pterohost/launch.sh"
identity="${root}/usr/local/lib/pterohost/identity.sh"

for file in "${entrypoint}" "${sysinfo}" "${steam_update}" "${launch}" "${identity}"; do
    if [ ! -f "${file}" ]; then
        printf 'Required upstream file is missing: %s\n' "${file}" >&2
        exit 1
    fi
done

# Console prefixes only. Do not rename functions or compatibility variables.
sed -i 's/\[pterohost\]/[ElysiumUp]/g' \
    "${entrypoint}" "${steam_update}" "${launch}" "${identity}"

# Startup footer and public source link.
sed -i \
    -e 's/Powered by Pterohost/Powered by ElysiumUp/g' \
    -e 's#https://pterohost\.com#https://github.com/elysiumup#g' \
    -e 's#https://github\.com/Pterohost/pterodactyl-images#https://github.com/Fikow195/zomboid-image#g' \
    "${sysinfo}"

if grep -Fq '[pterohost]' "${entrypoint}" "${steam_update}" "${launch}" "${identity}"; then
    printf 'A user-visible upstream console prefix remains after rebranding.\n' >&2
    exit 1
fi

if grep -Eq 'Powered by Pterohost|pterohost\.com|github\.com/Pterohost/pterodactyl-images' "${sysinfo}"; then
    printf 'A user-visible upstream footer remains after rebranding.\n' >&2
    exit 1
fi
