import json
import re
import sys
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[1]
DATA_ROOT = ROOT / "data" / "schematics"
CONTENT_ROOT = ROOT / "content"
SUPPORTED_MODES = {"flow", "flow-support", "timeline"}
SUPPORTED_DIRECTIONS = {"vertical", "horizontal"}
SUPPORTED_EDGE_KINDS = {"normal", "support"}
SUPPORTED_KINDS = {
    "allocation",
    "boundary",
    "cache",
    "cod3x",
    "component",
    "engine",
    "external",
    "history",
    "input",
    "result",
    "scar",
    "service",
    "source",
    "state",
    "support",
    "tool",
}
SHORTCODE_PATTERN = re.compile(r'\{\{\s*schematic\([^)]*data_path\s*=\s*"([^"]+)"')


class SchematicValidation:
    def __init__(self):
        self.errors = []
        self.warnings = []

    def error(self, path, message):
        self.errors.append(f"{path}: {message}")

    def warning(self, path, message):
        self.warnings.append(f"{path}: {message}")


def validate_page(path, location, validation):
    if not isinstance(path, str) or not path.startswith("@/"):
        validation.error(location, "page links must use a Zola @/ path")
        return

    target = CONTENT_ROOT / path[2:]
    if not target.is_file():
        validation.error(location, f"page target does not exist: {path}")


def validate_url(url, location, validation):
    if not isinstance(url, str) or not url:
        validation.error(location, "url must be a non-empty string")
        return

    parsed = urlparse(url)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        validation.error(location, f"url is not an HTTP(S) URL: {url}")


def validate_link(link, location, validation):
    if not isinstance(link, dict):
        validation.error(location, "links must contain objects")
        return

    if not isinstance(link.get("label"), str) or not link["label"]:
        validation.error(location, "link label must be a non-empty string")

    targets = [key for key in ("page", "url") if key in link]
    if len(targets) != 1:
        validation.error(location, "link must contain exactly one page or url")
        return

    if targets[0] == "page":
        validate_page(link["page"], location, validation)
    else:
        validate_url(link["url"], location, validation)


