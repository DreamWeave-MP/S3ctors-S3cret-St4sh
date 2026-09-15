---
title: Paid For With Blood
description: Production bugs, failed optimizations, bad assumptions, and the rules they purchased.
weight: 50
template: docs/section.html
page_template: docs/page.html
sort_by: weight
extra:
  kind: guide
---

These are not hypothetical best practices.

A **Paid For With Blood** entry requires an actual wound: production bug, regression, crash, stale-state failure, performance cliff, misleading type assumption, reverted optimization, or architecture that became expensive enough to replace.

The useful structure is always the same:

1. What looked reasonable?
2. What actually happened?
3. Why?
4. What changed?
5. What rule survived?

The goal is not to make old code look stupid. Most dangerous mistakes are dangerous precisely because they looked reasonable when written.

Keep the scar. Skip the injury.

## Receipt convention

Important entries should make the trail easy to follow:

- **Experiment** — the change that tested a hypothesis;
- **Revert** — the failure or regression that rejected it;
- **Finding** — the evidence that identified the actual cause;
- **Current pattern** — the implementation or rule that survived.

When possible, link each commit, link the file at the relevant revision, and link the current implementation. A commit tells you what changed; a commit-pinned source link tells you what the code looked like when it changed.
