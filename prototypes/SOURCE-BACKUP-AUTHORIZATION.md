# Source backup authorization

Scott: "let's just do a commit and push of our code to main so we aren't machine bound"
Scott: "not PR, not tag, no release just store our code"
Scott: "make sure to include roadmap, status, etc"

Software regime, with this explicit exception to the normal branch/PR/release flow: commit and push a source checkpoint directly to main. Preserve the unfinished 07 work as work in progress. Include prototype source, source art, foundation notes, roadmap, status and handoff. Exclude private state/credentials, generated exports and caches, and pre-existing unrelated deletions. This is storage of work, not a tested release, deployment or tag. CI is skipped for the unfinished checkpoint.
