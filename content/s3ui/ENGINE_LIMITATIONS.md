# S3UI Engine-Level Limitations

This file tracks places where S3UI can match OpenMW UI behavior only up to the boundary exposed by the Lua API.

## Travel: `GetPCTraveling`

Vanilla OpenMW travel sets the engine's internal "player is traveling" flag before teleporting:

- `openmw/apps/openmw/mwgui/travelwindow.cpp`
- `TravelWindow::onTravelButtonClick`
- `MWBase::Environment::get().getWorld()->setPlayerTraveling(true)`

That flag is what legacy MWScript observes through `GetPCTraveling`.
The script opcode reads the same engine state through `isPlayerTraveling()` in
`openmw/apps/openmw/mwscript/miscextensions.cpp`.

OpenMW Lua currently has no public API for setting this flag. S3UI can charge gold, advance time, teleport the player, and approximate follower behavior, but it cannot make `GetPCTraveling` report true without an OpenMW source/API change.

If OpenMW exposes this later, S3UI's travel execution should set the flag immediately before teleporting, matching vanilla `TravelWindow` behavior.
