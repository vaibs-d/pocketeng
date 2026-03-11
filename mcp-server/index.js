#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { execSync, spawn } from "child_process";
import { readFileSync, existsSync, readdirSync, copyFileSync, mkdirSync, writeFileSync } from "fs";
import { homedir } from "os";
import { join, basename } from "path";

// ─── Config ──────────────────────────────────────────────────────────────────

const CONFIG_DIR = join(homedir(), ".pocket-engineer");
const SERVERS_DIR = join(CONFIG_DIR, "servers");
const ACTIVE_FILE = join(CONFIG_DIR, "active");
const LEGACY_CONFIG = join(CONFIG_DIR, "config");

/** Migrate old single-server config to multi-server layout */
function migrateConfig() {
  if (existsSync(LEGACY_CONFIG) && !existsSync(SERVERS_DIR)) {
    mkdirSync(SERVERS_DIR, { recursive: true });
    copyFileSync(LEGACY_CONFIG, join(SERVERS_DIR, "default.conf"));
    writeFileSync(ACTIVE_FILE, "default");
  }
}

/** Get the active profile name */
function activeProfile() {
  if (existsSync(ACTIVE_FILE)) {
    return readFileSync(ACTIVE_FILE, "utf-8").trim();
  }
  return "default";
}

/** Parse a .conf file into a config object */
function parseConfFile(filePath) {
  if (!existsSync(filePath)) return null;
  const content = readFileSync(filePath, "utf-8");
  const vars = {};
  for (const line of content.split("\n")) {
    const match = line.match(/^(\w+)="(.+)"$/);
    if (match) vars[match[1]] = match[2];
  }
  return {
    host: vars.PE_HOST,
    user: vars.PE_USER || "ec2-user",
    key: vars.PE_KEY,
    dir: vars.PE_DIR || "~/projects",
  };
}

/**
 * Load config for a specific profile, or the active profile.
 * Falls back to legacy ~/.pocket-engineer/config for backward compat.
 */
function loadConfig(profileName) {
  migrateConfig();
  const profile = profileName || activeProfile();
  const profileFile = join(SERVERS_DIR, `${profile}.conf`);

  // Try profile-specific config first
  if (existsSync(profileFile)) {
    return parseConfFile(profileFile);
  }
  // Fall back to legacy config
  if (existsSync(LEGACY_CONFIG)) {
    return parseConfFile(LEGACY_CONFIG);
  }
  return null;
}

/** List all server profiles with their hosts */
function listProfiles() {
  migrateConfig();
  const profiles = [];
  if (!existsSync(SERVERS_DIR)) return profiles;

  const files = readdirSync(SERVERS_DIR).filter((f) => f.endsWith(".conf"));
  const current = activeProfile();

  for (const file of files) {
    const name = file.replace(/\.conf$/, "");
    const config = parseConfFile(join(SERVERS_DIR, file));
    profiles.push({
      name,
      host: config?.host || "unknown",
      active: name === current,
    });
  }
  return profiles;
}

function sshArgs(config) {
  return [
    "-i", config.key,
    "-o", "StrictHostKeyChecking=no",
    "-o", "ConnectTimeout=10",
    "-o", "BatchMode=yes",
  ];
}

function runSSH(config, command, timeoutMs = 30000) {
  return new Promise((resolve, reject) => {
    const args = [...sshArgs(config), `${config.user}@${config.host}`, command];
    const proc = spawn("ssh", args, { stdio: ["ignore", "pipe", "pipe"] });
    let stdout = "";
    let stderr = "";
    const timer = setTimeout(() => {
      proc.kill();
      reject(new Error("SSH command timed out"));
    }, timeoutMs);

    proc.stdout.on("data", (d) => (stdout += d.toString()));
    proc.stderr.on("data", (d) => (stderr += d.toString()));
    proc.on("close", (code) => {
      clearTimeout(timer);
      resolve({ stdout: stdout.trim(), stderr: stderr.trim(), code });
    });
    proc.on("error", (err) => {
      clearTimeout(timer);
      reject(err);
    });
  });
}

