<p align="center">
  <br />
  <code>&nbsp;pocketeng&nbsp;</code>
  <br />
  <br />
  <strong>Claude Code on your cloud, from anywhere.</strong>
  <br />
  Sessions survive disconnects — close your laptop, pick up on your phone.
  <br />
  <br />
  <a href="docs/getting-started.md">Getting Started</a> &nbsp;&bull;&nbsp;
  <a href="docs/how-it-works.md">How It Works</a> &nbsp;&bull;&nbsp;
  <a href="docs/syncing.md">Syncing</a> &nbsp;&bull;&nbsp;
  <a href="docs/commands.md">Commands</a> &nbsp;&bull;&nbsp;
  <a href="docs/multi-server.md">Multi-server</a> &nbsp;&bull;&nbsp;
  <a href="docs/phone-app.md">Phone App</a> &nbsp;&bull;&nbsp;
  <a href="docs/mcp-server.md">MCP</a>
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
curl -fsSL https://pocketeng.co/install | sh
```

<details>
<summary>Other methods</summary>

**Homebrew:**
```bash
brew install vaibs-d/pocketengineer/pocketeng
```

**Manual:**
```bash
curl -fsSL https://raw.githubusercontent.com/vaibs-d/pocketengineer/main/pocketeng \
  -o /usr/local/bin/pocketeng && chmod +x /usr/local/bin/pocketeng
```

</details>

## Quick Start

```bash
pocketeng init
```

That's it. The wizard walks you through everything:

1. **AWS credentials** — we spin up a `t3.medium` EC2 in your account
2. **Anthropic API key** — powers Claude Code on the server
3. **Your toolchain** — pick from GitHub CLI, Vercel, Supabase, Docker, AWS CLI
4. **Done** — SSH key, security group, and Claude Code are set up automatically

At the end you get a QR code. Scan it with the **Pocket Eng** iOS app to steer Claude from your phone.

```bash
# Start coding
pocketeng
```

## Commands

### Daily use

| Command | What it does |
|---|---|
| `pocketeng` | Interactive Claude Code session |
| `pocketeng "build a REST API"` | One-shot prompt |
| `pocketeng sync` | Push your local project to EC2 (with handoff notes for the phone session) |
| `pocketeng attach` | Reattach after a disconnect |
| `pocketeng resume <id>` | Resume a previous session |
| `pocketeng list` | List recent sessions |
| `pocketeng status` | Check if Claude is running |
| `pocketeng qr` | Show QR code for the phone app |

### Multi-server

Manage multiple EC2 instances — sync project A to `work`, project B to `personal`.

```bash
pocketeng servers                  # List all servers
pocketeng setup --name work        # Add a new server
pocketeng switch work              # Switch active server
pocketeng sync --server personal   # Sync to a specific server
```

The `--server <name>` flag works with any command.

## How It Works

1. `pocketeng init` provisions an EC2 with Claude Code, Node, Python, Git, tmux, and your tools
2. The CLI opens an SSH tunnel and runs Claude Code inside a **tmux** session
3. tmux keeps the process alive — even when you close the terminal or lose Wi-Fi
4. `pocketeng sync` pushes your local project + a handoff document to EC2
5. Open the **Pocket Eng** iOS app, scan QR, and continue on your phone

Sessions are just SSH connections to tmux. Nothing magical, nothing proprietary.

## Configuration

Set these if you're connecting to an existing server (or use `pocketeng setup`):

| Variable | Description | Default |
|---|---|---|
| `PE_HOST` | EC2 IP or hostname | *(required)* |
| `PE_USER` | SSH user | `ec2-user` |
| `PE_KEY` | Path to SSH private key | `~/.ssh/pocketeng.pem` |
| `PE_DIR` | Remote working directory | `~/projects` |

Config is stored in `~/.pocketeng/servers/<name>.conf`.

## MCP Server

Use Pocket Eng from inside Claude Code itself. The MCP server exposes tools to sync code and manage sessions without leaving your conversation.

```bash
cd mcp-server && npm install
```

Add to your Claude Code MCP config:

```json
{
  "mcpServers": {
    "pocketeng": {
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
