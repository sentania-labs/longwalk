# Client 03a placement fix

Authorization: Scott said "okay go" after approving frozen client placements. Regime: software, under the standing isolated-prototype exception. No commit, PR, server replacement or world-data change.

Observed on Windows: "Rendered placements do not match authored baseline". The old client recomputed placement selection and compared floating-point-formatted strings. The exact first mismatch on Windows is unresolved; platform rounding or selection differences are plausible, not proven.

Fix: freeze the verified Linux arrangement into world/visuals.json, preserving every final holder and model transform, including bridge offsets and fitted fence widths. Runtime loads these records directly. Their ordered identities and baseline digest must match the existing authored collision baseline. Bad manifests still fail validation with the offending index where applicable. The server baseline bytes and network protocol are unchanged.

Review: checked all placement identities, complete transform matrices, asset keys, resource-tree identity, building/tree counts, bridge/fence adjustments and unchanged baseline digest. No runtime placement filtering or decimal-string regeneration remains in the normal scene path. The authoring recipe is retained only for the explicit bake tool.

Windows execution still requires Scott's playtest. This fix addresses the observed startup guard; it cannot establish that no other Windows-specific issue exists.

Validation: manifest tests passed for all 3,099 identities, precise matrices and rejection of wrong baselines, missing records, wrong identities and non-finite values. The actual exported Linux 03a binary loaded the frozen scene and passed its free-inspection check under software rendering. Startup screenshot was visually inspected. This run was deliberately offline to avoid registering a test player on Scott's live world; its zero network actors are expected. Windows export and ZIP integrity passed. Baseline SHA remains 016fd438d874cbe7251ab0b97625bab9f7cc6f1761abdc6bf793d547a04fe3a0.

Follow-up found during offline verification: the existing connection monitor can show a server-timeout message before a connection attempt, due to Godot's default offline peer. This does not prevent Connect/Retry and is separate from the placement startup failure. Record for the UI/control pass.
