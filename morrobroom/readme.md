# Morrobroom

## BinaryTarget

## What Is Morrobroom?

Morrobroom is a Quake map compiler for Morrowind/OpenMW users. It is engine agnostic, like trenchbroom itself, with the intent being to provide an alternative way to create Morrowind assets and dungeons.  

## How Do I Set Up Morrobroom?

Morrobroom is currently tested against Trenchbroom 2025.3. Trenchbroom builds starting in January 2024 and on were tested, but may or may not have had breaking changes I don't remember. For best results, use 2025.3.  

Afterward, you will need to know where Trenchbroom stores its [game configurations](https://trenchbroom.github.io/manual/latest/#game_configuration_files) for your platform. Once you've found it, extract Morrobroom to somewhere you can keep track of on your PC. There will be a `resources` folder alongside it. Copy all of the *files*, and not folders, into your Trenchbroom game config directory. You will have two folders as well, `Meshes`, and `Textures`. These are assets Trenchbroom itself may use to display builtin tool textures, etc. While this is a highly unorthodox approach for OpenMW setups, I recommend installing these into Morrowind's `Data Files` folder regardless. They should never conflict with Morrowind assets, nor will the game generally use them. However, they are Morrowind-themed, and the meshes are compatible with OpenCS, so you may also reuse them in Morrowind modding if you *choose* to.  

Once you have opened Trenchbroom, create a new map, and select `Morrowind` as the game. Then, go to `View -> Preferences` and select `Morrowind`. Point Trenchbroom to the root directory of your Morrowind install, eg `/home/s3kshun8/Games/Morrowind` - NOT the `Data Files` folder! You will also need to point Trenchbroom, to the location of `morrobroom.exe` or `morrobroom` on unix platforms. Optionally, also give it the path to OpenMW-CS.

Now, you should go to `Run -> Compile Map`. You should see the default `Map-To-Engine` compilation profile you just copied into Trenchbroom's game config dir. *most* importantly, you'll find the `Working Directory` field. Set this to whichever is most relevant for your platform:  

### Linux

`$XDG_DATA_HOME/openmw/data or $HOME/.local/share/openmw/data`

### Mac

`$HOME/Library/Application\ Support/openmw/data`

### Windows

PowerShell

`Join-Path ([environment]::GetFolderPath("mydocuments")) "My Games\OpenMW\data"`

File Explorer

`C:\Users\Username\Documents\My Games\OpenMW\data`

`Documents\My Games\OpenMW\data`

You now have the most basic setup for Morrobroom possible - Trenchbroom should be aware of Morrowind itself, and be able to access those assets and make use of them when mapping. However, there are various limitations to this you should be aware of. Namely, that Trenchbroom naturally cannot read BSA files. Depending on where you got your Morrowind installation from, this could be a problem for you. There are numerous ways to work around this problem. My recommended one, is [vfstool](https://github.com/magicaldave/vfstool). Set up an openmw.cfg file like so:

```toml
fallback-archive=Morrowind.bsa
fallback-archive=Tribunal.bsa
fallback-archive=Bloodmoon.bsa
data=/home/s3kshun8/Games/Morrowind/Data Files
data=/home/s3kshun8/GitHub/propaganda-machine-2024/
```

Then, run vfstool against it like so:
`vfstool -c $HOME/GitHub/propaganda-machine-2024/compile.cfg collapse -es "./Propaganda-Install/Data Files"`
This will create a merged `Data Files` folder using every file defined in that particular openmw.cfg. It will extract BSA files and use symlinks where possible, but otherwise files will not copy directly. Then, go back to `View -> Preferences` in Trenchbroom and set it to the newly created folder, `Propaganda-Install`. For ease of use, set an absolute path and run it the same way every time. This will mean you don't have to treat your sub-mods as mods, and Trenchbroom just interprets this all as part of the game's base data.

Alternatively, you may set up symlinks in your Morrowind install directory to specific mods. For example, in the same folder as `Morrowind.exe`, have:

```toml
Data Files/
Tamriel Data/
OAAB_Data/
```

Finally, you may also maintain your own texture archives. Trenchbroom will see and mount any `zip` file in its configured `Data Files` folder, whose extension is `.zip`, `.archive`, or `.mbtex`. This way you can pick and choose which texture bundles you want Trenchbroom to load by just switching zip files out in your Morrowind install, which the game itself will never use.  

Just as long as Trenchbroom is able to actually find whatever assets you're attempting to feed it. :)
