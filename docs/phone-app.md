# Phone App

The Pocket Eng iOS app lets you run Claude Code sessions on your EC2 from your phone. Real SSH, real terminal output — not a web view.

## Connect

1. Run `pocket-engineer qr` in your terminal
2. Open the Pocket Eng app
3. Tap **Add Server** → scan the QR code

The QR encodes your server's host and SSH key. One scan and you're connected.

## Start a session

1. Tap a server on the home screen
2. Tap **New Session**
3. Type what you want Claude to do
4. Tap **Launch**

Claude Code runs on the EC2 via SSH. You see streaming output in real time — text, tool calls, file edits, command output.

## How sessions work

- Each session runs as a background process on EC2 via `nohup`
- If you close the app or lose signal, the task keeps running
- Reopen the app and it reconnects to the running task automatically
- Previous sessions are saved — tap one to resume or view history

## Tips

- **Handoff from laptop:** Run `pocket-engineer sync` on your laptop, then open the project on your phone. Claude reads `.handoff.md` and picks up where you left off.
- **Multiple servers:** The app supports multiple server connections. Add as many as you need from the home screen.
- **Status indicators:** Green dot = connected. Pulsing = Claude is actively working.
