# rd-coordsmanager
**RoxDev Development Store**

A simple but useful resource for FiveM developers and server owners. Lets you capture, save, and manage world coordinates directly in-game through a clean UI — no more copy-pasting from F8 or writing coords down manually.

Compatible with QB-Core, ESX, and Standalone.

---

## Features

- Capture your current X/Y/Z/Heading with one click
- Save coords with a custom name, linked to your Discord account
- Rename, delete, or update any saved coord
- Copy in multiple formats: vector4, vector3, table, raw
- Teleport directly to any saved coord from the menu
- Search through your saved coords instantly
- Open via command or a rebindable key

---

## Dependencies

- [oxmysql](https://github.com/overextended/oxmysql) — required for the database
- QB-Core or ESX - optional, works standalone too

---

## Installation

1. Drop `rd-coordsmanager` into your `resources` folder
2. Add `ensure oxmysql` and `ensure rd-coordsmanager` to your `server.cfg` — oxmysql must come first
3. Open `config.lua` and add your Discord ID to `Config.AllowedDiscords`
4. Start the server — the table is created automatically

If you prefer to create the table manually, the SQL file is in the `sql/` folder.

---

## Configuration

Everything is in `config.lua`. The important ones:

```lua
Config.AllowedDiscords = {
    'discord:YOUR_ID_HERE',
}
```

To find your Discord ID: Settings > Advanced > enable Developer Mode, then right-click your name and Copy ID. Add `discord:` in front of it.

```lua
Config.Framework         = 'auto'     -- auto | qb | esx | standalone
Config.Command           = 'coords'   -- or false to disable
Config.Keybind           = 'F7'       -- or false to disable
Config.MaxCoords         = 150
Config.DefaultCopyFormat = 'vector4'
Config.AllowTeleport     = true
```

---

## Copy Formats

| Key | Output |
|-----|--------|
| vector4 | `vector4(x, y, z, heading)` |
| vector3 | `vector3(x, y, z)` |
| table | `{ x = x, y = y, z = z, h = heading }` |
| raw | `x, y, z, heading` |

---

## Troubleshooting

**Menu doesn't open** — your Discord ID is not in `Config.AllowedDiscords`, or your server isn't sending Discord identifiers. Check your server.cfg for `set sv_endpoints` or similar identity settings.

**oxmysql error on start** — make sure `ensure oxmysql` is above `ensure rd-coordsmanager` in server.cfg, and that your MySQL connection string is set correctly.

**Coords not showing after save** — make sure the database is connected and the `rd_coords` table exists. Restart the resource once and check the server console for any errors.

---

*RoxDev — roxdev.tebex.io*