# teleportation

A Luanti mod with random teleport and teleport requests.

## Commands

| Command | What it does |
| --- | --- |
| `/rtp` | Teleport to a random safe spot. |
| `/tpr <player>` | Ask to teleport to a player. They get an Accept / Deny window (or use `/tpaccept`, `/tpdeny`). The request is cancelled after 30 seconds. |
| `/tpaccept [player]` | Accept a request (the newest one if no player is named). |
| `/tpdeny [player]` | Deny a request (the newest one if no player is named). |
| `/tpcancel [player]` | Cancel your own request (to one player, or all). |
| `/tpblock <player>` | Automatically deny requests from a player. |
| `/tpunblock <player>` | Allow a player's requests again. |
| `/tpblockall [on\|off]` | Block all requests (no argument toggles). |
| `/tpblocklist` | Show who you block. |

Blocked requesters are told "`<name>` isn't accepting teleport requests";
the target isn't notified. Blocking someone (or everyone) also drops requests
that are already waiting. Blocks are saved per player and survive restarts.
Requests are cancelled when either player leaves.

No privileges are needed.

## /rtp

A random x and z within the range around the starting position are loaded, then
a random spot in the y range that can be stood on is picked: a solid floor, two
free nodes above it, no liquid and nothing that hurts. It tries a number of
columns before giving up.

### Skyblock: Zero

The world there is void, so random columns almost never have ground. When
`sbz_api.planets` exists, `/rtp` picks a planet that touches the box (made
`teleportation.sbz_range_factor` times larger, 1.5 by default) and teleports to
the highest safe spot on a random point of its surface. If no planet touches the
box, the plain search runs.

The planets are in x and z 0 to 31000 and y 2000 to 20000, so set the starting
position and ranges to cover them, for example:

```
teleportation.rtp_origin = 15000, 10000, 15000
teleportation.rtp_range_x = 15000
teleportation.rtp_range_y = 9000
teleportation.rtp_range_z = 15000
```

## Settings

| Setting | Default | |
| --- | --- | --- |
| `teleportation.rtp_origin` | `0, 0, 0` | Centre of the area `/rtp` picks from. |
| `teleportation.rtp_range_x` | 1000 | How far from the centre, per axis (both directions). |
| `teleportation.rtp_range_y` | 150 | |
| `teleportation.rtp_range_z` | 1000 | |
| `teleportation.rtp_attempts` | 10 | Random columns tried before giving up. |
| `teleportation.request_timeout` | 30 | Seconds a `/tpr` request waits. |
| `teleportation.sbz_planets` | true | Skyblock: Zero planet search. |
| `teleportation.sbz_range_factor` | 1.5 | Ranges are multiplied by this when looking for planets. |

## License

MIT