function runLocal(command, timeoutMs = 120000) {
  return new Promise((resolve, reject) => {
    const proc = spawn("bash", ["-c", command], {
      stdio: ["ignore", "pipe", "pipe"],
    });
    let stdout = "";
    let stderr = "";
    const timer = setTimeout(() => {
      proc.kill();
      reject(new Error("Command timed out"));
    }, timeoutMs);

    proc.stdout.on("data", (d) => (stdout += d.toString()));
    proc.stderr.on("data", (d) => (stderr += d.toString()));
    proc.on("close", (code) => {
      clearTimeout(timer);
      resolve({ stdout: stdout.trim(), stderr: stderr.trim(), code });
    });
    proc.on("error", (err) => {
      clearTimeout(timer);
      reject(err);
    });
  });
}

// ─── MCP Server ──────────────────────────────────────────────────────────────

const server = new Server(
  { name: "pocket-engineer", version: "1.2.0" },
  { capabilities: { tools: {} } }
);

const SERVER_PARAM = {
  type: "string",
  description:
    "Server profile name (e.g. 'work', 'personal'). Defaults to the active profile. Use pe_servers to list available profiles.",
};

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "pe_sync",
      description:
        "Sync the current project directory to the EC2 server via rsync. This pushes your local code to the remote server so it can be accessed from the Pocket Eng phone app. Optionally generates a handoff document from the current Claude session.",
      inputSchema: {
        type: "object",
        properties: {
          project_dir: {
            type: "string",
            description:
              "Absolute path to the project directory to sync. Defaults to current working directory.",
          },
          notes: {
            type: "string",
            description:
              "Optional handoff notes to include in .handoff.md on the remote server. Describe current state, pending tasks, and key context for the phone session.",
          },
          server: SERVER_PARAM,
        },
      },
    },
    {
      name: "pe_list_sessions",
      description:
        "List Claude Code sessions running on the EC2 server. Shows session IDs, project names, and timestamps.",
      inputSchema: {
        type: "object",
        properties: {
          server: SERVER_PARAM,
        },
      },
    },
    {
      name: "pe_status",
      description:
        "Check if a tmux session with Claude Code is currently running on the EC2 server, and verify SSH connectivity.",
      inputSchema: {
        type: "object",
        properties: {
          server: SERVER_PARAM,
        },
      },
    },
    {
      name: "pe_run_remote",
      description:
        "Run a shell command on the EC2 server via SSH. Useful for checking files, installing packages, or inspecting the remote environment.",
      inputSchema: {
        type: "object",
        properties: {
          command: {
            type: "string",
            description: "The shell command to execute on the remote server.",
          },
          server: SERVER_PARAM,
        },
        required: ["command"],
      },
    },
    {
      name: "pe_servers",
      description:
        "List all configured server profiles and which one is currently active. Use this to see available servers before syncing or running commands.",
      inputSchema: {
        type: "object",
        properties: {},
      },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  // pe_servers doesn't need a config
  if (name === "pe_servers") {
    return handleServers();
  }

  // All other tools: load config (optionally from a specific profile)
  const config = loadConfig(args?.server);

  if (!config || !config.host) {
    const profileMsg = args?.server
      ? `Server profile '${args.server}' not found or not configured.`
      : "Pocket Eng not configured. Run `pocket-engineer init` or `pocket-engineer setup` first.";
    return {
      content: [{ type: "text", text: profileMsg }],
      isError: true,
    };
  }

  try {
    switch (name) {
      case "pe_sync":
        return await handleSync(config, args);
      case "pe_list_sessions":
        return await handleListSessions(config);
      case "pe_status":
        return await handleStatus(config);
      case "pe_run_remote":
        return await handleRunRemote(config, args);
      default:
        return {
          content: [{ type: "text", text: `Unknown tool: ${name}` }],
          isError: true,
        };
    }
  } catch (err) {
    return {
      content: [{ type: "text", text: `Error: ${err.message}` }],
      isError: true,
    };
  }
});

