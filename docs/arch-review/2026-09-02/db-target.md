# Target Database Shape — Wolf Leader

A clear picture of how the database should be structured. This is the destination,
not a migration script. Keep it short and readable.

**Engine:** Postgres with `pgvector`. One database, one backup, vectors next to the rows they describe.

## Core tables (the nouns)

| Table | Holds | Key | Links to |
|-------|-------|-----|----------|
| projects | One row per project (name, unique slug, human summary) | id; slug UNIQUE | — |
| project_paths | Every way this project appears on disk (Windows, Mac, Linux, compose folder) | id | project_id → projects |
| chats | One saved conversation / howl | id | project_id → projects (required, or NULL only if explicitly unsorted) |
| messages | One utterance in that conversation | id | chat_id → chats ON DELETE CASCADE |
| memories | One typed fact (decision, constraint, …) | id | project_id → projects; source_chat_id → chats |
| howls | One broadcast event (what ran, what was offered, git/job ids) | id | project_id → projects; chat_id → chats |
| jobs | Long work: ingest, git push, model pull, remote task | id | project_id; howl_id optional |
| fs_catalog | One row per known file/dir under a registered root (path, hash, mtime, short blurb) | id | project_id → projects |
| file_chunks | Text slices of files you actually ingested | id | project_id; fs_catalog_id; howl_id |
| knowledge_revisions | Pointer to the git commit of the markdown export (not the vectors) | id | project_id; howl_id |

_Rule of thumb:_ one table per real-world thing, each row uniquely identified,
each link backed by a foreign key.

**Drop as first-class ideas:** `snippets`; two path columns on `projects` (`path` vs `compose_path` — those become `project_paths` with a `kind`); stuffing handoff into `metadata` JSON.

## Shared calculations (views)

| View | Computes | Reads from | Who uses it |
|------|----------|------------|-------------|
| v_project_recall | The one “eat this” picture: summary, left-off, recent memories, recent howls | projects, memories, chats, howls | MCP recall, `/wolfeat`, web UI |
| v_left_off | Latest human + agent handoff for a project | howls or memories of type active_work | UI logbook, agent pickup |
| v_search | Keyword + vector hits already merged (or a function that does RRF) | memories, chats, file_chunks, fs_catalog, embeddings | `/api/search`, `/wolfeat` extras |

_Rule of thumb:_ any number more than one place needs lives in a view, computed
once.

**Vectors:** `vector` columns (or a single `embeddings` table keyed by `kind, ref_id`) on memories, chats/howls, projects.summary, fs_catalog blurbs, file_chunks. Same model name stored on the row. Unique (kind, ref_id, model).

## What stores raw facts vs. derived values

- **Tables store raw facts** — messages, memory text, path aliases, file hashes, job state, git commit SHAs.
- **Views compute derived values** — “where we left off,” search ranking, the recall bundle.
- **Markdown on Synology** is a generated export of those facts (for git history). It is not a second database.
- **Never store** formatted pickup prompts or UI purpose strings as a competing source of truth. Generate them from `v_project_recall`.

## What to retire

- **`snippets`** — nothing in the UI uses them.
- **`chats.content` as a full second transcript** — keep a short logbook line if you want; body lives in `messages`.
- **`projects.metadata` junk drawer** for left-off / pickup — real columns or `howls`.
- **Hardcoded `SLUG_STORIES` / `SEED_FILES`** — project rows and optional `SEED.md` import.
- **Optional sqlite-vec side path** on the homelab default — keyword-only stays a lean overlay, not the main line.

## Picture

```
projects ──< project_paths          (Z:\, /Volumes, /volume1, compose)
    │
    ├──< memories                  (typed facts, vectorized on write)
    ├──< chats ──< messages        (raw conversation)
    │       └──< howls             (one broadcast; optional git + jobs)
    ├──< fs_catalog                (map of the share; cheap embeddings)
    └──< file_chunks               (bodies you chose to ingest)

v_project_recall  ←── all of the above (one document for /wolfeat)
knowledge git     ←── generated markdown export, pointed at by knowledge_revisions
```

## How `/wolfhowl` touches this (no extra prompts)

Write: `chats` + `messages` + `memories` + `howls` + vectors + `fs_catalog` refresh for that project’s roots.

Do **not** write `file_chunks` or `knowledge_revisions` until the agent asks and you agree.

`/wolfeat` reads `v_project_recall` (and open `jobs`). Pulling git or models is a job, not a silent default.
