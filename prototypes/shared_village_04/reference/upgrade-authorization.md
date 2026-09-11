# Local server upgrade authorization

Scott: "switch the world over"

Live infrastructure: explicit authorization to replace the local playtest container with the verified Shared Village 04 image. Preserve Compose project longwalk-playtest and volume longwalk-playtest_world-data. Stop the writer and back up its volume before replacement. Retain the 03 image and backup for recovery. No DNS, firewall or Kubernetes changes.

Completed: stopped-world backup at /home/scott/.local/state/longwalk/backups/before-04-20260910T194826Z. Upgraded the same Compose project and volume to image 04. Live 04 handshake passed without registering a test player. Full latest state matched the backup after startup, including positions, owner, harvested tree and resumed state. Container healthy on UDP 7777.
