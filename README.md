# ElysiumUp Project Zomboid image

`ghcr.io/fikow195/zomboid` is a minimally modified Project Zomboid dedicated
server image for Pterodactyl Wings. It inherits the proven SteamCMD, Build
41/42, JVM heap, configuration, persistence, mod, console and graceful-shutdown
behavior from the Pterohost image and changes only user-visible branding.

The repository intentionally contains no node addresses, hosting credentials,
tokens, customer data or ElysiumUp infrastructure variables. All examples use
placeholders.

## Upstream and reproducibility

The base is pinned to the public `linux/amd64` manifest:

```text
ghcr.io/pterohost/pterodactyl-images@sha256:db80db6b9b7dde16d2d525aff207eac78e9b18f8e145661f5079d4582bc028f8
```

Upstream source: <https://github.com/Pterohost/pterodactyl-images>

The derivative does not replace `/usr/local/bin/start-zomboid`, rename any
`pterohost_*` function, or change upstream configuration and persistence paths.
`ENTRYPOINT ["/usr/bin/tini", "--"]` and
`CMD ["/bin/bash", "/entrypoint.sh"]` are inherited from the base image.

Only `linux/amd64` is supported because the upstream Project Zomboid server
depot and pinned image are amd64-only.

## Image tags

- `latest` tracks successful builds from `main`.
- `1.2.3` is an immutable semantic release tag.
- `sha-<commit>` identifies an individual source revision.

For production, prefer a version tag or the registry digest returned after a
release instead of `latest`.

## Pterodactyl installation

In the Pterodactyl admin panel, open the existing Project Zomboid egg and add:

```text
ElysiumUp Project Zomboid|ghcr.io/fikow195/zomboid:latest
```

Select the image for the server. Keep the egg's installation script, startup
command, stop command, allocations and variables unchanged. A typical existing
startup command is `start-zomboid`; do not replace the egg merely to use this
image.

The server volume remains `/home/container`. Existing game files, worlds,
configuration, mods and identity markers are not copied, deleted or migrated
by this derivative layer.

## Supported environment variables

All variables supported by the pinned upstream image remain available. The
most relevant ones are listed below; defaults are upstream defaults.

| Variable | Purpose |
| --- | --- |
| `STARTUP` | Pterodactyl startup template; `{{VAR}}` placeholders are expanded by the inherited entrypoint. |
| `SERVER_NAME` | Filename-safe server identity used by Project Zomboid for configuration and world paths. |
| `SERVER_PUBLIC_NAME` | Optional public browser name. |
| `SERVER_DESCRIPTION` | Optional public server description. |
| `SERVER_PORT`, `STEAM_PORT` | Game and Steam ports supplied by the egg. |
| `MAX_PLAYERS` | Optional maximum player count. |
| `SERVER_PUBLIC`, `SERVER_PASSWORD` | Public-listing and join-password settings. |
| `ADMIN_USER`, `ADMIN_PASSWORD` | Initial administrator credentials. |
| `RCON_PORT`, `RCON_PASSWORD` | RCON settings used by panel integrations. |
| `SERVER_MEMORY` | Container plan memory in MiB; upstream derives `-Xmx` from it. |
| `ZOMBOID_MAX_HEAP_MB` | Optional explicit maximum heap override. |
| `ZOMBOID_MIN_HEAP_MB` | Optional initial heap override; upstream default is 128 MiB. |
| `ZOMBOID_HEAP_PCT` | Optional percentage applied to `SERVER_MEMORY`. |
| `ZOMBOID_GC` | Garbage collector selection; upstream default is `g1`, with `zgc` opt-in. |
| `AUTO_UPDATE` | Set to `0` to skip the automatic SteamCMD update. |
| `STEAM_VALIDATE` | Set to `1` to request SteamCMD validation. |
| `SRCDS_APPID`, `SRCDS_BETAID`, `SRCDS_BETAPASS` | Steam app, branch and optional branch password compatibility variables. |
| `STEAMCMD_ATTEMPTS`, `STEAMCMD_TIMEOUT`, `STEAMCMD_RETRY_SLEEP` | Advanced SteamCMD retry controls. |
| `STEAM_BRANCH_FALLBACK` | Controls fallback to the public branch after an invalid branch selection. |
| `ZOMBOID_CASE_MIRROR` | Build 42 mod animation case-mirroring switch. |
| `ZOMBOID_CASE_MIRROR_WINDOW` | Time window in seconds for watching Workshop changes. |
| `ZOMBOID_STOP_TIMEOUT`, `ZOMBOID_KILL_TIMEOUT` | Graceful shutdown timeouts. |
| `ADDITIONAL_ARGS` | Additional Project Zomboid launch arguments. |

Do not bake secrets into this repository or Dockerfile. Configure sensitive
values such as passwords only through Pterodactyl's secret/protected variable
mechanism.

## Build and test

Docker with BuildKit is required:

```bash
docker build --platform linux/amd64 -t elysiumup-zomboid:test .
bash tests/rebrand.test.sh
bash scripts/verify-image.sh elysiumup-zomboid:test
```

The verification checks the inherited entrypoint, command and user; executable
flags; required internal functions; branding; OCI labels; and that the complete
`start-zomboid` script is byte-for-byte identical to the pinned base. That last
comparison covers the upstream JVM, persistence, mod and shutdown logic.

These checks do not start a real Project Zomboid server. A real startup test
requires a disposable server volume, network access to Steam, the normal egg
variables and enough time for the depot download. Do not report runtime success
until that test has completed and the server has also passed a panel Stop test.

## Updating the upstream base

1. Resolve the new public `zomboid` `linux/amd64` manifest digest.
2. Review upstream changes and its license.
3. Update the `UPSTREAM_IMAGE` default and `org.opencontainers.image.base.digest`
   together.
4. Run the local tests and a disposable Pterodactyl startup/stop test.
5. Tag a new semantic release only after all checks pass.

The base is intentionally not updated automatically: digest changes can alter
memory behavior, persistence or shutdown semantics and require review.

## Publishing

Pushes to `main`, semantic tags such as `1.0.0`, and manual dispatches run the
GitHub Actions workflow. The workflow uses Buildx, the GitHub Actions cache and
`GITHUB_TOKEN` with `contents: read` and `packages: write` only. It publishes to
`ghcr.io/fikow195/zomboid` after the verification job succeeds.

The organization must permit Actions to create packages and the workflow token
must have package write access. Package visibility can then be changed in the
GitHub package settings if public anonymous pulls are desired.

## License and attribution

The upstream repository is MIT-licensed. Its original copyright and license
text are preserved in [LICENSE](LICENSE), with additional attribution in
[NOTICE](NOTICE). ElysiumUp does not claim authorship of upstream runtime code,
Project Zomboid, SteamCMD or any other third-party component.
