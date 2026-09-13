#!/usr/bin/env python3
"""
Starwind local build + standalone closure audit.

This is a Python transcription of the uploaded historical Starwind-Builder build.sh,
adapted to the St4sh directory layout:

    sw_merged/
      addVanillaRefs
      merge_to_master
      tes3conv
      tes3cmd              # preferred here; PATH fallback supported
      motherjungle_audit.py
      plugins/
        *.json

It performs the old Builder preprocessing/surgery with tes3cmd, compiles JSON to TES3
plugins, runs the old merge graphs, builds standalone locally, and can audit the
result for unresolved hard TES3 record dependencies.

Modes intentionally mirror the old shell script:
    solo        old default/SP path
    standalone  old standalone path
    tsi         old multiplayer/TSI path
    all         solo + standalone, plus tsi if all TSI-only inputs are present

Examples:
    ./motherjungle_audit.py doctor
    ./motherjungle_audit.py build standalone
    ./motherjungle_audit.py build tsi
    ./motherjungle_audit.py audit .swbuild/standalone/out/Starwind-Standalone.omwaddon
    ./motherjungle_audit.py all --fail-on-unresolved
"""
from __future__ import annotations

import argparse
import json
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PLUGINS = ROOT / "plugins"
BUILD_ROOT = ROOT / ".swbuild"

# Exact junk-cell list from historical build.sh.
JUNK_CELL = [
    "ashinabi, smuggler den",
    "balmora, drarayne thelas' storage",
    "balmora, hecerinde's house",
    "baram ancestral tomb",
    "berandas, propylon chamber",
    "cavern of the incarnate",
    "dantooine",
    "dantooine, cavern",
    "falensarano, propylon chamber",
    "gnisis, arvs-drelen",
    "gnisis, madach tradehouse",
    "hairat-vassamsi egg mine, queen's lair",
    "kashyyk",
    "koal cave",
    "kogoruhn, hall of maki",
    "kogoruhn, vault of aerode",
    "moonmoth legion fort, prison towers",
    "mournhold, great bazaar",
    "mournhold, plaza brindisi dorom",
    "mournhold, royal palace: basement",
    "mournhold, royal palace: helseth's chambers",
    "Nar Shaddaa, Hutt Base",
    "nerano ancestral tomb",
    "pelagiad, south wall",
    "seyda neen, census and excise office",
    "solstheim, gyldenhul barrow",
    "solstheim, legge",
    "surirulk",
    "testcell",
    "toddtest",
    "tukushapal",
    "vivec, palace of vivec",
    "yakin",
]

# Canonical source names in the new plugins/ JSON layout.
SOURCE_JSON = {
    "Morrowind": "Morrowind.json",
    "Tribunal": "Tribunal.json",
    "Bloodmoon": "Bloodmoon.json",
    "Minimal": "Minimal.json",
    "V115": "StarwindRemasteredV1.15.json",
    "Patch": "StarwindRemasteredPatch.json",
    "Enhanced": "Starwind Enhanced.json",
    "PlanExp": "StarwindPlanExp.json",
    "CPP": "Starwind Community Patch Project.json",
    "Naboo": "naboo.json",
    "Bings": "bings race pack.json",
    "AltStart": "alt_start1.5.json",
    "Vvardenfell": "StarwindVvardenfell.json",
    "MPRecords": "StarwindMPRecords.json",
    "PartyHats": "PartyHats.json",
}

# Binary filenames expected by historical build.sh.
BINARY_NAME = {
    "Morrowind": "Morrowind.esm",
    "Tribunal": "Tribunal.esm",
    "Bloodmoon": "Bloodmoon.esm",
    "Minimal": "Minimal.esp",
    "V115": "StarwindRemasteredV1.15.esm",
    "Patch": "StarwindRemasteredPatch.esm",
    "Enhanced": "Starwind Enhanced.esm",
    "PlanExp": "StarwindPlanExp.esp",
    "CPP": "Starwind Community Patch Project.esp",
    "Naboo": "naboo.esp",
    "Bings": "bings race pack.esp",
    "AltStart": "alt_start1.5.esp",
    "Vvardenfell": "StarwindVvardenfell.esp",
    "MPRecords": "StarwindMPRecords.esp",
    "PartyHats": "PartyHats.esp",
}

BASE_REQUIRED = {
    "solo": ["V115", "Patch"],
    "standalone": ["V115", "Patch", "Minimal", "Morrowind", "Tribunal", "Bloodmoon"],
    "tsi": [
        "V115", "Patch", "Enhanced", "PlanExp", "AltStart", "Vvardenfell",
        "CPP", "Naboo", "Bings", "PartyHats",
    ],
}

NEVER_COPY = {
    "Header", "Skill", "StartScript", "LandscapeTexture", "Landscape",
    "PathGrid", "Dialogue", "DialogueInfo", "Cell",
}

