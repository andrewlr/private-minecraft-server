# Private Minecraft Server

A Dockerized Minecraft Java Edition server (Paper fork) configured for a private, family-friendly environment with strict content controls.

## Features

- **Paper server** with Aikar's JVM flags for stable tick performance
- **Whitelist-only** access with Mojang authentication (`online-mode=true`)
- **Peaceful mode** -- no hostile mobs, no PvP
- **Nether and End disabled** -- overworld-only gameplay
- **No magic** -- enchanting tables, brewing stands, and glass bottles are uncraftable via a bundled data pack
- **Automated daily backups** with 7-day retention via an `itzg/mc-backup` sidecar
- **Manual backup/restore scripts** for full volume archival and migration

## Quick Start

### 1. Configure environment

```bash
cp .env.example .env
# Edit .env and set a strong RCON_PASSWORD
```

### 2. Start the server

```bash
docker compose up -d
```

The Minecraft server will be available on port **25565**. First startup takes a few minutes while Paper downloads and the world generates.

### 3. Stop the server

```bash
docker compose down
```

## Player Management

All player management is done through RCON commands executed inside the running container.

### Add a player to the whitelist

```bash
docker exec mc-server rcon-cli whitelist add <username>
```

### Remove a player from the whitelist

```bash
docker exec mc-server rcon-cli whitelist remove <username>
```

### List whitelisted players

```bash
docker exec mc-server rcon-cli whitelist list
```

## Performance Monitoring

### TPS (Ticks Per Second)

Minecraft targets 20 TPS. Values below 20 indicate the server is struggling to keep up.

```bash
docker exec mc-server rcon-cli tps
```

This returns averages over the last 1, 5, and 15 minutes.

### MSPT (Milliseconds Per Tick)

MSPT measures how long each tick takes to process. Under 50ms is ideal (the server has a 50ms budget per tick to maintain 20 TPS).

```bash
docker exec mc-server rcon-cli mspt
```

## Backup and Restore

### Automated backups

The `backup` sidecar container automatically creates compressed backups every 24 hours into the `./backups/` directory and prunes backups older than 7 days. No action required.

### Manual volume backup

Archive the entire `mc-data` Docker volume to a timestamped `.tar.gz` file:

```bash
./scripts/volume-backup.sh           # saves to ./backups/
./scripts/volume-backup.sh /my/path  # saves to a custom directory
```

### Manual volume restore

Restore a previously created backup. This **deletes all current data** in the volume before restoring:

```bash
./scripts/volume-restore.sh ./backups/mc_volume_20260101_120000.tar.gz
```

You will be prompted to confirm before any data is deleted.

## Repository Structure

```
.
├── compose.yaml                 # Docker Compose: server + backup sidecar
├── .env.example                 # Template for required environment variables
├── config/
│   ├── bukkit.yml               # Disables The End dimension
│   └── datapacks/
│       └── disable_magic/       # Data pack removing magic-related recipes
│           ├── pack.mcmeta
│           └── data/minecraft/recipes/
│               ├── enchanting_table.json
│               ├── brewing_stand.json
│               └── glass_bottle.json
├── scripts/
│   ├── volume-backup.sh         # Archive mc-data volume to .tar.gz
│   └── volume-restore.sh        # Restore mc-data volume from .tar.gz
└── README.md
```

## Content Controls

| Control | Method |
|---|---|
| Nether disabled | `ALLOW_NETHER=false` in compose.yaml |
| End disabled | `allow-end: false` in config/bukkit.yml |
| Hostile mobs disabled | `DIFFICULTY=peaceful` + `SPAWN_MONSTERS=false` + `OVERRIDE_SERVER_PROPERTIES=true` in compose.yaml (see [note](#hostile-mob-controls)) |
| PvP disabled | `PVP=false` in compose.yaml |
| Enchanting disabled | Data pack removes enchanting_table recipe |
| Brewing disabled | Data pack removes brewing_stand and glass_bottle recipes |
| Authentication enforced | `ONLINE_MODE=true` in compose.yaml |
| Whitelist enforced | `ENABLE_WHITELIST=true` + `ENFORCE_WHITELIST=true` |

### Hostile mob controls

Three settings work together to reliably prevent all hostile mob spawning:

- **`DIFFICULTY=peaceful`** — Peaceful difficulty removes all hostile mobs regardless of their source, including those from mob spawner blocks in dungeons and mineshafts. `SPAWN_MONSTERS=false` alone does not prevent spawner-based mobs.
- **`SPAWN_MONSTERS=false`** — Disables natural hostile mob spawning as a fallback layer of protection.
- **`OVERRIDE_SERVER_PROPERTIES=true`** — Forces the itzg Docker image to regenerate `server.properties` from environment variables on every container start. Without this, Minecraft stores difficulty in the world's `level.dat` file, and changes to `DIFFICULTY` in compose.yaml may not take effect on existing worlds.
