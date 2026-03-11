# Commands

## Setup

| Command | Description |
|---|---|
| `pocket-engineer init` | Provision a new EC2 with Claude Code and your tools |
| `pocket-engineer setup` | Connect to an existing EC2 |
| `pocket-engineer setup --name work` | Connect and save as a named profile |

## Sessions

| Command | Description |
|---|---|
| `pocket-engineer` | Start an interactive Claude Code session |
| `pocket-engineer "do something"` | Send a one-shot prompt |
| `pocket-engineer attach` | Reattach to a running session |
| `pocket-engineer resume <id>` | Resume a past session by ID |
| `pocket-engineer list` | List recent sessions |
| `pocket-engineer status` | Check if Claude is running |

## Sync & Phone

| Command | Description |
|---|---|
| `pocket-engineer sync` | Push current directory to EC2 with handoff doc |
| `pocket-engineer sync /path` | Push a specific directory |
| `pocket-engineer qr` | Show QR code for the phone app |

## Multi-server

| Command | Description |
|---|---|
| `pocket-engineer servers` | List all configured servers |
| `pocket-engineer switch <name>` | Switch active server |
| `pocket-engineer --server <name> <cmd>` | Run any command against a specific server |

## Other

| Command | Description |
|---|---|
| `pocket-engineer logs` | Show EC2 provisioning/setup log |
| `pocket-engineer help` | Show help |
| `pocket-engineer version` | Show version |

## Global flag

`--server <name>` works with any command:

```bash
pocket-engineer --server work status
pocket-engineer --server personal sync
pocket-engineer --server work "deploy to production"
```
