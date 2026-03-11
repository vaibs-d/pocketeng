# MCP Server

Use Pocket Eng tools directly inside Claude Code conversations on your laptop. Sync code, check server status, and run remote commands without leaving your editor.

## Install

```bash
cd /path/to/pocketengineer/mcp-server
npm install
```

## Configure

Add to your Claude Code MCP config (`~/.claude/claude_desktop_config.json`):

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

Restart Claude Code. You'll now have these tools available in every conversation:

## Tools

### pe_sync

Sync your current project to EC2.

```
"Sync this project to my server with notes about the auth refactor"
```

Claude will rsync your files and write a `.handoff.md` with your notes.

### pe_status

Check server connectivity, running sessions, and disk space.

```
"Check if anything is running on my server"
```

### pe_list_sessions

List Claude Code sessions on the server with timestamps.

### pe_run_remote

Run any command on your EC2 via SSH.

```
"Run 'ls ~/projects' on the server"
```

### pe_servers

List all configured server profiles.

## Targeting a specific server

Every tool accepts an optional `server` parameter:

```
"Sync this project to my work server"
```

Claude will pass `server: "work"` to `pe_sync`. If you don't specify, it uses your active profile.