# Known-dead inherited vanilla dialogue INFOs identified from the standalone
# closure audit. These 53 INFOs are the complete source set behind the unresolved
# Morag Tong / Hands of Almalexia / Census and Excise faction references.
#
# IMPORTANT: these are pruned ONLY from the temporary vanilla masters used by the
# standalone build, immediately before addVanillaRefs. Canonical plugins/*.json
# sources are never modified, and the earlier Starwind merge is unaffected.
DEAD_VANILLA_FACTION_INFO_IDS = [
    "10892597398701449",
    "15740996644818361",
    "18628248200029145",
    "27104661529628909",
    "27380594163115117",
    "46239530102619813",
    "68081962797431540",
    "84318339166287950",
    "138471225627324116",
    "175158043101416917",
    "209281375883337301",
    "227566641690323024",
    "233813539948315535",
    "387031381294227495",
    "524426342189474603",
    "786912151253629496",
    "801171242963610533",
    "917331001273226401",
    "959211469735030099",
    "999411412119813019",
    "1278371803083124313",
    "1404115803293832208",
    "1556426861203214287",
    "1922626285304825312",
    "1922919187540014555",
    "1933022293213049142",
    "2060515467642016544",
    "2170199432650617071",
    "2674120808223158958",
    "2689112858236774173",
    "2928598872632726697",
    "3014115110938721232",
    "3029810224114315641",
    "3099612586852222907",
    "3134028020260168750",
    "4947196993132126615",
    "7347299612038512802",
    "8077199921502012362",
    "10587309131832629595",
    "12276284861507021461",
    "12560149042482210158",
    "12957241603014511444",
    "13167128832337732279",
    "13369242242758228534",
    "15146151042139030418",
    "19491238341389220281",
    "20280268732850724042",
    "21710101122065519831",
    "22580190852053612072",
    "23187123271197316191",
    "23407321083087418600",
    "24702137811180913386",
    "30253208512738732261",
]

# Starwind reuses these vanilla regions for pseudo-exterior weather, but their
# Morrowind/Bloodmoon sleep encounters are not valid for the standalone world.
STANDALONE_REGION_SLEEP_CREATURES = [
    ("Ascadian Isles Region", "ex_ascadianisles_sleep"),
    ("Isinfier Plains Region", "bm_ex_isinplains_sleep"),
    ("Azura's Coast Region", "ex_azurascoast_sleep"),
    ("Bitter Coast Region", "ex_bittercoast_sleep"),
    ("Grazelands Region", "ex_grazelands_sleep"),
    ("Moesring Mountains Region", "bm_ex_moemountains_sleep"),
    ("Red Mountain Region", "ex_RedMtn_all_sleep"),
    ("West Gash Region", "ex_westgash_sleep"),
]

# TES3/TESCS DialogueInfo faction sentinel meaning "-NO FACTION-".
NO_FACTION_SENTINELS = {"ffff"}

HARD_KINDS = {
    "race.spells",
    "soundgen.creature", "soundgen.sound",
    "magic_effect.bolt_sound", "magic_effect.cast_sound",
    "magic_effect.hit_sound", "magic_effect.area_sound",
    "magic_effect.cast_visual", "magic_effect.bolt_visual",
    "magic_effect.hit_visual", "magic_effect.area_visual",
    "region.sleep_creature", "region.sounds",
    "birthsign.spells",
    "door.script", "door.open_sound", "door.close_sound",
    "miscitem.script", "weapon.script", "weapon.enchanting",
    "container.script", "container.inventory",
    "creature.script", "creature.inventory", "creature.spells",
    "creature.ai.activate", "creature.sound",
    "bodypart.race", "light.script", "light.sound",
    "npc.script", "npc.inventory", "npc.spells", "npc.ai.activate",
    "npc.race", "npc.class", "npc.faction", "npc.head", "npc.hair",
    "armor.script", "armor.enchanting", "armor.male_bodypart",
    "armor.female_bodypart",
    "clothing.script", "clothing.enchanting", "clothing.male_bodypart",
    "clothing.female_bodypart",
    "repairitem.script", "activator.script", "apparatus.script",
    "lockpick.script", "probe.script", "ingredient.script",
    "book.script", "book.enchanting", "alchemy.script",
    "leveled_item.items", "leveled_creature.creatures",
    "cell.region", "cell.reference.id", "cell.reference.owner",
    "cell.reference.owner_global", "cell.reference.owner_faction",
    "cell.reference.key", "cell.reference.trap", "cell.reference.soul",
    "info.speaker_id", "info.speaker_race", "info.speaker_class",
    "info.speaker_faction", "info.player_faction",
    "faction.reaction",
}


def log(msg: str) -> None:
    print(f"[starwind] {msg}", flush=True)


def die(msg: str, code: int = 2):
    print(f"[starwind] ERROR: {msg}", file=sys.stderr)
    raise SystemExit(code)


def tool(name: str) -> Path:
    local = ROOT / name
    if local.exists() and os.access(local, os.X_OK):
        return local
    found = shutil.which(name)
    if found:
        return Path(found)
    die(f"required tool '{name}' not found beside script or in PATH")


def run(args, *, cwd: Path, stdout=None, stderr=None, quiet=False) -> None:
    argv = [str(x) for x in args]
    if not quiet:
        log("$ " + " ".join(shlex.quote(x) for x in argv))
    subprocess.run(argv, cwd=cwd, stdout=stdout, stderr=stderr, check=True)


def src_json(key: str) -> Path:
    return PLUGINS / SOURCE_JSON[key]


def source_present(key: str) -> bool:
    return src_json(key).exists()


def mode_paths(mode: str):
    root = BUILD_ROOT / mode
    return root, root / "work", root / "out", root / "reports"


def required_for(mode: str, include_mp_records: bool = True):
    keys = list(BASE_REQUIRED[mode])
    if mode == "tsi" and include_mp_records:
        keys.append("MPRecords")
    return keys


