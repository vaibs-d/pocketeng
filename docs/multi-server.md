# Multiple Servers

Run different projects on different EC2 instances. Your work stuff on one server, side projects on another.

## Add a server

```bash
pocket-engineer setup --name work
```

Or when provisioning a new one:

```bash
pocket-engineer init
# Step 4 asks for a server name
```

## See your servers

```bash
pocket-engineer servers
```

```
● default         100.23.127.155  (active)
  work            54.12.88.201
```

The `●` shows which server all commands currently target.

## Switch servers

```bash
pocket-engineer switch work
```

Now every command — `status`, `sync`, `qr`, etc. — goes to the `work` server until you switch again.

## One-off override

Use `--server` on any command to target a specific server without switching:

```bash
pocket-engineer sync --server work
pocket-engineer status --server default
```

## How it's stored

Config lives in `~/.pocket-engineer/servers/`:

```
~/.pocket-engineer/
  active              # name of the current server
  servers/
    default.conf      # host, user, key, dir
    work.conf
```

If you're upgrading from an older version, your existing config is automatically migrated to `servers/default.conf`.
