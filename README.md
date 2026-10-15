# After Echo Source Movement

Experimental Source-style player movement for Roblox, written in Luau. Extracted from work on **After Echo**, a ninja/samurai tactical shooter.

The current target is default Counter-Strike: Source movement. This is an independent implementation, not Valve code, an official Valve project, or a verified 1:1 port.

## Included

- Fixed 15 ms simulation ticks with a render-independent accumulator.
- Ground acceleration, friction and counter-strafing.
- Projection-limited air acceleration, including the 30-unit wish-direction cap.
- Split gravity integration, manual jumping and a configurable movement profile.
- Standing/crouching hulls, clearance checks, slope classification, slide clipping and step attempts.
- A Roblox Blockcast collision adapter.
- Deterministic regression checks that run in Roblox Studio or the official Luau CLI.

No game maps, character meshes, weapon assets, private game scripts, credentials, or purchased content are included.

## Status

**Early development.** Eighteen numerical regression checks passed with Luau 0.742 on October 14, 2026. These check the implementation's equations and invariants, not recordings from the original CS:S executable.

The numerical core loads in Roblox Studio. Live movement integration and collision tests have not yet been completed. In particular, the CSS-specific stamina rules and bunnyhop limit are candidate settings and require validation against a specified game build. Do not present the package as a completed 1:1 recreation.

## Install in Roblox Studio

Create a folder named `AfterechoMovement` in ReplicatedStorage, then add these sibling ModuleScripts using the files in `src/`:

```
ReplicatedStorage
  AfterechoMovement
    AfterechoSourceConfig
    AfterechoSourceMovement
    AfterechoSourceWorld
```

The core accepts positions and velocities in studs. Its settings use Hammer units with the existing After Echo scale of **0.08 studs per unit**. Choose a consistent scale for the map, avatar, and collision hull.

```lua
local package = game.ReplicatedStorage.AfterechoMovement
local Movement = require(package.AfterechoSourceMovement)
local World = require(package.AfterechoSourceWorld)

local collision = World.new(character)
local state = Movement.new(initialFeetPosition)

-- Call from your simulation callback. Read input and camera yaw in your controller.
Movement.advance(state, elapsed, {
    direction = worldSpaceHorizontalDirection,
    amount = normalizedInputMagnitude,
    maxSpeed = 250, -- Hammer units/second; select from the equipped weapon
    walk = walkHeld,
    duck = crouchHeld,
    jump = jumpHeld,
    blocked = false,
}, collision)

-- state.position is the feet position; state.velocity is simulation velocity.
-- Your controller applies the result to its avatar and presentation systems.
-- When the character is removed:
collision.destroy()
```

This is a movement library, not a complete networked character controller. The caller must manage input, avatar ownership, applying transforms, disabling competing Humanoid acceleration, gravity ownership, camera presentation, respawns, server validation and other players. Avoid integrating the simulated velocity a second time through Roblox's physics motor.

## Run tests

Install Python 3 and download the official [Luau CLI](https://github.com/luau-lang/luau/releases). From this repository:

```sh
python tools/run_tests.py --luau /path/to/luau
```

On Windows, pass the path to `luau.exe`. The test runner uses a minimal Vector3 test double; it does not emulate Roblox networking, terrain, or mesh collision.

In Roblox Studio, create a ModuleScript from `tests/AfterechoMovementTests.luau` and run:

```lua
local movement = require(game.ReplicatedStorage.AfterechoMovement.AfterechoSourceMovement)
local report = require(pathToTestModule)(movement)
print(report.passed, report.failed)
```

## Limits and next work

- Compare tick-by-tick input and velocity recordings with a named CS:S version and server configuration.
- Verify stairs, slopes, crouch tunnels, corners and initial overlaps against Roblox geometry.
- Add moving-platform base velocity, water movement and full Source ladder behavior. After Echo's existing rope ladders are outside this package.
- Test multiplayer replication and implement server-side validation before competitive deployment.
- Reconcile differences between Source collision traces and Roblox Blockcast/overlap queries.

See [reference notes](docs/REFERENCES.md) and [contributing](CONTRIBUTING.md).

## License

MIT for the original files in this repository; see [LICENSE](LICENSE). No Valve source or assets are distributed here. Counter-Strike and Source names identify the compatibility target.