def doctor() -> int:
    ok = True
    print(f"root:    {ROOT}")
    print(f"plugins: {PLUGINS}")
    print()
    for name in ("tes3conv", "merge_to_master", "addVanillaRefs", "tes3cmd"):
        local = ROOT / name
        path = local if local.exists() else shutil.which(name)
        state = "OK" if path and os.access(path, os.X_OK) else "MISSING"
        ok &= state == "OK"
        print(f"{name:18} {state:8} {path or ''}")
    print()
    for key, rel in SOURCE_JSON.items():
        p = PLUGINS / rel
        print(f"{key:18} {'OK' if p.exists() else 'absent':8} {rel}")
    return 0 if ok else 1


def compile_sources(mode: str, work: Path, include_mp_records: bool) -> None:
    keys = set(required_for(mode, include_mp_records))

    # merge_to_master resolves every declared master by filename from its cwd.
    # Even the solo merge therefore needs the vanilla masters staged locally,
    # because StarwindRemasteredPatch/V1.15 still declare them.
    keys.update(["Morrowind", "Tribunal", "Bloodmoon"])

    # TSI preprocessing touches these explicitly, so they must exist in TSI mode.
    if mode == "tsi":
        keys.update(["Enhanced", "PlanExp", "CPP", "Naboo", "Bings", "AltStart", "Vvardenfell", "PartyHats"])
    if mode == "standalone":
        keys.update(["Morrowind", "Tribunal", "Bloodmoon", "Minimal"])

    missing = [SOURCE_JSON[k] for k in keys if not source_present(k)]
    if missing:
        die(f"{mode} build is missing required source JSON: {', '.join(sorted(missing))}")

    conv = tool("tes3conv")
    for key in sorted(keys):
        src = src_json(key)
        dst = work / BINARY_NAME[key]
        run([conv, "-o", src, dst], cwd=work)


def tc(work: Path, *args, quiet=False, stdout=None, stderr=None):
    run([tool("tes3cmd"), *args], cwd=work, quiet=quiet, stdout=stdout, stderr=stderr)


def mtm(work: Path, plugin: str, master: str):
    run([tool("merge_to_master"), plugin, master], cwd=work)


def prune_dead_standalone_vanilla_dialogue(work: Path) -> None:
    """Remove known-dead vanilla INFOs from standalone build-local masters.

    This deliberately runs only after the Starwind/Minimal merge has finished,
    so merge_to_master sees the unmodified staged Bethesda masters. The pruned
    masters exist solely as addVanillaRefs reconstruction/dependency inputs.
    """
    masters = [
        "Morrowind.esm",
        "Tribunal.esm",
        "Bloodmoon.esm",
    ]
    missing = [name for name in masters if not (work / name).exists()]
    if missing:
        die(
            "standalone vanilla dialogue prune is missing staged masters: "
            + ", ".join(missing)
        )

    log(
        "Pruning 53 known-dead vanilla faction INFOs from temporary "
        "standalone masters..."
    )

    # tes3cmd accepts multiple --exact-id selectors and multiple plugin inputs.
    # One command keeps this surgery deterministic and visible in the build log.
    args = ["delete", "--type", "INFO"]
    for info_id in DEAD_VANILLA_FACTION_INFO_IDS:
        args.extend(["--exact-id", info_id])
    args.extend(masters)
    tc(work, *args)


def clear_standalone_region_sleep_creatures(work: Path) -> None:
    """Clear vanilla sleep encounters from Starwind's reused regions.

    The Starwind patch supplies six of these regions itself; the other two are
    inherited from the staged Morrowind and Bloodmoon masters. Modify only the
    standalone build inputs so the ordinary merged and vanilla source data
    retain their original gameplay.
    """
    inputs = [
        "Starwind.esp",
        "Morrowind.esm",
        "Bloodmoon.esm",
    ]
    missing = [name for name in inputs if not (work / name).exists()]
    if missing:
        die(
            "standalone region sleep cleanup is missing staged inputs: "
            + ", ".join(missing)
        )

    log("Clearing vanilla sleep encounters from reused standalone regions...")
    for region_id, sleep_creature in STANDALONE_REGION_SLEEP_CREATURES:
        tc(
            work,
            "modify",
            "--type", "REGN",
            "--exact-id", region_id,
            "--sub-match", "Sleep_Creature_ID:",
            "--replace", f"/{sleep_creature}//",
            *inputs,
        )


