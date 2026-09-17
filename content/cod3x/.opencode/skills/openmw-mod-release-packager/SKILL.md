---
name: openmw-mod-release-packager
description: "OpenMW mod release packaging, manifests, .omwscripts, plugins, assets, install docs, release notes, site metadata, and shipped-path coherence."
---

# OpenMW Mod Release Packager

Use this skill when work touches release archives, shipped file lists, manifests, install documentation, site/download metadata, or release notes for an OpenMW mod.

## Release Coherence Checks

- Inspect repository status/diff before packaging so local edits, generated files, and unrelated work are understood.
- Docs must match shipped paths exactly, including case, plugin names, `.omwscripts`, directories, asset paths, and archive layout.
- Preserve install instructions unless the actual package/config requirements changed.
- Verify the release includes every required plugin, script config, Lua file, asset, license, readme, and metadata file—and excludes scratch/local/generated-development files.
- Release notes must describe the shipped diff, not planned or unmerged behavior.
- Keep manifest metadata, package file lists, install docs, and site/download references consistent.
- Validate site/frontmatter syntax when a release updates published documentation.
- Do not mix unrelated application changes into a packaging-only task.
- Do not commit/tag/publish unless explicitly requested.

## Safety

- Prefer a dry-run manifest or staging directory before building a final archive.
- Never overwrite source plugins/assets merely to assemble a release.
- Treat generated binaries as outputs to verify, not proof that the package is correct.

## Validation

Run the repository's safe packaging dry-run, site check/build, path/reference audit, and release validation when available. Finish by comparing the staged/final file list with documentation and release notes.
