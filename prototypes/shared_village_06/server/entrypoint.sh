#!/bin/sh
set -eu
# Container stop asks the single world writer to checkpoint before it exits.
rm -f /tmp/world-stop /tmp/world-ready
stop_world() {
    touch /tmp/world-stop
    result=0
    wait "$world_pid" || result=$?
    exit "$result"
}
trap stop_world TERM INT
flock -n -F /data/world.lock godot --headless --path /app -- --server --data=/data &
world_pid=$!
wait "$world_pid"
