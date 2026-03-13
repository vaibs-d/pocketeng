# Multiple Servers

Run different projects on different EC2 instances. Your work stuff on one server, side projects on another.

## Add a server

```bash
pocketeng setup --name work
```

Or when provisioning a new one:

```bash
pocketeng init
# Step 4 asks for a server name
```

## See your servers

```bash
pocketeng servers
```

```
● default         100.23.127.155  (active)
  work            54.12.88.201
```

The `●` shows which server all commands currently target.

## Switch servers

```bash
pocketeng switch work
```

Now every command — `status`, `sync`, `qr`, etc. — goes to the `work` server until you switch again.

## One-off override

Use `--server` on any command to target a specific server without switching:

```bash
pocketeng sync --server work
pocketeng status --server default
```

## How it's stored

Config lives in `~/.pocketeng/servers/`:

```
~/.pocketeng/
  active              # name of the current server
  servers/
    default.conf      # host, user, key, dir
    work.conf
```

If you're upgrading from an older version, your existing config is automatically migrated.
