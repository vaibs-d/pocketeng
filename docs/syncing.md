# Syncing Projects

Push a local project to your EC2 so you can work on it from your phone.

## Basic sync

```bash
cd ~/my-project
pocket-engineer sync
```

This does three things:

1. Asks Claude to write a **handoff document** summarizing your current session
2. Rsyncs your project files to `~/projects/my-project` on EC2
3. Places `.handoff.md` in the remote project root

When you open the project on your phone and start a new session, Claude reads the handoff and knows exactly where you left off.

## Sync a specific directory

```bash
pocket-engineer sync /path/to/project
```

## Sync to a specific server

```bash
pocket-engineer sync --server work
```

## What gets synced

Everything except:

- `.git`, `node_modules`, `.build`, `DerivedData`
- `dist`, `.next`, `__pycache__`, `venv`, `.env`
- Binary files over 50MB
- The `.claude` directory

## What's a handoff?

When you run `pocket-engineer sync`, it asks your local Claude Code session to write a short document covering:

- What's been built so far
- Key decisions made
- What still needs to be done
- Important context (API keys needed, gotchas, etc.)

This lives at `.handoff.md` in the project root. The phone app's Claude session picks it up automatically.

You can also add your own notes during sync — the CLI will prompt you.
