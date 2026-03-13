# Commands

## Setup

| Command | Description |
|---|---|
| `pocketeng init` | Provision a new EC2 with Claude Code and your tools |
| `pocketeng setup` | Connect to an existing EC2 |
| `pocketeng setup --name work` | Connect and save as a named profile |

## Sessions

| Command | Description |
|---|---|
| `pocketeng` | Start an interactive Claude Code session |
| `pocketeng "do something"` | Send a one-shot prompt |
| `pocketeng attach` | Reattach to a running session |
| `pocketeng resume <id>` | Resume a past session by ID |
| `pocketeng list` | List recent sessions |
| `pocketeng status` | Check if Claude is running |

## Sync & Phone

| Command | Description |
|---|---|
| `pocketeng sync` | Push current directory to EC2 with handoff doc |
| `pocketeng sync /path` | Push a specific directory |
| `pocketeng qr` | Show QR code for the phone app |

## Multi-server

| Command | Description |
|---|---|
| `pocketeng servers` | List all configured servers |
| `pocketeng switch <name>` | Switch active server |
| `pocketeng --server <name> <cmd>` | Run any command against a specific server |

## Other

| Command | Description |
|---|---|
| `pocketeng logs` | Show EC2 provisioning/setup log |
| `pocketeng help` | Show help |
| `pocketeng version` | Show version |

## Global flag

`--server <name>` works with any command:

```bash
pocketeng --server work status
pocketeng --server personal sync
pocketeng --server work "deploy to production"
```
