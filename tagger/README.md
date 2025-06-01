# Tagger

Tagger is an attempt to reimplement Skyrim's system of adding tags to records/objects in-game, in OpenMW. While eventually Skyrim's literal format could be supported, this is most likely a long ways off and not necessarily practical for Morrowind modders. MTM attempts to bridge the gap, by making it easy to create and use tags for classifying objects - like, which cells are dungeons, or merchants, or distinguishing bandages from regular medical supplies, etc.

End users will need this as a dependency of other mods (hopefully), but it doesn't do much of anything in itself. Read on past the installation guide for developer's notes.

## Installation

1. Download the mod from [this URL](https://modding-openmw.gitlab.io/s3ctors-s3cret-st4sh/mod_tag_mod)
1. Extract the zip to a location of your choosing, examples below:

        # Windows
        C:\games\OpenMWMods\mod_tag_mod

        # Linux
        /home/username/games/OpenMWMods/mod_tag_mod

        # macOS
        /Users/username/games/OpenMWMods/mod_tag_mod

1. Add the appropriate data path to your `opemw.cfg` file (e.g. `data="C:\games\OpenMWMods\mod_tag_mod"`)
1. Add `content=ModTags.omwscripts` to your load order in `openmw.cfg` or enable them via OpenMW-Launcher

## Using Tags

Tags are stored as yaml files under the subdirectory `ModTags` of any `data=` entry in openmw.cfg. When properly installed, Tagger includes a (hopefully growing) built-in set of tag definitions for the vanilla plugins, as well as some popular mods. Contributions to Tagger's built-in tags and associations are welcome and desired. The rest of this category will describe how to create tags and attach them to any object desired. This includes cells, quests, objects in the game world, or whatever other thing you can represent as a string in Lua.

### Yaml Schema

Every Tagger definition file should have either or both of the following fields:

`tags` is a list of tag names to be used. It might look like this:

        tags:
          - "ArmorDwarven"
          - "ArmorIron"
          - "ArmorGlass"

These will then be made available to other modders through the Tagger interface.

`applied_tags` is a map of tagged objects to the list of tags they actually use. Multiple mods may add as many tags as they wish to the same object as many times as they like. Tags may not be removed by design.

        applied_tags:
          "Seyda Neen, Arrille's Tradehouse":
            - "CellMerchant"
          "Arkngthand, Halls of Hollow Hand":
            - "CellDungeon"
            - "CellDwemer"
            - "CellDwemerDungeon"
            - "CellMainQuest" 
          "Caius Cosades":
            - "NPCMainQuest"

When Tagger is loaded, all tags are loaded immediately and made available in all script contexts. Tags are stored inside of a global storage section which only lives through the length of your play session.
This means that Tagger doesn't occupy unnecessary space in your save file, is always as up to date as it can be, and can be used by any object in the game. Also, note that it's not necessarily a requirement that tags are associated with a specific gameObject. You can apply tags to anything you can represent as a string in a yaml file, so feel free to make up your own associations, such as with quests or even specific MWScripts.

### API

For scripters whom are not creating their own tag definitions but derivative scripts (you can do both!) there are mostly four values you'd care about.
Global scripts can access Tagger's features through `I.TaggerG`, whereas all other scripts can access them through `I.TaggerL`. Both the global list of tags and all applied tags are available as the values `I.TaggerL.TagList` or `I.TaggerL.AppliedTags`. Calls to these functions normalize your inputs, so don't worry about case sensitivity.

You can check if an object has a tag, or read its entire tag list like so:
        I.TaggerL.objectHasTag(self, "NPCMainQuest")
        I.TaggerL.objectTags(self)

<div id="credits" style="text-align: center;">

## Credits

Author: S3ctor

All assets made by Dave Corley under the GPL3 license. Please enjoy my mod, hack away as you please, and respect the freedoms of your fellow modders and players in the meantime.

</div>
