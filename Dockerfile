ARG UPSTREAM_IMAGE="ghcr.io/pterohost/pterodactyl-images@sha256:db80db6b9b7dde16d2d525aff207eac78e9b18f8e145661f5079d4582bc028f8"
FROM ${UPSTREAM_IMAGE}

USER root

COPY --chmod=0755 scripts/rebrand.sh /usr/local/share/elysiumup/rebrand.sh
COPY --chmod=0644 branding/motd.txt /motd.txt
COPY --chmod=0644 branding/nodes.tsv /etc/pterohost/nodes.tsv

RUN /usr/local/share/elysiumup/rebrand.sh / \
    && rm -f /usr/local/share/elysiumup/rebrand.sh

LABEL org.opencontainers.image.title="ElysiumUp Project Zomboid" \
      org.opencontainers.image.vendor="ElysiumUp" \
      org.opencontainers.image.description="Optimized Project Zomboid dedicated server image for ElysiumUp Hosting" \
      org.opencontainers.image.source="https://github.com/Fikow195/zomboid-image" \
      org.opencontainers.image.documentation="https://github.com/Fikow195/zomboid-image#readme" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.base.name="ghcr.io/pterohost/pterodactyl-images:zomboid" \
      org.opencontainers.image.base.digest="sha256:db80db6b9b7dde16d2d525aff207eac78e9b18f8e145661f5079d4582bc028f8"

USER container
WORKDIR /home/container

# ENTRYPOINT and CMD are deliberately inherited unchanged from the pinned base:
#   ENTRYPOINT ["/usr/bin/tini", "--"]
#   CMD ["/bin/bash", "/entrypoint.sh"]
