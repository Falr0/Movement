# Reference and verification notes

The code is an original implementation of movement math, informed by public descriptions and observable equations. The reference projects below have their own licenses; their source is not incorporated into this repository.

- [Valve's public Source SDK movement implementation](https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/gamemovement.cpp): projected acceleration, ground friction, air wish-speed limiting, gravity integration, plane clipping, stepping and ground classification. SDK 2013 is not the complete Counter-Strike: Source movement implementation.
- [Valve's public movement variables](https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/movevars_shared.cpp): Source movement variable definitions; game-specific overrides must be checked separately.
- [Momentum Mod movement implementation](https://github.com/momentum-mod/game/blob/develop/mp/src/game/shared/momentum/mom_gamemovement.cpp): a separate movement-oriented project, useful for comparison. Its game modes contain intentional changes; it is not proof of default CS:S behavior.
- [Roblox WorldRoot](https://create.roblox.com/docs/reference/engine/classes/WorldRoot): Blockcast returns swept distance and a hit normal but does not detect shapes already overlapping at the cast origin.

## Candidate CS:S profile

The initial target uses acceleration 5, air acceleration 10, friction 4, stop speed 75, gravity 800, a 30-unit air wish cap, a 250-unit default run speed, and 15 ms simulation ticks. Weapon speeds are supplied by the caller.

Legacy stamina timing and the 1.2x bunnyhop speed limit are provisional. They have not been verified against a recording from a named stock CS:S build. Frame-rate consistency tests establish the behavior of this implementation, not equivalence to every Source server.

## Regression evidence

Initial run: Luau 0.742, October 14, 2026, 18 checks passed. Checks include ground acceleration, friction, counter-strafe braking, independent perpendicular air velocity, walking/crouching speeds, approximately 57-unit jump height, manual jump edge handling, landing, diagonal input normalization, crouch clearance, and fixed-step consistency at 30, 60, 144 and 240 render FPS.

Roblox scene playtesting, networking and an original-game comparison are still required.
