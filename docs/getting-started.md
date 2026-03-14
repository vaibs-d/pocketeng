# Getting Started

Set up Pocket Eng in under 5 minutes — no AWS knowledge required.

## What you need

- An iPhone with the **Pocket Eng** app installed
- A Mac or Linux terminal
- An [Anthropic API key](https://console.anthropic.com) *(the app will ask for this)*
- An AWS account *(the app will handle credentials)*

## Install the CLI

```bash
brew install vaibs-d/pocketengineer/pocketeng
```

Or with curl:

```bash
curl -fsSL https://pocketeng.co/install | sh
```

## Run it

```bash
pocketeng
```

A QR code appears in your terminal. That's it — the app takes it from here.

1. Open the **Pocket Eng** app
2. Tap **Connect Mac** and scan the QR code
3. The app detects your Mac and asks: **"Spin up your EC2?"**
4. Tap yes — EC2 provisions, Claude Code installs, ~2 minutes

When it's done, your session is live on both your laptop and phone.

## Start coding

On your laptop:

```bash
pocketeng
```

On your phone: just open the app — the session is already running.

Close your laptop anytime. The session keeps going on EC2. Come back with:

```bash
pocketeng attach
```

## No phone? Use the manual wizard

If you prefer to set up without the app:

```bash
pocketeng init --manual
```

This walks you through AWS credentials, Anthropic API key, and toolchain selection.

## Already have an EC2?

Connect to your existing server instead of provisioning a new one:

```bash
pocketeng setup
```

Enter your host, SSH key path, and user.
