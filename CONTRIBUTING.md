# Contributing

Start with a reproducible movement case: input sequence, fixed timestep, starting velocity, expected result and measured result. Include the exact Source game/build and console variables if comparing with Counter-Strike: Source.

Run the numerical regression suite before proposing a change. Geometry changes also need a Roblox Studio reproduction; a numerical test alone cannot validate Blockcast behavior.

Keep simulation independent from camera smoothing and avatar animation. Preserve elapsed-time remainder in the fixed-step accumulator. Document intentional departures from Source behavior.

Submit only code and assets that you have permission to redistribute. Do not include proprietary game source, leaked code, credentials or game assets.

Contributions to this repository are offered under its MIT license.
