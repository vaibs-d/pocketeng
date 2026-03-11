<p align="center">
  <br />
  <code>&nbsp;pocket-engineer&nbsp;</code>
  <br />
  <br />
  <strong>Claude Code on your cloud, from anywhere.</strong>
  <br />
  Sessions survive disconnects — close your laptop, pick up on your phone.
  <br />
  <br />
  <a href="#install">Install</a> &nbsp;&bull;&nbsp;
  <a href="#quick-start">Quick Start</a> &nbsp;&bull;&nbsp;
  <a href="#commands">Commands</a> &nbsp;&bull;&nbsp;
  <a href="#how-it-works">How It Works</a> &nbsp;&bull;&nbsp;
  <a href="#companion-app">iOS App</a>
  <br />
  <br />
</p>

---

```
 You                              Your EC2
┌──────────┐    SSH + tmux    ┌──────────────────┐
│  Laptop  │ ───────────────► │  Claude Code     │
│ terminal │                  │   (persistent)   │
└──────────┘                  │                  │
                              │  ~/projects/     │
┌──────────┐    SSH + tmux    │   your-app/      │
│  Phone   │ ───────────────► │   another-app/   │
│  app     │                  │                  │
└──────────┘                  └──────────────────┘
```

**No relay servers. No intermediaries. Direct SSH to your EC2.**
You own the machine, the keys, and the code.

---

## Install

```bash
brew tap vaibs-d/pocketengineer https://github.com/vaibs-d/pocketengineer
brew install pocket-engineer
```

<details>
<summary>Manual install (no Homebrew)</summary>

```bash
curl -fsSL https://raw.githubusercontent.com/vaibs-d/pocketengineer/main/pocket-engineer \
  -o /usr/local/bin/pocket-engineer && chmod +x /usr/local/bin/pocket-engineer
```

</details>

## Quick Start

```bash
pocket-engineer init
```

That's it. The wizard walks you through everything:

1. **AWS credentials** — we spin up a `t3.medium` EC2 in your account
2. **Anthropic API key** — powers Claude Code on the server
3. **Your toolchain** — pick from GitHub CLI, Vercel, Supabase, Docker, AWS CLI
4. **Done** — SSH key, security group, and Claude Code are set up automatically

At the end you get a QR code. Scan it with the **Pocket Eng** iOS app to steer Claude from your phone.

```bash
# Start coding
pocket-engineer
```

## Commands

### Daily use

| Command | What it does |
|---|---|
| `pocket-engineer` | Interactive Claude Code session |
| `pocket-engineer "build a REST API"` | One-shot prompt |
| `pocket-engineer sync` | Push your local project to EC2 (with handoff notes for the phone session) |
| `pocket-engineer attach` | Reattach after a disconnect |
| `pocket-engineer resume <id>` | Resume a previous session |
| `pocket-engineer list` | List recent sessions |
| `pocket-engineer status` | Check if Claude is running |
| `pocket-engineer qr` | Show QR code for the phone app |

### Multi-server

Manage multiple EC2 instances — sync project A to `work`, project B to `personal`.

```bash
pocket-engineer servers                  # List all servers
pocket-engineer setup --name work        # Add a new server
pocket-engineer switch work              # Switch active server
pocket-engineer sync --server personal   # Sync to a specific server
```

The `--server <name>` flag works with any command.

## How It Works

1. `pocket-engineer init` provisions an EC2 with Claude Code, Node, Python, Git, tmux, and your tools
2. The CLI opens an SSH tunnel and runs Claude Code inside a **tmux** session
3. tmux keeps the process alive — even when you close the terminal or lose Wi-Fi
4. `pocket-engineer sync` pushes your local project + a handoff document to EC2
5. Open the **Pocket Eng** iOS app, scan QR, and continue on your phone

Sessions are just SSH connections to tmux. Nothing magical, nothing proprietary.

## Configuration

Set these if you're connecting to an existing server (or use `pocket-engineer setup`):

| Variable | Description | Default |
|---|---|---|
| `POCKET_ENGINEER_HOST` | EC2 IP or hostname | *(required)* |
| `POCKET_ENGINEER_USER` | SSH user | `ec2-user` |
| `POCKET_ENGINEER_KEY` | Path to SSH private key | `~/.ssh/pocket-engineer.pem` |
| `POCKET_ENGINEER_DIR` | Remote working directory | `~/projects` |

Config is stored in `~/.pocket-engineer/servers/<name>.conf`.

## MCP Server

Use Pocket Eng from inside Claude Code itself. The MCP server exposes tools to sync code and manage sessions without leaving your conversation.

```bash
cd mcp-server && npm install
```

Add to your Claude Code MCP config:

```json
{
  "mcpServers": {
    "pocket-engineer": {
      "command": "node",
      "args": ["/path/to/mcp-server/index.js"]
    }
  }
}
```

**Tools available:**

| Tool | Description |
|---|---|
| `pe_sync` | Sync project to EC2 with optional handoff notes |
| `pe_status` | Check server connectivity and running sessions |
| `pe_list_sessions` | List Claude Code sessions on the server |
| `pe_run_remote` | Run a command on the EC2 via SSH |
| `pe_servers` | List all configured server profiles |

All tools accept an optional `server` parameter to target a specific profile.

## Companion App

The **Pocket Eng** iOS app connects to your EC2 via QR code and gives you a mobile interface to run Claude Code sessions from your phone. Real SSH streaming, real terminal output — not a web wrapper.

## Requirements

- macOS or Linux terminal
- AWS account (for EC2 provisioning)
- [AWS CLI](https://aws.amazon.com/cli/) installed
- [Anthropic API key](https://console.anthropic.com)

## License

MIT