def common_preprocess(work: Path, mode: str) -> None:
    # Non-TSI branch from historical build.sh.
    if mode != "tsi":
        tc(
            work, "modify", "--type", "SCPT",
            "--replace", "/who's ship/whose ship/",
            "StarwindRemasteredV1.15.esm", "StarwindRemasteredPatch.esm",
        )

    # Unreferenced typo script.
    tc(work, "delete", "--type", "SCPT", "--exact-id", "sw_", "StarwindRemasteredPatch.esm")

    # Destroy bytecode for every .esm/.esp in the build workdir.
    log("Destroying bytecode...")
    plugin_files = sorted([p.name for p in work.iterdir() if p.suffix.lower() in {".esm", ".esp"}])
    if plugin_files:
        with open(os.devnull, "wb") as dn:
            tc(
                work, "modify", "--type", "SCPT", "--sub-match", "Bytecode:",
                "--replace", "/.*//", *plugin_files,
                quiet=True, stdout=dn, stderr=dn,
            )

    log("Fixing typos...")
    tc(
        work, "modify", "--type", "WEAP", "--exact-id", "sw_grplasm",
        "--replace", "/Name:44mm Pasma Grenade/Name:44mm Plasma Grenade/",
        "StarwindRemasteredPatch.esm",
    )
    tc(
        work, "modify", "--type", "ACTI",
        "--replace", "/Name:Asteriod/Name:Asteroid/",
        "StarwindRemasteredV1.15.esm", "StarwindRemasteredPatch.esm",
    )

    log("Cleaning junk cells...")
    for cell in JUNK_CELL:
        tc(
            work, "delete", "--type", "CELL", "--type", "PGRD",
            "--hide-backups", "--exact-id", cell,
            "StarwindRemasteredV1.15.esm", "StarwindRemasteredPatch.esm",
        )
    tc(
        work, "delete", "--type", "CELL", "--exterior",
        "StarwindRemasteredV1.15.esm", "StarwindRemasteredPatch.esm",
    )

    # Historical diagnostic dump. Keep it as an artifact instead of spewing into CI stdout.
    diag = work / "tatooine_objidx_397.dump.txt"
    with diag.open("wb") as f:
        tc(
            work, "dump", "--type", "CELL", "--exact-id", "Tatooine",
            "--instance-match", "ObjIdx:397 ", "StarwindRemasteredPatch.esm",
            stdout=f,
        )

    tc(work, "delete", "--type", "GMST", "--exact-id", "sEffectTurnUndead", "StarwindRemasteredPatch.esm")
    tc(work, "delete", "--type", "MGEF", "--exact-id", "101", "StarwindRemasteredPatch.esm")

    tc(
        work, "delete", "--type", "LEVC", "--exact-id", "sw_sandcreatures",
        "--sub-match", "SW_Rakhoul1",
        "StarwindRemasteredPatch.esm", "StarwindRemasteredV1.15.esm",
    )

    # Enhanced cleanup is only possible/needed when Enhanced exists.
    enhanced = work / "Starwind Enhanced.esm"
    if enhanced.exists():
        log("Patching Enhanced...")
        tc(work, "delete", "--type", "CELL", "--exact-id", "Tatooine", "Starwind Enhanced.esm")
        tc(
            work, "delete", "--type", "CELL", "--exact-id", "Taris, Central Plaza",
            "--instance-match", "MastIdx:5", "Starwind Enhanced.esm",
        )
        tc(
            work, "delete", "--type", "CELL", "--exact-id", "Taris, Central Plaza",
            "--instance-match", "ObjIdx:8517", "StarwindRemasteredPatch.esm",
        )
        tc(
            work, "delete", "--type", "CELL",
            "--match", "Taris, Central Plaza: Government Office",
            "--instance-match", "MastIdx:5", "--instance-match", "SW_In_TableGround",
            "Starwind Enhanced.esm",
        )
        tc(
            work, "delete", "--type", "CELL",
            "--match", "Taris, Central Plaza: Government Office",
            "--instance-match", "SW_In_TableGround",
            "StarwindRemasteredPatch.esm",
        )
        tc(
            work, "delete", "--type", "CELL",
            "--exact-id", "Taris, Central Plaza: Capital Tower Upper Level",
            "--instance-match", "SW_In_TableGround",
            "StarwindRemasteredPatch.esm",
        )
        tc(
            work, "delete", "--type", "CELL",
            "--exact-id", "Taris, Central Plaza: Capital Tower Upper Level",
            "--instance-match", "MastIdx:5", "--instance-match", "SW_In_TableGround",
            "StarwindRemasteredPatch.esm",
        )
        tc(
            work, "delete", "--type", "CELL", "--exact-id", "Taris, Upper City Cantina",
            "--instance-match", "Sign", "StarwindRemasteredPatch.esm",
        )
        tc(
            work, "delete", "--type", "CELL", "--exact-id", "Taris, Upper City Cantina",
            "--instance-match", "MastIdx:5", "Starwind Enhanced.esm",
        )
        tc(
            work, "delete", "--type", "CELL", "--exact-id", "Nar Shaddaa, Lower City",
            "--instance-match", "SW_SignCantina", "--instance-match", "X:9336",
            "StarwindRemasteredPatch.esm",
        )
        tc(
            work, "delete", "--type", "CELL", "--exact-id", "Nar Shaddaa, Lower City",
            "--instance-match", "SW_SignCantina", "--instance-match", "MastIdx:5",
            "Starwind Enhanced.esm",
        )
        tc(
            work, "delete", "--type", "CELL", "--exact-id", "Nar Shaddaa, Customs",
            "--instance-match", "SW_SignCantina", "StarwindRemasteredPatch.esm",
        )
        tc(
            work, "delete", "--type", "CELL", "--exact-id", "Nar Shaddaa, Customs",
            "--instance-match", "SW_SignCantina", "--instance-match", "MastIdx:5",
            "Starwind Enhanced.esm",
        )
        tc(
            work, "delete", "--type", "CELL", "--exact-id", "Starwind test cell",
            "--instance-match", "MastIdx:5", "Starwind Enhanced.esm",
        )
        tc(
            work, "delete", "--type", "ARMO", "--match", "swe_mandochest",
            "--sub-match", "Female_Body_ID:", "Starwind Enhanced.esm",
        )

    tc(
        work, "delete", "--type", "DOOR", "--sub-match", "DoNothing",
        "--exact-id", "in_t_door_small", "StarwindRemasteredV1.15.esm",
    )


