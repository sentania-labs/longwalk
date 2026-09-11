# Follow-ups after Working Day 06

- Distant route bursts can take seconds with sixteen travelers. Budget/cached regional navigation needs work before raising population or claiming MMO capacity. The GUI now exposes action and simulation timing.
- Keep a stable handshake entry point across releases. Actual client 05 is rejected by the changed RPC layout before the friendly version message. Current playtest instructions explicitly pair 06 with port 7778.
- Investigate the nonfatal reconnect signal warning in Godot 4.3. Its RPC cache tracks a bound tree-exit callback but clears an unbound one in [the pinned engine source](https://github.com/godotengine/godot/blob/4.3/modules/multiplayer/scene_cache_interface.cpp). Engine changes still need Scott's decision. Functional reconnect and retained-goods evidence are separate from log cleanliness.
- Agree on a close-view person/doorway art target, then improve poses and furnishings. The window mark is provisional; Windows Explorer still uses the engine's resource icon. Override the window title independently of the retained 03 userdata directory in a later client update.
- Design growing inventory/interface bars and wider equipment discovery. Four quick slots and fixed constitution remain the working defaults here.
- Plan snapshot retention and off-volume recovery before continuous long-term use. Current snapshots are immutable full records with no automatic pruning; distributed ownership and database HA are not implemented.
