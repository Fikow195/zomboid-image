#!/bin/bash

set -euo pipefail

image="${1:-}"
base_image="${BASE_IMAGE:-ghcr.io/pterohost/pterodactyl-images@sha256:db80db6b9b7dde16d2d525aff207eac78e9b18f8e145661f5079d4582bc028f8}"

if [ -z "${image}" ]; then
    printf 'Usage: %s IMAGE\n' "$0" >&2
    exit 2
fi

entrypoint="$(docker image inspect --format '{{json .Config.Entrypoint}}' "${image}")"
command="$(docker image inspect --format '{{json .Config.Cmd}}' "${image}")"
user="$(docker image inspect --format '{{.Config.User}}' "${image}")"

test "${entrypoint}" = '["/usr/bin/tini","--"]'
test "${command}" = '["/bin/bash","/entrypoint.sh"]'
test "${user}" = 'container'

test "$(docker image inspect --format '{{index .Config.Labels "org.opencontainers.image.title"}}' "${image}")" = 'ElysiumUp Project Zomboid'
test "$(docker image inspect --format '{{index .Config.Labels "org.opencontainers.image.vendor"}}' "${image}")" = 'ElysiumUp'
test "$(docker image inspect --format '{{index .Config.Labels "org.opencontainers.image.licenses"}}' "${image}")" = 'MIT'

docker run --rm --entrypoint /bin/bash "${image}" -euc '
    test -x /entrypoint.sh
    test -x /usr/local/bin/start-zomboid
    test -x /usr/local/lib/pterohost/steam-update.sh
    test -x /usr/local/lib/pterohost/launch.sh
    test -x /usr/local/lib/pterohost/identity.sh

    bash -n /entrypoint.sh
    bash -n /sysinfo.sh
    bash -n /usr/local/bin/start-zomboid
    bash -n /usr/local/lib/pterohost/steam-update.sh
    bash -n /usr/local/lib/pterohost/launch.sh
    bash -n /usr/local/lib/pterohost/identity.sh

    grep -Fq "pterohost_steam_update()" /usr/local/lib/pterohost/steam-update.sh
    grep -Fq "pterohost_panel_argv()" /usr/local/lib/pterohost/launch.sh
    grep -Fq "pterohost_ident_sync()" /usr/local/lib/pterohost/identity.sh
    grep -Fq "ProjectZomboid64.json" /usr/local/bin/start-zomboid
    grep -Fq ".pterohost-world-identity" /usr/local/bin/start-zomboid
    grep -Fq "graceful_stop()" /usr/local/bin/start-zomboid

    ! grep -Fq "[pterohost]" /entrypoint.sh /usr/local/lib/pterohost/steam-update.sh /usr/local/lib/pterohost/launch.sh /usr/local/lib/pterohost/identity.sh
    ! grep -Eq "Powered by Pterohost|pterohost\.com|github\.com/Pterohost/pterodactyl-images" /sysinfo.sh /motd.txt
    grep -Fq "[ElysiumUp]" /entrypoint.sh
    grep -Fq "Powered by ElysiumUp" /sysinfo.sh
'

# The whole Zomboid bootstrap remains byte-for-byte identical. This is the
# strongest guard for JVM sizing, server configuration, world persistence,
# mod handling and graceful shutdown behavior.
derived_hash="$(docker run --rm --entrypoint sha256sum "${image}" /usr/local/bin/start-zomboid | awk '{print $1}')"
base_hash="$(docker run --rm --entrypoint sha256sum "${base_image}" /usr/local/bin/start-zomboid | awk '{print $1}')"
test -n "${derived_hash}"
test "${derived_hash}" = "${base_hash}"

printf 'Image verification passed for %s.\n' "${image}"
printf 'Project Zomboid bootstrap SHA-256: %s\n' "${derived_hash}"