def tsi_preprocess(work: Path) -> None:
    log("Applying TSI-specific Builder surgery...")

    # Exact reference deletions.
    commands = [
        ("Nar Shaddaa, Customs", "ObjIdx:16461 ", ["StarwindRemasteredPatch.esm"]),
        ("Taris, Ruined Plaza", "ObjIdx:6874 ", ["StarwindRemasteredPatch.esm"]),
        ("Taris, Ruined Plaza", "ObjIdx:7201 ", ["StarwindRemasteredPatch.esm"]),
        ("Taris, Ruined Plaza", "ObjIdx:7202 ", ["StarwindRemasteredPatch.esm"]),
        ("Taris, Ruined Plaza", "ObjIdx:7203 ", ["StarwindRemasteredPatch.esm"]),
        ("Taris, Ruined Plaza", "ObjIdx:7204 ", ["StarwindRemasteredPatch.esm"]),
        ("Taris, Ruined Plaza", "ObjIdx:7205 ", ["StarwindRemasteredPatch.esm"]),
        ("Taris, Ruined Plaza: Medical Bay", "ObjIdx:6749 ", ["StarwindRemasteredPatch.esm"]),
        ("Nar Shaddaa, Customs", "ObjIdx:16453 ", ["StarwindRemasteredPatch.esm"]),
        ("Nar Shaddaa, Customs", "ObjIdx:16507 ", ["bings race pack.esp"]),
        ("Tatooine, Sandriver", "ObjIdx:1109 ", ["StarwindRemasteredPatch.esm"]),
        ("The Outer Rim, Freighter", "ObjIdx:2951 ", ["StarwindRemasteredPatch.esm"]),
        ("The Outer Rim, Freighter", "ObjIdx:2952 ", ["StarwindRemasteredPatch.esm"]),
        ("The Outer Rim, Freighter", "ObjIdx:3024 ", ["StarwindRemasteredPatch.esm"]),
        ("The Outer Rim, Freighter", "ObjIdx:16384 ", ["StarwindRemasteredPatch.esm", "StarwindRemasteredV1.15.esm"]),
        ("The Outer Rim, Freighter", "ObjIdx:16400 ", ["StarwindRemasteredPatch.esm", "StarwindRemasteredV1.15.esm"]),
        ("Manaan, Republic Embassy", "ObjIdx:6771 ", ["StarwindRemasteredV1.15.esm"]),
        ("Manaan, Sith Embassy", "ObjIdx:9107 ", ["StarwindRemasteredV1.15.esm", "StarwindRemasteredPatch.esm"]),
    ]
    for cell, match, files in commands:
        tc(work, "delete", "--type", "CELL", "--exact-id", cell, "--instance-match", match, *files)

    # Historical Beast's Lair extraction artifact. The uploaded build.sh creates and cleans
    # beastlair.esp but never merges it back. Preserve that behavior exactly rather than
    # silently "fixing" history.
    tc(
        work, "dump", "--type", "CELL", "--exact-id", "Tatooine, Beast's Lair",
        "--raw-with-header", "beastlair.esp", "StarwindRemasteredPatch.esm",
    )
    tc(work, "delete", "--instance-match", "DELE", "beastlair.esp")

    tc(work, "delete", "--type", "CELL", "--exact-id", "Nar Shaddaa, Makacheesa Market", "StarwindVvardenfell.esp")
    tc(
        work, "delete", "--type", "CELL", "--exact-id", "Nar Shaddaa, Vvardenfell Hanger",
        "--instance-match", "ObjIdx:14 ", "StarwindVvardenfell.esp",
    )
    tc(work, "delete", "--type", "CELL", "--exact-id", "Imperial Prison Ship", "alt_start1.5.esp")

    tc(
        work, "modify", "--replace", "/random gold/tsi_gold/",
        "StarwindRemasteredPatch.esm", "StarwindRemasteredV1.15.esm",
    )
    tc(
        work, "modify", "--type", "CELL",
        "--replace", "/SW_ManaKoltoTank/tsi_kolto_nowall/",
        "StarwindRemasteredV1.15.esm", "StarwindRemasteredPatch.esm",
    )
    tc(
        work, "modify", "--type", "CELL",
        "--replace", "/SW_ManaKoltoMedTank/tsi_kolto_wall/",
        "StarwindRemasteredV1.15.esm", "StarwindRemasteredPatch.esm",
    )

    tc(work, "delete", "--type", "CELL", "--exterior", "bings race pack.esp")
    tc(
        work, "delete", "--type", "CELL",
        "--exact-id", "nar shaddaa, h.t. parnell's oddities",
        "bings race pack.esp",
    )

    tc(
        work, "delete", "--type", "CELL", "--exact-id", "Taris, Upper City Cantina",
        "--instance-match", "SW_TarisHuttRagax", "StarwindRemasteredPatch.esm",
    )
    tc(
        work, "delete", "--type", "CELL", "--exact-id", "Nar Shaddaa, Hutt Cartel",
        "--instance-match", "SW_HuttBadhiya", "StarwindRemasteredPatch.esm",
    )

    tc(
        work, "delete", "--type", "SCPT", "--exact-id", "SW_CourteCompScript",
        "StarwindRemasteredPatch.esm", "StarwindRemasteredV1.15.esm",
    )
    tc(
        work, "modify", "--type", "NPC_", "--exact-id", "sw_czerkacourte22",
        "--replace", "/SW_CourteCompScript//", "StarwindRemasteredPatch.esm",
    )

    tc(
        work, "delete", "--type", "CELL", "--instance-match", "SW_ShipQuester",
        "StarwindRemasteredV1.15.esm", "StarwindRemasteredPatch.esm",
    )

    tc(
        work, "delete",
        "--exact-id", "Nab_HeaviestJunk",
        "--exact-id", "passtheday",
        "--exact-id", "nab_byebye",
        "--exact-id", "dayispassed",
        "--exact-id", "mothball",
        "--exact-id", "NerevarAwakened ",
        "naboo.esp",
    )
    tc(work, "delete", "--sub-match", "Script:Nab_ByeBye", "naboo.esp")
    tc(work, "delete", "--sub-match", "Script:passtheday", "naboo.esp")
    tc(
        work, "delete", "--type", "CELL",
        "--instance-match", "MastIdx:4", "--instance-match", "MastIdx:5",
        "naboo.esp",
    )


