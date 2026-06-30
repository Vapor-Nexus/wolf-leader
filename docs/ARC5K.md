# Arc5K — Architecture Optimizer in Wolf Leader

Arc5K reviews a whole app end to end — database, ETL, backend, API, and Vue
frontend — **read-only, never touching production**. It finds the real
structural problems (the same logic copied in several places, missing keys and
indexes, dead tables, logic in the wrong layer) and explains the fixes in
dead-simple plain English, ranked worst-first, with a phased fix plan and a
target database-shape guide.

## How it works in Wolf Leader

Wolf Leader stays what it is — orchestration and storage. It does **not** analyze
code itself. Instead:

```
You click "Arc5K" on a project
        │
        ▼
Wolf Leader builds a ready-to-run review prompt for that project
        │
        ▼
Your AI assistant (Cursor/Claude) runs the `arc5k` skill, doing the actual
read-only review and running the tools Arc5K relies on
        │
        ▼
The finished report is filed back into the project's memory
(via the arc5k_review MCP tool, or the report endpoint)
```

So the AI assistant does the reviewing; Wolf Leader sets up the job and keeps the
result alongside everything else it remembers about the project.

## Using it from the Web UI

1. Open a project.
2. Click the **Arc5K** button (top of the project view). Hover it for a one-line
   description of what it does.
3. The review prompt is copied to your clipboard. Paste it into your AI assistant.
4. When the assistant finishes, the report lands in `docs/arch-review/<date>/` in
   the project repo and is filed into the project's memory in Wolf Leader.

## API and MCP

- `POST /api/projects/{slug}/arc5k` — returns the kickoff prompt. Optional body
  `{"layers": ["db","api"]}` to scope the review (default: all layers).
- `POST /api/projects/{slug}/arc5k/report` — body `{"report": "...markdown..."}`
  files a finished review into the project's memory.
- MCP tool `arc5k_review` — call with no `report` to get the kickoff prompt; call
  again with `report=<markdown>` to file the review. `layers` is a comma-separated
  subset of `holistic,db,etl,backend,api,frontend`.

The Arc5K skill itself ships under `examples/cursor/skills/arc5k/` and is installed
to `~/.cursor/skills/arc5k/` by `scripts/install-cursor-client.sh` (and via the
hub client bundle), alongside the `save` and `new` skills.

## Context storage: shared folder or network drive

All Wolf Leader context (the SQLite DB + Markdown projects, including Arc5K
reports) lives in the mounted data volume. Point it wherever you like:

- **Local (default):** `WOLF_LEADER_DATA_DIR=./data` in `.env`.
- **Shared folder / already-mounted network drive:** set `WOLF_LEADER_DATA_DIR` to
  that path, e.g. `WOLF_LEADER_DATA_DIR=/Volumes/team-share/wolf-leader`, then
  `docker compose up -d`.
- **NFS share, attached directly (no host mount):** use the overlay and set the
  server address + export path in `.env`:

  ```bash
  WOLF_LEADER_NFS_ADDR=192.168.1.50
  WOLF_LEADER_NFS_PATH=/exports/wolf-leader
  docker compose -f docker-compose.yml -f docker-compose.netdrive.yml up -d --build
  ```
