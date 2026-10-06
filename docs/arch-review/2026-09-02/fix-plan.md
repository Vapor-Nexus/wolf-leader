# Fix Plan — Wolf Leader

A phased, do-this-then-that list. Each phase leaves the app working. Start at the
top. Nothing here changes production automatically — these are changes for a
human (or agent) to make and review.

This plan assumes you are steering toward **Postgres + pgvector**, **`/wolfhowl`**
(broadcast), and **`/wolfeat`** (download). Do not spend a week polishing SQLite
constraints you are about to replace — put those rules on the new schema.

## Phase 1 — Quick wins (high pain, low effort)

- [ ] **Decide the winner:** database owns live facts; markdown is export for git. Write that as a one-pager the skills will fetch. (findings 8, 13)
- [ ] **Stop adding favorite slugs.** New purpose text goes on the project, not in `SLUG_STORIES`. (finding 6)
- [ ] **Mark dead doors.** Snippets + `/summarize` + `/query` as legacy in docs / UI hidden. Do not rebuild them. (finding 12)
- [ ] **Name the two skills in the design only** (no code required yet): `/wolfhowl` = broadcast, `/wolfeat` = eat. `/save` stays the light checkpoint.

_Why first:_ cheap clarity so later work does not copy the same story a seventh time.

## Phase 2 — Single source of truth (stop the drift)

- [ ] **Postgres schema** from `db-target.md`: unique slug, chat→project key, path aliases, first-class left-off, messages as the conversation. (findings 1, 2, 4, 9, 10, 13)
- [ ] **pgvector on the write path.** Insert/update of project, memory, session, catalog row also upserts its vector. No “embeddings off” default for this hub. (finding 3)
- [ ] **One recall view** (or one API payload) used by MCP `recall`, the web project tab, and `/wolfeat`. (findings 5, 11)
- [ ] **Generate** `PROJECT.md` / `AGENT_BRIEF.md` / `SPEC.yaml` from that data when a howl completes; git the export, not the database file.

_Why:_ collapse copied logic into one home before you teach agents two new verbs.

## Phase 3 — Right layer (move logic where it belongs)

- [ ] **Path match in the database** (`project_paths`), not a Python loop. (findings 4, 7)
- [ ] **Filesystem catalog** (path + name + mtime + short embedding) for registered project roots only. Search the catalog; do not crawl the NAS when someone asks. (see db-target)
- [ ] **File body RAG** only for files the chat cited, the howl just committed, or you approved from a catalog hit.
- [ ] **Web UI** loads one bundle. Distill regexes stop being a second search engine for paths.
- [ ] **Jobs table** for ingest / git / model pulls. Skills suggest; the hub records.

## Phase 4 — Bigger structural work (schedule it)

- [ ] **`/wolfhowl` and `/wolfeat` skills** — thin, fetch the live guide (same pattern as `/save`).
- [ ] **Default plate vs ask** (this is the fork you wanted nailed):

  **`/wolfhowl` with no extra prompts (always):**
  1. Resolve or create the project (slug + this machine’s workspace path as an alias).
  2. Save the conversation (messages).
  3. Extract memories / left-off into the database.
  4. Embed what just landed (session, memories, project summary).
  5. Refresh the filesystem *catalog* for this project root (names and paths, not every file body).
  6. Tell you what it did, in one short report.

  **`/wolfhowl` only after it asks (offer, do not assume):**
  - Commit/push the **knowledge export** to Synology git.
  - Commit/push the **project repo** (only if it is already a git repo and you say yes).
  - Embed **file bodies** that were cited or that a catalog hit suggested.
  - Start a **job** (model pull, deploy watch) via a connector.

  **`/wolfeat` with no extra prompts (always):**
  1. Resolve project (any path alias).
  2. Pull the one recall view (brief, memories, last howls, top catalog/RAG hits).
  3. Show open jobs / ingest still running.

  **`/wolfeat` only after it asks:**
  - `git pull` knowledge export and/or project repo on this machine.
  - Download a listed model to this client.
  - Open/read extra file bodies beyond the top hits.

- [ ] **Connectors** (Ollama / other LXCs) talk to the hub; they do not live inside the Wolf Leader container.
- [ ] **Retire** leftover JSON keys and unused snippet routes after the new path is the only path.

_Note:_ each box should be small enough to do and verify on its own. Finding numbers match `report.md`.
