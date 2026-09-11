FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends libfontconfig1 && rm -rf /var/lib/apt/lists/*
RUN test -x /usr/bin/flock && mkdir -p /data /app
COPY godot /usr/local/bin/godot
COPY app/ /app/
COPY entrypoint.sh /usr/local/bin/world-entrypoint
RUN chmod 755 /usr/local/bin/world-entrypoint
WORKDIR /app
EXPOSE 7777/udp
VOLUME ["/data"]
ENV HOME=/tmp LONGWALK_HEALTH_FILE=/tmp/world-ready
HEALTHCHECK --interval=10s --timeout=3s --start-period=20s CMD test -f /tmp/world-ready && test $(( $(date +%s) - $(stat -c %Y /tmp/world-ready) )) -lt 15
ENTRYPOINT ["/usr/local/bin/world-entrypoint"]
