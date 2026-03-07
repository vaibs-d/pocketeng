# ClaudeRemote - Setup Guide

## Prerequisites
- Xcode 15+ (macOS 14+)
- An EC2 instance with Claude Code pre-installed
- An SSH private key (Ed25519 or RSA) for the EC2 instance

## Option A: Open as Swift Package (Simplest)

1. Open Xcode
2. File > Open > navigate to `/Users/vaibhavdubey/dev/ClaudeRemote/`
3. Select `Package.swift`
4. Xcode will resolve dependencies automatically
5. Select an iOS Simulator or device as the target
6. Build & Run (Cmd+R)

**Note:** When opening as a package, set the scheme to "ClaudeRemote" and the run destination to an iOS simulator.

## Option B: Generate Xcode Project with XcodeGen

```bash
# Install XcodeGen
brew install xcodegen

# Generate project
cd /Users/vaibhavdubey/dev/ClaudeRemote
xcodegen generate

# Open the project
open ClaudeRemote.xcodeproj
```

## EC2 Instance Setup

Ensure your EC2 instance has:

1. **Claude Code installed:**
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```

2. **ANTHROPIC_API_KEY set:**
   ```bash
   echo 'export ANTHROPIC_API_KEY=your-key-here' >> ~/.bashrc
   ```

3. **SSH access configured** with your private key in `~/.ssh/authorized_keys`

## App Usage

1. **Connection Setup:** Tap the bolt icon > enter host, username, import your SSH private key
2. **Create Session:** Tap "+" > name your session (e.g., "Add dark mode to my app")
3. **Chat:** Type your task and send. Claude Code will work on the EC2 instance.
4. **Tool Activities:** Tap collapsible rows to see what Claude is doing (file reads, edits, commands)
5. **Resume:** Sessions persist. Close and reopen — tap a session to continue where you left off.

## Architecture

- SwiftUI + SwiftData + Citadel SSH
- MVVM with actor-based services
- Claude Code runs in headless mode (`claude -p` with `--output-format stream-json`)
- Multi-turn via `--resume <session_id>`
- Code edits auto-approved via `--dangerously-skip-permissions`
