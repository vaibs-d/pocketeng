# How It Works

No magic. Just SSH, tmux, and Claude Code.

## The setup

```
pocketeng init
```

This provisions a `t3.medium` EC2 in your AWS account and installs:

- Claude Code (via npm)
- Node.js, Python, Git, tmux
- Whatever else you picked (GitHub CLI, Docker, Vercel, etc.)
- Your Anthropic API key in `~/.bashrc`

You get an SSH key and a security group. That's the entire infrastructure.

## The connection

```
 Your laptop                        Your EC2
┌────────────┐                   ┌────────────────┐
│ terminal   │ ──── SSH ────────►│ tmux session   │
│            │                   │  └─ claude      │
└────────────┘                   └────────────────┘
```

When you run `pocketeng`, it:

1. Opens an SSH connection to your EC2
2. Creates a **tmux** session named `pocketeng`
3. Runs `claude` (Claude Code) inside that tmux session

That's it. You're now talking to Claude Code on the server.

## Why tmux matters

tmux is a terminal multiplexer — it keeps processes running even when you disconnect.

- Close your laptop lid → tmux keeps Claude running
- Wi-Fi drops → tmux keeps Claude running
- Reattach anytime with `pocketeng attach`

This is the same thing that happens when you run a long build in a tmux session on a server. Nothing new.

## The phone connection

```
 Your phone                         Your EC2
┌────────────┐                   ┌────────────────┐
│ Pocket Eng │ ──── SSH ────────►│ nohup claude   │
│ iOS app    │◄──── stdout ──────│  -p --verbose   │
└────────────┘                   └────────────────┘
```

The phone app connects to the same EC2 via SSH (using the key from the QR code). It runs Claude Code in headless mode (`claude -p --output-format stream-json`) via `nohup`, so the process survives even if the app goes to background.

The app parses the streaming JSON output in real time — that's how you see text, tool calls, and file edits appear live.

## Syncing

```
 Your laptop                        Your EC2
┌────────────┐     rsync         ┌────────────────┐
│ ~/my-app/  │ ─────────────────►│ ~/projects/    │
│            │                   │   my-app/      │
│ .handoff.md│ ─────────────────►│   .handoff.md  │
└────────────┘                   └────────────────┘
```

`pocketeng sync` rsyncs your local project to EC2 over SSH. It also generates a `.handoff.md` — a summary of your current Claude session so the phone session knows where you left off.

## What you own

- **The EC2** — it's in your AWS account, your region, your VPC
- **The SSH key** — stored locally at `~/.pocketeng/`
- **The code** — lives on your EC2, synced by you
- **The sessions** — Claude Code session files at `~/.claude/` on your EC2

There's no Pocket Eng server in the middle. No relay. No account. Direct SSH from your device to your EC2.
