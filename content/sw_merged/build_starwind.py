#!/usr/bin/env python3
"""Build the definitive Starwind edition and its distributable split pair."""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path

import motherjungle_audit as legacy
import split_starwind


ROOT = Path(__file__).resolve().parent
BUILD_ROOT = ROOT / ".swbuild" / "definitive"
WORK = BUILD_ROOT / "work"
OUT = BUILD_ROOT / "out"
REPORTS = BUILD_ROOT / "reports"

INCLUDED_SOURCES = (
    "Morrowind", "Tribunal", "Bloodmoon", "Minimal", "V115", "Patch",
    "Bings", "Enhanced", "PlanExp", "AltStart", "CPP", "Naboo", "PartyHats",
)
EXCLUDED_SOURCES = ("MPRecords", "Vvardenfell")

MAIN_QUEST_ANCHORS = {
    ("Script", "SW_ShadeAttackFinaleScr"),
    ("Script", "SW_ShadeDroidArmyFinaleScr"),
    ("Script", "SW_ShadeScriptCantinaTat"),
    ("Script", "SW_ShadeScriptManaan1"),
    ("Script", "SW_ShadeScriptMedical"),
    ("Script", "SW_ShadeTowerScr"),
    ("Npc", "SW_ShadePre"),
    ("Npc", "SW_ShadeManaan1"),
    ("Npc", "SW_ShadeMedicalTat"),
    ("Npc", "SW_ShadeTower"),
    ("Npc", "SW_ShipQuester"),
    ("Dialogue", "SW_PreTaris"),
    ("Dialogue", "SW_TarisChap1"),
    ("Dialogue", "SW_TarisChap1-2"),
    ("Dialogue", "SW_TarisChapX3-2"),
    ("Dialogue", "SW_TarisChapX3-3"),
    ("Dialogue", "SW_ShipOwn"),
}
MAIN_QUEST_CELL_REFERENCE_ANCHORS = {
    "SW_ShipQuester",
}


def source_manifest() -> dict:
    sources = {}
    for key in INCLUDED_SOURCES:
        path = legacy.src_json(key)
        sources[key] = {
            "path": str(path),
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        }
    return {"included": sources, "excluded": list(EXCLUDED_SOURCES)}


def compile_sources() -> None:
    missing = [legacy.SOURCE_JSON[key] for key in INCLUDED_SOURCES
               if not legacy.source_present(key)]
    if missing:
        raise RuntimeError("missing definitive source JSON: " + ", ".join(sorted(missing)))

    for key in INCLUDED_SOURCES:
        source = legacy.src_json(key)
        destination = WORK / legacy.BINARY_NAME[key]
        legacy.run([legacy.tool("tes3conv"), "-o", source, destination], cwd=WORK)


def active_staged_plugins() -> list[Path]:
    """Return only current compiled inputs, not tes3cmd backup copies."""
    return [
        WORK / legacy.BINARY_NAME[key]
        for key in INCLUDED_SOURCES
        if (WORK / legacy.BINARY_NAME[key]).exists()
    ]


def run_source_hygiene() -> Path:
    report = REPORTS / "Starwind-definitive-dialogue-source-hygiene.json"
    subprocess.run(
        [
            sys.executable,
            str(ROOT / "dialogue_source_hygiene.py"),
            "--report", str(report),
        ],
        cwd=ROOT,
        check=True,
    )
    return report


def assert_main_quest(stage: str, paths: list[Path], checks: list[dict]) -> None:
    found = set()
    found_cell_references = set()
    for path in paths:
        if not path.exists():
            continue
        for record in legacy.load_plugin(path)[1:]:
            record_id = legacy.editor_id(record)
            if record_id:
                found.add((record.get("type", ""), record_id.casefold()))
            if record.get("type") == "Cell":
                found_cell_references.update(
                    str(reference.get("id", "")).casefold()
                    for reference in record.get("references", [])
                    if reference.get("id") and not reference.get("deleted")
                )
    missing = sorted(
        f"{record_type}:{record_id}"
        for record_type, record_id in MAIN_QUEST_ANCHORS
        if (record_type, record_id.casefold()) not in found
    )
    missing_references = sorted(
        reference_id
        for reference_id in MAIN_QUEST_CELL_REFERENCE_ANCHORS
        if reference_id.casefold() not in found_cell_references
    )
    check = {
        "stage": stage,
        "paths": [str(path) for path in paths],
        "missing": missing,
        "missing_cell_references": missing_references,
    }
    checks.append(check)
    REPORTS.mkdir(parents=True, exist_ok=True)
    (REPORTS / "main-quest-preservation.json").write_text(
        json.dumps(
            {
                "anchors": sorted(f"{kind}:{ident}" for kind, ident in MAIN_QUEST_ANCHORS),
                "cell_reference_anchors": sorted(MAIN_QUEST_CELL_REFERENCE_ANCHORS),
                "checks": checks,
            },
            indent=2,
        ) + "\n",
        encoding="utf-8",
    )
    if missing or missing_references:
        raise RuntimeError(
            f"main-quest preservation failed at {stage}: "
            f"records={missing}, cell_references={missing_references}"
        )