def preprocess(work: Path, mode: str) -> None:
    if mode == "tsi":
        tsi_preprocess(work)
    common_preprocess(work, mode)


def do_sp_merge(work: Path) -> Path:
    mtm(work, "StarwindRemasteredPatch.esm", "StarwindRemasteredV1.15.esm")
    target = work / "Starwind-Solo.omwaddon"
    (work / "StarwindRemasteredV1.15.esm").rename(target)
    return target


def do_mp_merge(work: Path, include_mp_records: bool) -> Path:
    mtm(work, "bings race pack.esp", "Starwind Enhanced.esm")
    mtm(work, "Starwind Enhanced.esm", "StarwindRemasteredPatch.esm")
    mtm(work, "StarwindPlanExp.esp", "StarwindRemasteredPatch.esm")
    mtm(work, "alt_start1.5.esp", "StarwindRemasteredPatch.esm")
    mtm(work, "StarwindVvardenfell.esp", "StarwindRemasteredPatch.esm")
    mtm(work, "Starwind Community Patch Project.esp", "StarwindRemasteredPatch.esm")
    mtm(work, "naboo.esp", "StarwindRemasteredPatch.esm")
    mtm(work, "StarwindRemasteredPatch.esm", "StarwindRemasteredV1.15.esm")

    # Historical post-merge removal of deleted instances.
    tc(work, "delete", "--instance-match", "DELE", "StarwindRemasteredV1.15.esm")

    starwind = work / "Starwind.omwaddon"
    (work / "StarwindRemasteredV1.15.esm").rename(starwind)

    if include_mp_records:
        mtm(work, "StarwindMPRecords.esp", "Starwind.omwaddon")

    mtm(work, "PartyHats.esp", "Starwind.omwaddon")

    # Historical final enchantment normalization.
    temp = work / "Starwind.esp"
    starwind.rename(temp)
    tc(
        work, "modify", "--sub-no-match", "ENAM:",
        "--type", "CLOT", "--type", "ARMO", "--type", "WEAP",
        "--run", '$R->set({f=>"enchantment"}, 375)',
        "Starwind.esp",
    )
    temp.rename(starwind)
    return starwind


def do_standalone_merge(work: Path) -> Path:
    solo = do_sp_merge(work)
    mtm(work, "Starwind-Solo.omwaddon", "Minimal.esp")
    (work / "Minimal.esp").rename(work / "Starwind.esp")

    # Standalone-only source surgery: these inherited vanilla INFOs are known dead
    # in Starwind and otherwise cause addVanillaRefs to materialize dialogue whose
    # only remaining dependencies are vanilla factions we intentionally do not want.
    prune_dead_standalone_vanilla_dialogue(work)
    clear_standalone_region_sleep_creatures(work)

    # addVanillaRefs expects these names in cwd. They were already compiled here.
    log("Running recursive addVanillaRefs...")
    decouple = work / "decoupleLog.txt"
    with decouple.open("wb") as f:
        run([tool("addVanillaRefs")], cwd=work, stdout=f)

    result = work / "Starwind-Standalone.omwaddon"
    (work / "Starwind.esp").rename(result)
    return result


