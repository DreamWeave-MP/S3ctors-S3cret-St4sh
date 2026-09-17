---
title: OpenCode Setup
description: Install Cod3x's project agents and skills, understand discovery, and invoke them without bloating every prompt.
weight: 10
extra:
  kind: guide
---

Cod3x ships its OpenCode definitions in `.opencode/`:

```text
.opencode/
├── agents/
│   ├── openmw-save-data-specialist.md
│   ├── openmw-ui-specialist.md
│   ├── openmw-vfs-specialist.md
│   └── tes3-plugin-analyst.md
└── skills/
    ├── cod3x-luals-stub-maintainer/
    │   └── SKILL.md
    ├── lua-public-api-curator/
    │   └── SKILL.md
    └── ...
```

In the St4sh source tree, the canonical copies live at `content/cod3x/.opencode`. Treat those files as the maintained source for the Cod3x pack.

OpenCode's own documentation is the authority for its configuration format and discovery behavior. See [Agents](https://opencode.ai/docs/agents/), [Agent Skills](https://opencode.ai/docs/skills/), and [Rules](https://opencode.ai/docs/rules/).

## Project-local installation

For a mod or Lua project, the simplest layout is:

```text
my-openmw-mod/
├── AGENTS.md
├── .opencode/
│   ├── agents/
│   │   └── ...selected Cod3x agents...
│   └── skills/
│       └── ...selected Cod3x skills...
├── scripts/
└── ...
```

Copy the definitions you want from Cod3x into the target project's `.opencode` directory, or symlink them if your development environment makes that convenient.

You do **not** need the whole pack in every repository. A UI-heavy mod may reasonably install the UI specialist and UI/context/lifecycle skills while ignoring TES3 plugin analysis. A content-heavy compatibility project may want the plugin, VFS, asset, persistence, and packaging pieces instead.

## Discovery is upward, not recursive

This matters when Cod3x is checked out inside a larger repository.

OpenCode discovers project `.opencode` definitions by walking upward from the active working directory toward the Git worktree. It does not recursively search every descendant directory looking for another project's `.opencode` folder.

Therefore:

```text
St4sh/
└── content/
    └── cod3x/
        └── .opencode/
```

means the Cod3x definitions are discoverable when your working directory is `content/cod3x` or below it, but they are not automatically active merely because you launched OpenCode from `St4sh/`.

For another project, put the definitions in that project's `.opencode`, install them globally, or otherwise place them in a location OpenCode actually discovers. Do not assume the nested Cod3x source directory is a global plugin installation.

## Global installation

OpenCode also supports global definitions under:

```text
~/.config/opencode/agents/
~/.config/opencode/skills/
```

Global installation is useful if you work on many OpenMW projects and want the same specialists everywhere. Project-local installation is safer when a repository needs a pinned or customized version of a skill.

A practical split is:

- install generic OpenMW specialists globally;
- keep project-specific `AGENTS.md` rules in the repository;
- keep modified or experimental skills project-local so the repository controls their behavior.

## Agents versus skills

An **agent** is a named assistant profile. Cod3x's four shipped agents are `mode: subagent`, so they are intended to be delegated focused work rather than replace your primary coding session.

A **skill** is reusable guidance the current agent can load when relevant. OpenCode advertises available skills by name and description and loads the full `SKILL.md` only when the skill is used. This keeps twelve specialist instruction sets out of the prompt until one is actually useful.

That difference is intentional:

- use an agent when the task benefits from a fresh specialist investigation;
- use a skill when the current task needs a narrow engineering contract;
- use both when a specialist agent should perform the work under one or more explicit Cod3x constraints.

## Invoking a specialist agent

You can ask the current agent to delegate explicitly:

```text
Use the openmw-ui-specialist subagent to review this menu rewrite for
context, root ownership, callback lifetime, and OpenMW-version assumptions.
```

OpenCode also supports invoking subagents by agent mention in interfaces that expose mentions:

```text
@openmw-vfs-specialist Find why textures/foo.dds resolves to the wrong file.
```

The filename is the important agent identifier. The shipped Cod3x IDs are listed in [Specialist Agents](@/cod3x/docs/ai/agents.md).

Because a subagent runs in a fresh child context, give it the concrete target: file, diff, error, reproduction, plugin, save, path, or question. Do not assume it inherited every incidental detail from a long primary conversation.

## Using a skill

Often you can simply describe the task and let OpenCode choose an advertised skill. For high-value review work, being explicit is better:

```text
Review this change using the openmw-lua-context-guard skill.
```

or:

```text
Use openmw-persistence-storage-auditor and check whether this state change
is safe for existing saves.
```

The skill ID is the directory name under `.opencode/skills/`. `SKILL.md` must keep the matching lower-case kebab-case name and a useful description so OpenCode can discover it correctly.

## Keep `AGENTS.md`

Skills do not replace repository instructions.

Your project should still have a short `AGENTS.md` describing things that are always true there: architecture, build/test commands, source-of-truth rules, formatting, generated files, release constraints, and links to deeper documentation. OpenCode loads those persistent rules as project context; skills supply narrower expertise on demand.

Cod3x's own [`AGENTS.md`](@/cod3x/docs/tooling/agents.md) philosophy is intentionally terse: the repository file says **what the agent must do**, while the field manual explains **why**.

## Permissions and troubleshooting

If an agent or skill does not appear:

1. confirm OpenCode is running from a directory whose ancestor chain includes the intended `.opencode`;
2. confirm agent files are under `.opencode/agents/`;
3. confirm skill files are exactly `SKILL.md` under `.opencode/skills/<skill-id>/`;
4. confirm the skill ID and frontmatter name agree;
5. check OpenCode's agent/skill permissions if your configuration restricts them;
6. check for another global or project definition using the same ID.

Do not debug discovery by pasting every skill body into `AGENTS.md`. That defeats the on-demand design and makes every request pay for irrelevant context.
