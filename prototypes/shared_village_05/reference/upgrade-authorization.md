# Local 05 upgrade authorization

Scott: "go for it"

In response to: "May I back up your world and switch the server to 05?"

Live infrastructure, explicitly authorized local prototype upgrade. Stop the writer, preserve a full 04 volume backup, replace the container using the verified 05 image, and retain Compose project longwalk-playtest and volume longwalk-playtest_world-data. Verify old character/world facts and 05 handshake. Rollback to 04 requires the stopped pre-upgrade backup. No DNS, firewall or Kubernetes changes.

Completed: live container runs verified 05 image on UDP 7777, healthy and WORLD READY. Backup: `/home/scott/.local/state/longwalk/backups/before-05-20260910T213815Z` (private directory). All backup JSON checksums passed. The 05 loader validated the actual saved world as schema 2 with all prior character and world fields preserved: three characters, tree harvested, world resumed. All pre-upgrade volume files remain byte-identical. Live 05 protocol handshake passed without registering a traveler. Schema migration is in memory until the next normal save.