def build(mode: str, *, clean=True, include_mp_records=True) -> Path:
    build_dir, work, out, reports = mode_paths(mode)
    if clean and build_dir.exists():
        shutil.rmtree(build_dir)
    work.mkdir(parents=True, exist_ok=True)
    out.mkdir(parents=True, exist_ok=True)
    reports.mkdir(parents=True, exist_ok=True)

    compile_sources(mode, work, include_mp_records)
    preprocess(work, mode)

    if mode == "solo":
        result = do_sp_merge(work)
        out_name = "Starwind-Solo.omwaddon"
    elif mode == "standalone":
        result = do_standalone_merge(work)
        out_name = "Starwind-Standalone.omwaddon"
    elif mode == "tsi":
        result = do_mp_merge(work, include_mp_records)
        out_name = "Starwind-TSI.omwaddon"
    else:
        die(f"unknown build mode {mode}")

    final = out / out_name
    shutil.copy2(result, final)

    manifest = {
        "mode": mode,
        "output": str(final),
        "include_mp_records": include_mp_records,
        "historical_build_sh_transcribed": True,
        "standalone_dead_vanilla_faction_infos_pruned": (
            len(DEAD_VANILLA_FACTION_INFO_IDS) if mode == "standalone" else 0
        ),
        "note": (
            "Beast's Lair extraction is preserved exactly as uploaded build.sh: "
            "beastlair.esp is created/cleaned but not merged back. "
            "Standalone additionally prunes the audited dead vanilla faction INFO "
            "set from staged vanilla masters before addVanillaRefs."
        ),
    }
    (build_dir / "build-manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    log(f"built {final}")
    return final


# ---- closure audit ----

def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def load_plugin(path: Path):
    if path.suffix.lower() == ".json":
        return load_json(path)
    with tempfile.TemporaryDirectory() as td:
        out = Path(td) / "plugin.json"
        run([tool("tes3conv"), "-o", path, out], cwd=ROOT)
        return load_json(out)


def editor_id(r):
    if "id" in r:
        return str(r["id"])
    if r.get("type") == "MagicEffect":
        return str(r.get("effect_id", ""))
    if r.get("type") == "Skill":
        return str(r.get("skill_id", ""))
    return ""


def add_dep(out, value, src, kind):
    if value is None:
        return
    value = str(value)
    if value:
        out.append({
            "target": value.lower(),
            "target_original": value,
            "source_type": src[0],
            "source_id": src[1],
            "kind": kind,
        })


def dependencies(r, ordinal=0):
    out = []
    typ = r.get("type", "")
    src = (typ, editor_id(r) or r.get("name", "") or f"#{ordinal}")

    if typ == "Race":
        for x in r.get("spells", []):
            add_dep(out, x, src, "race.spells")
    elif typ == "SoundGen":
        add_dep(out, r.get("creature", ""), src, "soundgen.creature")
        add_dep(out, r.get("sound", ""), src, "soundgen.sound")
    elif typ == "MagicEffect":
        for k in ("bolt_sound", "cast_sound", "hit_sound", "area_sound",
                  "cast_visual", "bolt_visual", "hit_visual", "area_visual"):
            add_dep(out, r.get(k, ""), src, "magic_effect." + k)
    elif typ == "Region":
        add_dep(out, r.get("sleep_creature", ""), src, "region.sleep_creature")
        for pair in r.get("sounds", []):
            if pair:
                add_dep(out, pair[0], src, "region.sounds")
    elif typ == "Birthsign":
        for x in r.get("spells", []):
            add_dep(out, x, src, "birthsign.spells")
    elif typ == "Door":
        for k in ("script", "open_sound", "close_sound"):
            add_dep(out, r.get(k, ""), src, "door." + k)
    elif typ in {"MiscItem", "RepairItem", "Activator", "Apparatus",
                 "Lockpick", "Probe", "Ingredient", "Alchemy"}:
        add_dep(out, r.get("script", ""), src, typ.lower() + ".script")
    elif typ == "Weapon":
        add_dep(out, r.get("script", ""), src, "weapon.script")
        add_dep(out, r.get("enchanting", ""), src, "weapon.enchanting")
    elif typ == "Container":
        add_dep(out, r.get("script", ""), src, "container.script")
        for pair in r.get("inventory", []):
            if len(pair) > 1:
                add_dep(out, pair[1], src, "container.inventory")
    elif typ == "Creature":
        add_dep(out, r.get("script", ""), src, "creature.script")
        for pair in r.get("inventory", []):
            if len(pair) > 1:
                add_dep(out, pair[1], src, "creature.inventory")
        for x in r.get("spells", []):
            add_dep(out, x, src, "creature.spells")
        for pkg in r.get("ai_packages", []):
            if pkg.get("type") == "Activate":
                add_dep(out, pkg.get("target", ""), src, "creature.ai.activate")
        add_dep(out, r.get("sound", ""), src, "creature.sound")
    elif typ == "Bodypart":
        add_dep(out, r.get("race", ""), src, "bodypart.race")
    elif typ == "Light":
        add_dep(out, r.get("script", ""), src, "light.script")
        add_dep(out, r.get("sound", ""), src, "light.sound")
    elif typ == "Npc":
        add_dep(out, r.get("script", ""), src, "npc.script")
        for pair in r.get("inventory", []):
            if len(pair) > 1:
                add_dep(out, pair[1], src, "npc.inventory")
        for x in r.get("spells", []):
            add_dep(out, x, src, "npc.spells")
        for pkg in r.get("ai_packages", []):
            if pkg.get("type") == "Activate":
                add_dep(out, pkg.get("target", ""), src, "npc.ai.activate")
        for k in ("race", "class", "faction", "head", "hair"):
            add_dep(out, r.get(k, ""), src, "npc." + k)
    elif typ in {"Armor", "Clothing"}:
        low = typ.lower()
        add_dep(out, r.get("script", ""), src, low + ".script")
        add_dep(out, r.get("enchanting", ""), src, low + ".enchanting")
        for b in r.get("biped_objects", []):
            add_dep(out, b.get("male_bodypart", ""), src, low + ".male_bodypart")
            add_dep(out, b.get("female_bodypart", ""), src, low + ".female_bodypart")
    elif typ == "Book":
        add_dep(out, r.get("script", ""), src, "book.script")
        add_dep(out, r.get("enchanting", ""), src, "book.enchanting")
    elif typ == "LeveledItem":
        for pair in r.get("items", []):
            if pair:
                add_dep(out, pair[0], src, "leveled_item.items")
    elif typ == "LeveledCreature":
        for pair in r.get("creatures", []):
            if pair:
                add_dep(out, pair[0], src, "leveled_creature.creatures")
    elif typ == "Cell":
        add_dep(out, r.get("region", ""), src, "cell.region")
        for ref in r.get("references", []):
            add_dep(out, ref.get("id", ""), src, "cell.reference.id")
            for k in ("owner", "owner_global", "owner_faction", "key", "trap", "soul"):
                add_dep(out, ref.get(k, ""), src, "cell.reference." + k)
    elif typ == "DialogueInfo":
        for k in ("speaker_id", "speaker_race", "speaker_class",
                  "speaker_faction", "player_faction"):
            value = r.get(k, "")
            if (
                k in {"speaker_faction", "player_faction"}
                and str(value or "").casefold() in NO_FACTION_SENTINELS
            ):
                continue
            add_dep(out, value, src, "info." + k)
        # sound_path and generic filter.id deliberately excluded.
    elif typ == "Faction":
        for reaction in r.get("reactions", []):
            add_dep(out, reaction.get("faction", ""), src, "faction.reaction")
    return out


def known_source_records():
    records = []
    for rel in SOURCE_JSON.values():
        p = PLUGINS / rel
        if p.exists():
            records.extend(load_json(p))
    return records


def audit(path: Path, *, fail_on_unresolved=False):
    final_records = load_plugin(path)
    header = final_records[0] if final_records and final_records[0].get("type") == "Header" else {}
    all_ids = {editor_id(r).lower() for r in final_records if editor_id(r)}
    deps = []
    for i, r in enumerate(final_records):
        deps.extend(dependencies(r, i))

    hard = [d for d in deps if d["kind"] in HARD_KINDS and d["target"] not in all_ids]

    known = {
        (r.get("type", ""), editor_id(r).lower())
        for r in known_source_records() if editor_id(r)
    }
    for d in hard:
        d["source_provenance"] = (
            "KNOWN_INPUT"
            if (d["source_type"], d["source_id"].lower()) in known
            else "FINAL_ONLY_LIKELY_IMPORTED"
        )

    counts = {
        "records_including_header": len(final_records),
        "masters": len(header.get("masters", [])),
        "hard_unresolved_occurrences": len(hard),
        "hard_unresolved_unique_ids": len({d["target"] for d in hard}),
        "hard_unresolved_source_records": len({(d["source_type"], d["source_id"]) for d in hard}),
        "hard_unresolved_sources_likely_imported": len({
            (d["source_type"], d["source_id"]) for d in hard
            if d["source_provenance"] == "FINAL_ONLY_LIKELY_IMPORTED"
        }),
    }
    report = {
        "header": header,
        "counts": counts,
        "hard_by_kind": dict(Counter(d["kind"] for d in hard).most_common()),
        "hard_unresolved": hard,
        "hard_missing_ids": sorted({d["target"] for d in hard}),
    }

    reports = BUILD_ROOT / "reports"
    reports.mkdir(parents=True, exist_ok=True)
    out = reports / f"{path.stem}-closure-audit.json"
    out.write_text(json.dumps(report, indent=2), encoding="utf-8")

    print(json.dumps(counts, indent=2))
    print("\nHard unresolved by kind:")
    for k, v in report["hard_by_kind"].items():
        print(f"  {k:36} {v}")
    log(f"audit report: {out}")

    if fail_on_unresolved and hard:
        raise SystemExit(3)
    return report


def build_all(*, clean=True, fail_on_unresolved=False):
    solo = build("solo", clean=clean)
    standalone = build("standalone", clean=clean)
    audit(standalone, fail_on_unresolved=fail_on_unresolved)

    # Only build TSI when all historical TSI inputs are present.
    tsi_needed = required_for("tsi", include_mp_records=True)
    missing = [SOURCE_JSON[k] for k in tsi_needed if not source_present(k)]
    if missing:
        log("TSI build skipped; historical TSI-only inputs absent: " + ", ".join(sorted(missing)))
    else:
        build("tsi", clean=clean, include_mp_records=True)


def main():
    ap = argparse.ArgumentParser()
    sp = ap.add_subparsers(dest="cmd", required=True)

    sp.add_parser("doctor")

    b = sp.add_parser("build")
    b.add_argument("mode", choices=("solo", "standalone", "tsi"))
    b.add_argument("--no-clean", action="store_true")
    b.add_argument("--nomp", action="store_true",
                   help="TSI only: reproduce historical do_mp_merge nomp behavior")

    a = sp.add_parser("audit")
    a.add_argument("plugin", type=Path)
    a.add_argument("--fail-on-unresolved", action="store_true")

    aa = sp.add_parser("all")
    aa.add_argument("--no-clean", action="store_true")
    aa.add_argument("--fail-on-unresolved", action="store_true")

    args = ap.parse_args()

    if args.cmd == "doctor":
        raise SystemExit(doctor())
    if args.cmd == "build":
        build(args.mode, clean=not args.no_clean, include_mp_records=not args.nomp)
        return
    if args.cmd == "audit":
        audit(args.plugin, fail_on_unresolved=args.fail_on_unresolved)
        return
    if args.cmd == "all":
        build_all(clean=not args.no_clean, fail_on_unresolved=args.fail_on_unresolved)


if __name__ == "__main__":
    main()
