+++
title = "Caius Takes Weekends Off"
description = "Use the Tamrielic weekday and activation-time teleportation to give Caius a modest social life."
weight = 65

[extra]
api_docs = true
kind = "experiment"
+++

## What this demonstrates

- [`day_of_week`](@/static_switching_system/docs/api/conditions/player-and-world-state.md#day-of-week)
- [`not`](@/static_switching_system/docs/api/conditions/logic.md#not), [`cell`](@/static_switching_system/docs/api/conditions/location-and-identity.md#cell), [`object_type` and `record_id`](@/static_switching_system/docs/api/conditions/location-and-identity.md)
- [`teleport`](@/static_switching_system/docs/api/actions/world-and-transform.md#teleport)
- A condition that is evaluated when an object becomes active rather than when the game clock changes

## Why it works

On Loredas and Sundas, an active Caius in his house is sent to the South Wall Cornerclub. On the other five days, an active Caius in the Cornerclub is sent home. There is no `once`: SSS is allowed to reconsider Caius each time he becomes active, so the rule can correct his location the next time he is processed after the weekday changes.

This is deliberately a lazy schedule, not an NPC scheduler. SSS cannot move Caius while he is sitting in an inactive cell. On a weekend, visiting his house activates him and sends him to South Wall; on a weekday, finding him at South Wall sends him home. Checking the destination first does not summon him there.

Caius does not check his watch. More importantly, SSS does not know where he is until the world wakes him up. The opening quest sends the player to South Wall to ask where Caius lives, but entering South Wall first on a weekend does not cause Caius to appear there. Entering his house first does.

## The catch

- `day_of_week` uses the Tamrielic game calendar, not the real-world clock. Its canonical values are `sundas`, `morndas`, `tirdas`, `middas`, `turdas`, `fredas`, and `loredas`.
- `day_of_week` is a condition, not a weekday-change event. Caius does not check his watch, and he does not teleport at midnight while the player is watching him.
- If Caius is active at 23:59 Fredas and the player waits until Loredas, the weekend rule runs only the next time SSS processes him. The same applies when Sundas becomes Morndas.
- The positions are vanilla interior coordinates, but furniture, collision, or another mod can make a destination unsuitable. `onGround: true` asks OpenMW to resolve final ground placement; it is not a guarantee of a perfect spot.

## Complete YAML

The source fixture is `Examples/InstanceModifier_CaiusTakesWeekendsOff.yaml`.

```yaml
log_name: Caius Takes Weekends Off
priority: polish

instances:
  - conditions:
      - object_type: NPC
      - record_id: "^caius cosades$"
      - cell: "Balmora, Caius Cosades' House"
      - day_of_week:
          - loredas
          - sundas
    actions:
      - teleport:
          cell: "Balmora, South Wall Cornerclub"
          position:
            x: 291
            y: 537
            z: 261
          onGround: true

  - conditions:
      - object_type: NPC
      - record_id: "^caius cosades$"
      - cell: "Balmora, South Wall Cornerclub"
      - not:
          day_of_week:
            - loredas
            - sundas
    actions:
      - teleport:
          cell: "Balmora, Caius Cosades' House"
          position:
            x: 163
            y: -228
            z: 192
          onGround: true
```