def preprocess_definitive_sources(checks: list[dict]) -> None:
    """Apply only reviewed Definitive integration cleanup.

    This deliberately does not call legacy.tsi_preprocess(): that function
    contains multiplayer substitutions, quest-instance removals, and other
    historical deployment policy that must not enter the Definitive edition.
    """
    legacy.common_preprocess(WORK, "definitive")

    # Bing's pack contributes reusable races/content but carries two known
    # dirty cells that are not part of the intended world.
    bings = WORK / "bings race pack.esp"
    bings_records = legacy.load_plugin(bings)
    orphan_bodyparts = [
        legacy.editor_id(record)
        for record in bings_records
        if (
            record.get("type") == "Bodypart"
            and str(record.get("race", "")).casefold() == "bng_mustafarian"
        )
    ]
    if orphan_bodyparts:
        args = ["delete", "--type", "BODY"]
        for bodypart_id in orphan_bodyparts:
            args.extend(["--exact-id", bodypart_id])
        args.append(bings.name)
        legacy.tc(WORK, *args)
    legacy.tc(WORK, "delete", "--type", "CELL", "--exterior", "bings race pack.esp")
    legacy.tc(
        WORK, "delete", "--type", "CELL", "--exact-id",
        "nar shaddaa, h.t. parnell's oddities", "bings race pack.esp",
    )

    # Alt Start's prison ship conflicts with the canonical opening sequence.
    legacy.tc(
        WORK, "delete", "--type", "CELL", "--exact-id", "Imperial Prison Ship",
        "alt_start1.5.esp",
    )

    # Naboo's old multiplayer DRM is not part of Definitive. Remove the
    # obsolete records and clear every attached script/reference coherently.
    legacy.tc(
        WORK, "delete",
        "--exact-id", "Nab_HeaviestJunk",
        "--exact-id", "passtheday",
        "--exact-id", "nab_byebye",
        "--exact-id", "dayispassed",
        "--exact-id", "mothball",
        "--exact-id", "NerevarAwakened ",
        "naboo.esp",
    )
    legacy.tc(WORK, "delete", "--sub-match", "Script:Nab_ByeBye", "naboo.esp")
    legacy.tc(WORK, "delete", "--sub-match", "Script:passtheday", "naboo.esp")
    legacy.tc(
        WORK, "delete", "--type", "CONT", "--exact-id", "ZE_Items",
        "--sub-match", "Nab_HeaviestJunk", "naboo.esp",
    )

    assert_main_quest(
        "after-definitive-preprocess",
        active_staged_plugins(),
        checks,
    )


def merge_definitive() -> Path:
    # This is the historical TSI graph, intentionally excluding Vvardenfell
    # and MPRecords from the definitive edition.
    legacy.mtm(WORK, "bings race pack.esp", "Starwind Enhanced.esm")
    for plugin in (
        "Starwind Enhanced.esm",
        "StarwindPlanExp.esp",
        "alt_start1.5.esp",
        "Starwind Community Patch Project.esp",
        "naboo.esp",
    ):
        legacy.mtm(WORK, plugin, "StarwindRemasteredPatch.esm")
    legacy.mtm(WORK, "StarwindRemasteredPatch.esm", "StarwindRemasteredV1.15.esm")

    canonical = WORK / "Starwind-Definitive.omwaddon"
    (WORK / "StarwindRemasteredV1.15.esm").rename(canonical)
    legacy.mtm(WORK, "PartyHats.esp", canonical.name)

    temp = WORK / "Starwind.esp"
    canonical.rename(temp)
    legacy.tc(
        WORK,
        "modify", "--sub-no-match", "ENAM:", "--type", "CLOT", "--type", "ARMO",
        "--type", "WEAP", "--run", '$R->set({f=>"enchantment"}, 375)', temp.name,
    )
    temp.rename(canonical)
    return canonical


def decouple(canonical: Path) -> tuple[Path, Path]:
    legacy.mtm(WORK, canonical.name, "Minimal.esp")
    starwind = WORK / "Starwind.esp"
    (WORK / "Minimal.esp").rename(starwind)

    legacy.prune_dead_standalone_vanilla_dialogue(WORK)
    legacy.clear_standalone_region_sleep_creatures(WORK)
    legacy.clear_standalone_exterior_residue(WORK)
    pre_add_vanilla = WORK / "Starwind-Definitive-pre-addVanilla.omwaddon"
    shutil.copy2(starwind, pre_add_vanilla)

    log_path = WORK / "decoupleLog.txt"
    with log_path.open("wb") as log:
        legacy.run([legacy.tool("addVanillaRefs")], cwd=WORK, stdout=log)

    # Tombstones have served their purpose during import and are not part of
    # the final distributable plugin.
    legacy.tc(WORK, "delete", "--instance-match", "DELE", starwind.name)
    final = WORK / "Starwind-Definitive.omwaddon"
    starwind.rename(final)
    return final, pre_add_vanilla