def validate_schematic(path, validation, ids):
    try:
        data = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        validation.error(path, f"cannot read JSON: {error}")
        return

    if not isinstance(data, dict):
        validation.error(path, "top-level value must be an object")
        return

    schematic_id = data.get("id")
    if not isinstance(schematic_id, str) or not re.fullmatch(r"[a-z0-9][a-z0-9-]*", schematic_id):
        validation.error(path, "id must be lowercase kebab-case")
    elif schematic_id in ids:
        validation.error(path, f"duplicate diagram id: {schematic_id}")
    else:
        ids.add(schematic_id)

    mode = data.get("mode", "flow")
    if mode not in SUPPORTED_MODES:
        validation.error(path, f"unsupported mode: {mode}")

    relationships = data.get("relationships", "auto")
    if relationships not in {"auto", "always"}:
        validation.error(path, f"unsupported relationships mode: {relationships}")

    direction = data.get("direction", "vertical")
    if direction not in SUPPORTED_DIRECTIONS:
        validation.error(path, f"unsupported direction: {direction}")

    nodes = data.get("nodes")
    if not isinstance(nodes, list) or not nodes:
        validation.error(path, "nodes must be a non-empty array")
        return

    node_ids = set()
    for index, node in enumerate(nodes):
        location = f"{path} node {index + 1}"
        if not isinstance(node, dict):
            validation.error(location, "node must be an object")
            continue

        node_id = node.get("id")
        if not isinstance(node_id, str) or not re.fullmatch(r"[a-z0-9][a-z0-9-]*", node_id):
            validation.error(location, "id must be lowercase kebab-case")
        elif node_id in node_ids:
            validation.error(location, f"duplicate node id: {node_id}")
        else:
            node_ids.add(node_id)

        for field in ("title", "detail"):
            if field in node and not isinstance(node[field], str):
                validation.error(location, f"{field} must be plain text")

        role = node.get("role", "main")
        if role not in {"main", "support"}:
            validation.error(location, f"unsupported node role: {role}")

        if node.get("kind", "component") not in SUPPORTED_KINDS:
            validation.error(location, f"unsupported node kind: {node.get('kind')}")

        if "page" in node:
            validate_page(node["page"], location, validation)
        if "url" in node:
            validate_url(node["url"], location, validation)
        if "page" in node and "url" in node:
            validation.error(location, "node must not contain both page and url")

        links = node.get("links", [])
        if not isinstance(links, list):
            validation.error(location, "links must be an array")
        else:
            for link_index, link in enumerate(links):
                validate_link(link, f"{location} link {link_index + 1}", validation)

    support_nodes = [node for node in nodes if node.get("role", "main") == "support"]
    if mode == "flow-support" and not support_nodes:
        validation.error(path, "flow-support mode requires at least one support node")
    if mode == "flow" and support_nodes:
        validation.error(path, "support nodes require flow-support mode")

    edges = data.get("edges", [])
    if not isinstance(edges, list):
        validation.error(path, "edges must be an array")
        return

    for index, edge in enumerate(edges):
        location = f"{path} edge {index + 1}"
        if not isinstance(edge, dict):
            validation.error(location, "edge must be an object")
            continue

        for endpoint in ("from", "to"):
            if edge.get(endpoint) not in node_ids:
                validation.error(location, f"{endpoint} does not identify a node: {edge.get(endpoint)}")

        if "label" in edge and not isinstance(edge["label"], str):
            validation.error(location, "label must be plain text")

        if edge.get("kind", "normal") not in SUPPORTED_EDGE_KINDS:
            validation.error(location, f"unsupported edge kind: {edge.get('kind')}")

    legend = data.get("legend", [])
    if not isinstance(legend, list):
        validation.error(path, "legend must be an array")
    else:
        for index, item in enumerate(legend):
            location = f"{path} legend {index + 1}"
            if not isinstance(item, dict):
                validation.error(location, "legend item must be an object")
                continue
            if item.get("kind") not in SUPPORTED_KINDS:
                validation.error(location, f"unsupported legend kind: {item.get('kind')}")
            if not isinstance(item.get("label"), str) or not item["label"]:
                validation.error(location, "legend label must be a non-empty string")

    if mode in {"flow", "timeline"}:
        main_ids = [node["id"] for node in nodes if node.get("role", "main") == "main" and "id" in node]
        sequential_edges = {
            (edge.get("from"), edge.get("to"))
            for edge in edges
            if edge.get("kind", "normal") == "normal" and not edge.get("label")
        }
        expected_edges = set(zip(main_ids, main_ids[1:]))
        unexpected_edges = sequential_edges - expected_edges
        if unexpected_edges:
            validation.warning(path, "ordered flow contains a normal unlabeled edge outside adjacent main nodes")


def validate_shortcode_references(validation):
    referenced_paths = set()
    for path in CONTENT_ROOT.rglob("*.md"):
        try:
            content = path.read_text()
        except OSError as error:
            validation.error(path, f"cannot read Markdown: {error}")
            continue

        for data_path in SHORTCODE_PATTERN.findall(content):
            referenced_paths.add(data_path)
            target = ROOT / data_path
            if not target.is_file():
                validation.error(path, f"schematic data file does not exist: {data_path}")

    for data_path in referenced_paths:
        if not data_path.startswith("data/schematics/"):
            validation.error(data_path, "schematic data paths must live under data/schematics")


def main():
    validation = SchematicValidation()
    ids = set()
    paths = sorted(DATA_ROOT.glob("*.json"))
    if not paths:
        validation.error(DATA_ROOT, "no schematic data files found")

    for path in paths:
        validate_schematic(path, validation, ids)
    validate_shortcode_references(validation)

    for warning in validation.warnings:
        print(f"WARN {warning}")
    for error in validation.errors:
        print(f"ERROR {error}")

    if validation.errors:
        print(f"Schematic validation failed: {len(validation.errors)} error(s)")
        return 1

    print(f"Validated {len(paths)} schematics with unique IDs and resolvable references")
    return 0


if __name__ == "__main__":
    sys.exit(main())
