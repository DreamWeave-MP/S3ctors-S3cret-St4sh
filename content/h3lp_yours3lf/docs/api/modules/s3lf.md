---
title: S3lf
description: The installed local/player interface for convenient access to the attached object.
weight: 10
extra:
  kind: api
---

{{ api_signature(value="require('openmw.interfaces').s3.lf → S3lfObject") }}

S3lf exposes frequently used object, type, record, and stat data through a lazily resolved view. It reduces repeated engine API indexing; it does not turn every engine value into a plain Lua value or remove the engine's restrictions.

{% usage_note(title="Installed interface · Local and player") %}
Enable H3's plugin and use the interface on an object where its provider is attached. This is not a global or menu interface. `I.s3.lf` is the current path; `I.s3lf` is not. Do not require the provider script as a constructor.
{% end %}

## Read the attached actor's health

```lua
local I = require 'openmw.interfaces'

local function reportHealth()
    local s3lf = assert(I.s3 and I.s3.lf, 'H3 S3lf interface is unavailable')
    local actor = s3lf.asActor()
    if actor then
        print(actor.recordId .. ': ' .. tostring(actor.health.current))
    end
end

return {
    engineHandlers = {
        onInit = reportHealth,
        onLoad = reportHealth,
    },
}
```

Use the [bootstrap's player-script registration](@/h3lp_yours3lf/docs/getting-started/overview.md). The lookup happens when the handler runs rather than assuming the interface is ready during another script's top-level evaluation.

## Common members

| Member | Meaning |
| --- | --- |
| `id` | Game-object instance ID, not record ID. |
| `recordId` | Record identifier shared by instances of that record. |
| `object` | Underlying local game object. |
| `record` | Record data exposed as a field, not a record lookup function. |
| `controls` | Actor controls when the attached object is an actor. |
| `ATTACK_TYPE` | Attack-type constants for actor controls. |
| `EQUIPMENT_SLOT` | Actor equipment-slot constants. |
| `STANCE` | Actor stance constants. |
| `actorType` | `0` player, `1` NPC, `2` creature, `3` non-actor. |
| `bounds` | The attached object's bounding box. |
| `cellsVisited` | Player-only map of cell IDs observed by the player's update handler. |
| `consoleLog(...)` | Lowercase convenience alias for [LogMessage](@/h3lp_yours3lf/docs/api/modules/log-message.md). |
| `distance(other)` | Distance from the attached object's position to another object's position. |
| `sendObjectEvent(name, data?)` | Sends an event to the attached object. |
| `asActor()`, `asNPC()`, `asPlayer()`, `asCreature()`, `asNonActor()` | Same view narrowed to the matching type, or `nil`. NPC includes player. |

Values marked uncacheable are read again; ignored values return `nil`. The lists below describe the complete H3-provided and inherited facade surface. `record` may be a creature, NPC, armor, book, clothing, ingredient, light, miscellaneous, potion, weapon, apparatus, lockpick, probe, repair, activator, container, door, static, or levelled-creature record when the attached object has that record type.

## Inherited object members

S3lf retains the fields and methods of OpenMW's attached-object (`SelfObject`) surface. Their availability and mutation rules remain the OpenMW rules; the facade does not make read-only local object fields writable.

| Member | Meaning |
| --- | --- |
| `contentFile` | Lowercase content file defining the object, or `nil` for a dynamically created object. |
| `position` | Object position. |
| `scale` | Object scale. |
| `rotation` | Object rotation. |
| `saveState` | Whether the object has been modified for save; local scripts read this value. |
| `startingCell` | Original cell, when available. |
| `startingPosition` / `startingRotation` | Original position and rotation. |
| `owner` | Object ownership information. |
| `cell` | Current cell, or `nil` during loading or while inside inventory/container storage. |
| `parentContainer` | Container or actor holding the object, or `nil` when it is in a cell. |
| `type` | OpenMW type table for the object. |
| `count` | Stack count. |
| `globalVariable` | Associated global variable, or `nil`. |
| `isValid()` | Whether the object exists and is available. |
| `sendEvent(eventName, eventData)` | Sends a local event to the object. |
| `getBoundingBox()` | Returns the object's world-space bounding box. |
| `activateBy(actor)` | Activates the object using an actor. |
| `isActive()` | Whether the attached object is in an active cell. |
| `enableAI(value)` | Enables or disables standard AI for the attached actor. |

## Forwarded dynamic members

The attached object's type module, record, and OpenMW animation module may expose additional members. S3lf forwards those members using the same key lookup, binding functions to the attached object and caching values according to the configured key behavior. Their names and availability therefore depend on the attached object's type and record; they are not a fixed H3 field list. Use `type`, `record`, and the relevant OpenMW API contract to determine what a particular object provides.

## Actor methods

These methods exist on actor views. They omit the object argument because S3lf supplies the attached object.

| Member | Meaning |
| --- | --- |
| `getEncumbrance()` | Current actor encumbrance. |
| `getCapacity()` | Current actor inventory capacity. |
| `getBarterGold()` / `setBarterGold(amount)` | Read or set barter gold. |
| `isDead()` / `isDeathFinished()` | Death and finished-death state. |
| `getPathfindingAgentBounds()` | Actor pathfinding bounds. |
| `isInActorsProcessingRange()` | Whether the actor is in processing range. |
| `inventory()` | Actor inventory. |
| `canMove()` | Whether the actor can move. |
| `getRunSpeed()` / `getWalkSpeed()` / `getCurrentSpeed()` | Actor movement speeds. |
| `isOnGround()` / `isSwimming()` | Current movement state. |
| `getStance()` / `setStance(stance)` | Read or set actor stance. |
| `hasEquipped(item)` | Whether the actor has the object equipped. |
| `getEquipment(slot?)` / `setEquipment(equipment)` | Read or set equipment. |
| `getSelectedSpell()` / `setSelectedSpell(spell)` | Read or set the selected spell. |
| `clearSelectedCastable()` | Clear the selected castable. |
| `getSelectedEnchantedItem()` / `setSelectedEnchantedItem(item)` | Read or set the selected enchanted item. |
| `activeEffects()` | Active actor effects. |
| `activeSpells()` | Active actor spells. |
| `spells()` | Actor spell list. |

## Actor stats

These fields are engine stat objects, not copied plain tables. Dynamic stats, AI stats, attributes, and level apply to actor views as supported by the underlying type. Skills are available on NPC and player views.

| Category | Fields |
| --- | --- |
| Dynamic stats | `health`, `magicka`, `fatigue` |
| AI stats | `alarm`, `fight`, `flee`, `hello` |
| Attributes | `strength`, `intelligence`, `willpower`, `agility`, `speed`, `endurance`, `personality`, `luck` |
| Level | `level` |
| Skills | `block`, `armorer`, `mediumarmor`, `heavyarmor`, `bluntweapon`, `longblade`, `axe`, `spear`, `athletics`, `enchant`, `destruction`, `alteration`, `illusion`, `conjuration`, `mysticism`, `restoration`, `alchemy`, `unarmored`, `security`, `sneak`, `acrobatics`, `lightarmor`, `shortblade`, `marksman`, `mercantile`, `speechcraft`, `handtohand` |

## NPC methods

These methods exist on NPC views. OpenMW's NPC type includes the player, so `asNPC()` also exposes them for a player view.

| Member | Meaning |
| --- | --- |
| `getFactions()` | Factions joined by the NPC. |
| `getFactionRank(faction)` / `setFactionRank(faction, value)` | Read or set faction rank. |
| `modifyFactionRank(faction, value)` | Adjust faction rank. |
| `joinFaction(faction)` / `leaveFaction(faction)` | Join or leave a faction. |
| `getFactionReputation(faction)` / `setFactionReputation(faction, value)` | Read or set faction reputation. |
| `modifyFactionReputation(faction, value)` | Adjust faction reputation. |
| `expel(faction)` / `clearExpelled(faction)` | Set or clear faction expulsion. |
| `isExpelled(faction)` | Whether the NPC is expelled from a faction. |
| `getDisposition(player)` / `getBaseDisposition(player)` | Read current or base disposition. |
| `setBaseDisposition(player, value)` / `modifyBaseDisposition(player, value)` | Set or adjust base disposition. |
| `isWerewolf()` / `setWerewolf(werewolf)` | Read or set werewolf state. |

## Player methods

These methods exist only on a player view.

| Member | Meaning |
| --- | --- |
| `getCrimeLevel()` / `setCrimeLevel(crimeLevel)` | Read or set crime level. |
| `isCharGenFinished()` | Whether character generation is finished. |
| `isTeleportingEnabled()` / `setTeleportingEnabled(state)` | Read or set teleporting permission. |
| `quests()` | Player quest data. |
| `addTopic(topicId)` | Add a topic to the player's journal topics. |
| `journal()` | Player journal. |
| `getControlSwitch(key)` / `setControlSwitch(key, value)` | Read or set a player control switch. |
| `getBirthSign()` | Player birth sign. |
| `sendMenuEvent(eventName, eventData?)` | Sends an event to the player's menu context. |

## Record-derived fields

When the attached record provides them, S3lf resolves these fields from the record:

| Field | Meaning |
| --- | --- |
| `isCreature` | Whether the attached record is a creature record. |
| `combatSkill` | Creature combat skill. |
| `name` | Record display name. |
| `model` | Record model path. |
| `baseGold` | Record base gold value. |

Bound type methods omit the object argument. For example, `actor.getStance()` and `actor.getEquipment(slot)` operate on the attached actor. Use dot calls: adding a colon would supply an extra argument. Availability still depends on the object type and underlying OpenMW API.

## Diagnostics and player-specific tracking

| Member | Meaning |
| --- | --- |
| `isInCombat()` | Whether tracked target data is nonempty and engine AI is enabled. |
| `targetData()` | Read-only map of tracked actor IDs to actor objects. |
| `display` | Builds and sends a diagnostic description of the view to nearby players, then returns that description; available on local and player views. |

Combat tracking consumes `OMWMusicCombatTargetsChanged`; it is not an independent scan of every fight in the world. Incoming reports produce `S3CombatTargetAdded` or `S3CombatTargetRemoved`, with the reporting actor as payload. Do not interpret repeated reports as a unique kill count or guaranteed deduplicated transition history.

`S3LFCellChanged` carries the previous cell ID when the player moves between known cells. The player provider saves its tracked target data and visited cells. Consumers should use the interface, not reach into that provider's save payload.

## Caching and lifetime

Most resolved members are cached; selected `openmw.self` keys are explicitly ignored or left uncached through H3's key-behavior table. Type values, type methods, stats, record values, object values, and animation values then follow their own lazy-cache paths. This is not a deep snapshot: cached engine stat objects can still expose current values. Do not infer that every cached scalar is refreshed each frame or that every field exists on every object. Retain the interface only for its valid script/object lifetime and read changing data when needed.

See [State and Context](@/h3lp_yours3lf/docs/concepts/state-and-context.md) for the distinction between wrappers, permissions, and persistent data.