def run_dialogue_validation(final: Path, pre_add_vanilla: Path) -> Path:
    report = REPORTS / "Starwind-Definitive-dialogue-chain-audit.json"
    args = [
        sys.executable,
        str(ROOT / "dialogue_chain_audit.py"),
        "--standalone", str(final),
        "--starwind-solo", str(pre_add_vanilla),
        "--report", str(report),
        "--decouple-log", str(WORK / "decoupleLog.txt"),
        "--no-fail",
    ]
    for key in ("Morrowind", "Tribunal", "Bloodmoon"):
        args.extend(["--base", str(WORK / legacy.BINARY_NAME[key])])
    for key in INCLUDED_SOURCES:
        if key not in {"Morrowind", "Tribunal", "Bloodmoon", "Minimal"}:
            args.extend(["--provenance-source", str(legacy.src_json(key))])
    subprocess.run(args, cwd=ROOT, check=True)

    result = json.loads(report.read_text(encoding="utf-8"))
    summary = result["summary"]
    hard = {
        key: summary[key]
        for key in (
            "missing_dialogues", "extra_dialogues", "extra_dead_infos",
            "missing_live_infos", "engine_order_mismatches",
            "potentially_competing_inversions", "dialogue_content_mismatches",
            "info_content_mismatches", "standalone_orphan_infos",
        )
        if summary[key]
    }
    if hard:
        raise RuntimeError(f"definitive dialogue validation failed: {hard}")
    return report


def run_late_actor_provenance(final: Path) -> Path:
    report = REPORTS / "late-actor-provenance.json"
    subprocess.run(
        [
            sys.executable,
            str(ROOT / "late_actor_provenance.py"),
            "--log", str(WORK / "decoupleLog.txt"),
            "--standalone", str(final),
            "--report", str(report),
            "--markdown", str(REPORTS / "late-actor-provenance.md"),
            "--cleanup-script", str(REPORTS / "late-actor-provenance-cleanup.sh"),
        ],
        cwd=ROOT,
        check=True,
    )
    return report


def build(*, clean: bool, keep_work: bool, strict: bool) -> None:
    if clean and BUILD_ROOT.exists():
        shutil.rmtree(BUILD_ROOT)
    WORK.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    REPORTS.mkdir(parents=True, exist_ok=True)

    source_info = source_manifest()
    quest_checks: list[dict] = []
    hygiene_report = run_source_hygiene()
    compile_sources()
    assert_main_quest(
        "before-definitive-preprocess",
        active_staged_plugins(),
        quest_checks,
    )
    preprocess_definitive_sources(quest_checks)

    canonical = merge_definitive()
    assert_main_quest("after-canonical-merge", [canonical], quest_checks)
    final_work, pre_add_vanilla = decouple(canonical)
    final = OUT / "Starwind-Definitive.omwaddon"
    shutil.copy2(final_work, final)
    assert_main_quest("after-master-decoupling", [final], quest_checks)

    closure = legacy.audit(final, fail_on_unresolved=True)
    dialogue_report = run_dialogue_validation(final, pre_add_vanilla)
    late_actor_report = run_late_actor_provenance(final)
    split_report = split_starwind.split(
        final,
        OUT / "Star_Data.omwaddon",
        OUT / "Starwind.omwaddon",
        REPORTS / "starwind-split-report.json",
    )

    if strict:
        summary = json.loads(dialogue_report.read_text(encoding="utf-8"))["summary"]
        structural = {
            key: summary[key]
            for key in (
                "engine_order_mismatches", "standalone_physical_order_mismatches",
                "serialized_link_mismatches",
            )
            if summary[key]
        }
        if structural:
            raise RuntimeError(f"strict dialogue validation failed: {structural}")

    manifest = {
        "edition": "definitive",
        "included_sources": source_info["included"],
        "excluded_sources": source_info["excluded"],
        "output": str(final),
        "source_hygiene_report": str(hygiene_report),
        "closure_report": str(ROOT / ".swbuild" / "reports" / "Starwind-Definitive-closure-audit.json"),
        "dialogue_report": str(dialogue_report),
        "late_actor_provenance_report": str(late_actor_report),
        "split_report": str(REPORTS / "starwind-split-report.json"),
        "main_quest_guard_report": str(REPORTS / "main-quest-preservation.json"),
        "closure_counts": closure["counts"],
        "split_counts": {
            key: split_report[key]
            for key in (
                "source_records", "data_records", "content_records",
                "reconstruction_exact", "effective_record_mismatch_count",
                "data_to_content_dependency_count", "new_unresolved_dependency_count",
            )
        },
    }
    (BUILD_ROOT / "build-manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )

    if not keep_work:
        shutil.rmtree(WORK)
    print(json.dumps(manifest["split_counts"], indent=2))
    print(f"definitive output: {final}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--no-clean", action="store_true")
    parser.add_argument("--keep-work", action="store_true")
    parser.add_argument("--verbose", action="store_true", help="reserved for compatibility")
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()
    build(clean=not args.no_clean, keep_work=args.keep_work, strict=args.strict)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