// ─── Tool Handlers ───────────────────────────────────────────────────────────

function handleServers() {
  const profiles = listProfiles();
  if (profiles.length === 0) {
    return {
      content: [
        {
          type: "text",
          text: "No servers configured. Run `pocket-engineer init` or `pocket-engineer setup` first.",
        },
      ],
    };
  }

  const lines = [`${profiles.length} server(s) configured:`, ""];
  for (const p of profiles) {
    const marker = p.active ? "●" : " ";
    const tag = p.active ? " (active)" : "";
    lines.push(`  ${marker} ${p.name.padEnd(16)} ${p.host}${tag}`);
  }
  lines.push("");
  lines.push(
    'Use the "server" parameter on pe_sync, pe_status, etc. to target a specific server.'
  );

  return { content: [{ type: "text", text: lines.join("\n") }] };
}

async function handleSync(config, args) {
  const projectDir = args?.project_dir || process.cwd();
  const projectName = basename(projectDir);
  const remoteProject = `${config.dir}/${projectName}`;

  const lines = [];
  lines.push(`Syncing ${projectDir} -> ${config.host}:${remoteProject}`);

  // Create remote dir (escape single quotes in path)
  const safeRemoteProject = remoteProject.replace(/'/g, "'\\''");
  await runSSH(config, `mkdir -p '${safeRemoteProject}'`);

  // Write handoff notes if provided
  if (args?.notes) {
    const { writeFileSync } = await import("fs");
    const handoffPath = join(projectDir, ".handoff.md");
    writeFileSync(handoffPath, args.notes);
    lines.push("Wrote .handoff.md with handoff notes");
  }

  // Rsync
  const excludes = [
    ".git", "node_modules", ".build", "DerivedData", "*.xcodeproj",
    ".DS_Store", "Pods", "build", "dist", ".next", "__pycache__",
    "*.pyc", "venv", ".venv", "env", ".env", "*.egg-info", ".tox",
    ".pytest_cache", "target", ".gradle", "*.o", "*.so", "*.dylib", ".claude",
  ];
  const excludeArgs = excludes.map((e) => `--exclude '${e}'`).join(" ");
  // Shell-escape paths to handle spaces and special characters
  const safeProjectDir = projectDir.replace(/'/g, "'\\''");
  const safeKey = config.key.replace(/'/g, "'\\''");
  const rsyncCmd = `rsync -azq --delete ${excludeArgs} --max-size='50m' -e "ssh -i '${safeKey}' -o StrictHostKeyChecking=no" '${safeProjectDir}/' '${config.user}@${config.host}:${safeRemoteProject}/'`;

  const result = await runLocal(rsyncCmd, 120000);
  if (result.code !== 0) {
    lines.push(`rsync warning (exit ${result.code}): ${result.stderr || "some files may have been skipped"}`);
  }

  lines.push("Sync complete!");
  lines.push("");
  lines.push(`Remote path: ${remoteProject}`);
  lines.push("Open Pocket Eng app on phone to start a session on this project.");

  return { content: [{ type: "text", text: lines.join("\n") }] };
}

async function handleListSessions(config) {
  const cmd = `find ~/.claude/projects -name '*.jsonl' ! -name 'agent-*' -printf '%T@ %p\\n' 2>/dev/null; exit 0`;
  const result = await runSSH(config, cmd);

  if (!result.stdout) {
    return {
      content: [{ type: "text", text: "No sessions found on the server." }],
    };
  }

  const lines = result.stdout.split("\n").filter(Boolean);
  const sessions = lines
    .map((line) => {
      const spaceIdx = line.indexOf(" ");
      const epochStr = line.substring(0, spaceIdx);
      const filePath = line.substring(spaceIdx + 1);
      const sid = basename(filePath, ".jsonl");
      const projectDir = basename(filePath.replace(`/${basename(filePath)}`, ""));

      // Make project name readable
      const parts = projectDir.split("-projects");
      let displayName;
      if (parts.length > 1) {
        const suffix = (parts[parts.length - 1] || "").replace(/^-/, "").replace(/-/g, " ");
        displayName = suffix || "Default";
      } else {
        displayName = projectDir;
      }

      const epoch = parseFloat(epochStr);
      const date = new Date(epoch * 1000);
      const ago = timeAgo(date);

      return { sid, displayName, date, ago };
    })
    .sort((a, b) => b.date - a.date);

  const output = [`Found ${sessions.length} session(s) on ${config.host}:`, ""];
  for (const s of sessions) {
    output.push(`  ${s.sid.substring(0, 8)}...  ${s.displayName.padEnd(20)}  ${s.ago}`);
  }

  return { content: [{ type: "text", text: output.join("\n") }] };
}

async function handleStatus(config) {
  const lines = [];

  // Test SSH
  const sshResult = await runSSH(config, "echo ok");
  if (sshResult.stdout !== "ok") {
    return {
      content: [
        {
          type: "text",
          text: `Cannot connect to ${config.host}. SSH connection failed.\n${sshResult.stderr}`,
        },
      ],
      isError: true,
    };
  }
  lines.push(`Connected to ${config.host}`);

  // Check tmux (CLI sessions)
  const tmuxResult = await runSSH(
    config,
    "tmux has-session -t pocket-engineer 2>/dev/null && echo RUNNING || echo STOPPED"
  );
  if (tmuxResult.stdout === "RUNNING") {
    lines.push("CLI session: RUNNING (tmux)");
  } else {
    lines.push("CLI session: not running");
  }

  // Check nohup processes (phone app sessions)
  const bgResult = await runSSH(
    config,
    "ls /tmp/pe-pid-*.* 2>/dev/null | while read f; do PID=$(cat \"$f\" 2>/dev/null); [ -n \"$PID\" ] && kill -0 $PID 2>/dev/null && echo ALIVE; done | wc -l; exit 0"
  );
  const bgCount = parseInt(bgResult.stdout.trim()) || 0;
  if (bgCount > 0) {
    lines.push(`Phone app tasks: ${bgCount} running`);
  }

  // Check disk
  const diskResult = await runSSH(config, "df -h / | tail -1 | awk '{print $4}'");
  if (diskResult.stdout) {
    lines.push(`Disk free: ${diskResult.stdout}`);
  }

  // Count sessions
  const countResult = await runSSH(
    config,
    "find ~/.claude/projects -name '*.jsonl' ! -name 'agent-*' 2>/dev/null | wc -l; exit 0"
  );
  lines.push(`Sessions on server: ${countResult.stdout.trim() || "0"}`);

  return { content: [{ type: "text", text: lines.join("\n") }] };
}

async function handleRunRemote(config, args) {
  if (!args?.command) {
    return {
      content: [{ type: "text", text: "No command provided." }],
      isError: true,
    };
  }

  const result = await runSSH(config, args.command, 60000);
  const output = [];
  if (result.stdout) output.push(result.stdout);
  if (result.stderr) output.push(`stderr: ${result.stderr}`);
  if (!result.stdout && !result.stderr)
    output.push(`(no output, exit code ${result.code})`);

  return { content: [{ type: "text", text: output.join("\n") }] };
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function timeAgo(date) {
  const seconds = Math.floor((Date.now() - date.getTime()) / 1000);
  if (seconds < 60) return "just now";
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
  return `${Math.floor(seconds / 86400)}d ago`;
}

// ─── Start ───────────────────────────────────────────────────────────────────

const transport = new StdioServerTransport();
await server.connect(transport);
