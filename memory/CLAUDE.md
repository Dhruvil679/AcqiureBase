# CLAUDE.md — AcquireBase Memory Vault

This vault is a persistent, structured project memory for AcquireBase. It lives inside the repo at `D:\Marketplace\acquirebase\memory\` and is designed to be opened as an Obsidian vault.

## How future sessions should use this vault

1. **Read `index.md` first** at the start of every session. It is the one-page current-state snapshot.
2. If you need detail on a specific area, drill into the relevant file under `architecture/`, `status/`, `decisions/`, or `issues/`.
3. Do not rely on conversation history for project state — this vault is the source of truth.

## Update discipline

At the end of any substantial work session (or when the user says "wrap up" / "save progress"), update the vault:

- **`index.md`** — keep current. It should reflect actual state, not history.
- **`log.md`** — append one dated entry summarizing what happened this session (a few lines only).
- **`status/implemented.md`**, **`status/in-progress.md`**, **`status/todo.md`** — move items between these files as work actually progresses.
- **`decisions/`** — add a new short file for any significant architectural choice made this session: decision + one or two sentence rationale.
- **`issues/known-issues.md`** — add or resolve entries as bugs/limitations are found or fixed.

## What NOT to do

- Don't let `index.md` become a dumping ground. Keep it roughly one page.
- Don't append endless history to state files — that belongs in `log.md`.
- Don't duplicate the full codebase here. Summarize and point to files.
- Don't fabricate state. If the vault contradicts the actual code, verify and fix the vault.

## Vault structure

```
memory/
├── CLAUDE.md              ← this file
├── index.md               ← read first, every session
├── log.md                 ← append-only session log
├── architecture/
│   ├── overview.md        ← structure, stack, high-level design
│   ├── data-model.md      ← Firestore collections, fields, relationships
│   └── security.md        ← rules, custom claims, rate limiting
├── decisions/             ← one file per significant decision
├── status/
│   ├── implemented.md     ← fully working now
│   ├── in-progress.md     ← actively being built
│   └── todo.md            ← left to do, in priority order
└── issues/
    └── known-issues.md    ← bugs, limitations, flagged items
```
