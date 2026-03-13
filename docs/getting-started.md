# Getting Started

Set up Pocket Eng in under 5 minutes. You'll have Claude Code running on your own EC2, accessible from your laptop and phone.

## What you need

- A Mac or Linux terminal
- An AWS account
- An [Anthropic API key](https://console.anthropic.com)
- [AWS CLI](https://aws.amazon.com/cli/) installed (`brew install awscli`)

## Install

```bash
curl -fsSL https://pocketeng.co/install | sh
```

## Provision your server

```bash
pocketeng init
```

The wizard asks for three things:

1. **AWS credentials** — access key + secret key + region
2. **Anthropic API key** — your `sk-ant-...` key
3. **Toolchain** — pick what you want installed (GitHub CLI, Vercel, Docker, etc.)

It then launches a `t3.medium` EC2 with everything pre-installed. Takes about 2 minutes.

When it's done, you'll see a QR code. That's for the phone app.

## Start coding

```bash
pocketeng
```

This opens Claude Code inside a tmux session on your EC2. You can close your laptop — the session keeps running.

To come back later:

```bash
pocketeng attach
```

## Connect your phone

1. Open the **Pocket Eng** iOS app
2. Tap **Add Server**
3. Scan the QR code from your terminal (run `pocketeng qr` to show it again)

That's it. Your phone is connected to the same EC2. You can start sessions, send prompts, and see Claude work — all from your phone.

## Already have an EC2?

Skip provisioning and connect to your existing server:

```bash
pocketeng setup
```

Enter your host, SSH key path, and user. Pocket Eng doesn't install anything on your server — it just needs SSH access and Claude Code already installed.
