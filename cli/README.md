# Pocket Engineer CLI

Run [Claude Code](https://docs.anthropic.com/en/docs/claude-code) on your EC2 from any terminal. Sessions survive disconnects — close your laptop, pick up on your phone.

## Install

```bash
brew tap vaibs-d/pocketengineer https://github.com/vaibs-d/pocketengineer
brew install pocket-engineer
```

Or manually:

```bash
curl -fsSL https://raw.githubusercontent.com/vaibs-d/pocketengineer/main/pocket-engineer -o /usr/local/bin/pocket-engineer
chmod +x /usr/local/bin/pocket-engineer
```

## Quick Start

```bash
# Provision a new EC2 with Claude Code + your tools
pocket-engineer init

# Scan the QR code with the Pocket Engineer iOS app — done.
```

## Usage

```bash
# Interactive Claude Code session
pocket-engineer

# Send a one-shot prompt
pocket-engineer "build a REST API with Express and Postgres"

# Sync your local project + session to EC2 (pick up on phone)
pocket-engineer sync

# Show QR code for phone app
pocket-engineer --qr

# Resume a previous session
pocket-engineer --list
pocket-engineer --resume <session-id>

# Reattach after disconnect
pocket-engineer --attach

# Check if Claude is running
pocket-engineer --status
```

## How it works

```
┌──────────┐     SSH + tmux     ┌──────────────────┐
│  Laptop  │ ──────────────────▶│   Your EC2       │
│ terminal │                    │  ┌────────────┐  │
└──────────┘                    │  │ Claude Code │  │
                                │  │  (in tmux)  │  │
┌──────────┐     SSH + tmux     │  └────────────┘  │
│  Phone   │ ──────────────────▶│                  │
│   app    │                    │  ~/projects/     │
└──────────┘                    └──────────────────┘
```

1. `pocket-engineer init` provisions an EC2 with Claude Code, Node, Python, Git, tmux, and your tools
2. The CLI opens SSH and runs Claude Code inside a **tmux** session
3. tmux keeps the session alive even when you disconnect
4. `pocket-engineer sync` pushes your local project + session context to EC2
5. Pick up the same session on your phone with the **Pocket Engineer** iOS app

## Configuration

Run `pocket-engineer setup` or set environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `POCKET_ENGINEER_HOST` | EC2 IP or hostname | *(required)* |
| `POCKET_ENGINEER_USER` | SSH user | `ec2-user` |
| `POCKET_ENGINEER_KEY` | Path to SSH private key | `~/.ssh/pocket-engineer.pem` |
| `POCKET_ENGINEER_DIR` | Remote working directory | `~/projects` |

## Requirements

- AWS account (for EC2 provisioning)
- AWS CLI installed (`brew install awscli`)
- An Anthropic API key ([console.anthropic.com](https://console.anthropic.com))

## Companion App

The **Pocket Engineer** iOS app connects to your EC2 via QR code scan and gives you a mobile interface to steer Claude Code from your phone.

## License

MIT
