---
title: Good Designs
description: Design studies about reducing difficult systems to small, durable contracts.
weight: 25
template: docs/section.html
page_template: docs/page.html
sort_by: weight
extra:
  kind: guide
  suppress_section_links: true
---

Cod3x has a shelf for failures. It should also have a shelf for designs that worked unusually well.

These are **Design Studies**, not a catalog of patterns to cargo-cult. Each study starts with a problem that looks larger than the code that eventually solves it, then follows the reduction that made the solution composable. Some are **Design Genealogies**: they follow a small trick across projects until repeated requirements, failures, and reuse earn it a more general form.

The teaching order is deliberate:

1. explain the problem in plain English;
2. show the tempting complicated design;
3. show the smaller question the next layer actually needs to answer;
4. name the formal design principle only after the reader can see it;
5. return to the real implementation and its tradeoffs.

Concrete first. Formal second.

{{ learning_path(data_path="data/learning-paths/cod3x_good_designs.json") }}

The five-step path teaches the core instinct: make the question smaller, put work where it belongs, and do not add machinery until it earns its existence. The branches let readers choose depth without turning the section into assigned reading.

## All studies

| Study | The reduction |
| --- | --- |
| [Reduce the Problem](@/cod3x/docs/good-designs/reduce-the-problem.md) | Ask what the next layer actually needs instead of modeling everything the current layer knows. |
| [S3maphore Playlist Eligibility](@/cod3x/docs/good-designs/s3maphore-playlist-eligibility.md) | Playlist conflict resolution becomes an eligibility callback plus generic priority ordering. |
| [CamHelper](@/cod3x/docs/good-designs/cam-helper-extraction.md) | T4rg3t5 camera logic becomes a reusable interface after real consumers prove the boundary. |
| [ImageAtlas](@/cod3x/docs/good-designs/image-atlas-domain-concept.md) | Repeated frame arithmetic becomes a domain object with a small vocabulary. |
| [Local Handlers](@/cod3x/docs/good-designs/local-handlers.md) | Same-context synchronous observation stays local instead of becoming another engine event. |
| [Move Stable Work to the Cold Path](@/cod3x/docs/good-designs/cold-path-ordering.md) | Stable playlist order is established at load time instead of repeatedly during resolution. |
| [I.s3.lf](@/cod3x/docs/good-designs/s3lf-semantic-boundary.md) | Cache expensive engine-backed values once, bind the attached object once, and expose convenient table-shaped access. |

## Genealogies

| Genealogy | The shape of the evolution |
| --- | --- |
| [NullFunction to StateMachine](@/cod3x/docs/good-designs/state-machine-genealogy.md) | Empty callback → swappable handler → named states and explicit transition timing. |
| [Event-Driven S3maphore Resolution](@/cod3x/docs/good-designs/s3maphore-event-resolution.md) | Poll everything → identify invalidation events → pay for the cases event-driven state makes possible. |
| [PlaylistRules](@/cod3x/docs/good-designs/playlist-rules-private-machinery.md) | Semantic rule questions → shared cache helper → explicit invalidation → private machinery. |
| [ProtectedTable](@/cod3x/docs/good-designs/protected-table-genealogy.md) | Compose storage-backed settings, transient state, and methods → remove synchronization plumbing → harden the reusable boundary. |
| [Actor Scheduler](@/cod3x/docs/good-designs/actor-scheduler.md) | Unbounded actor scanning → bounded batches with an explicit freshness target. |
| [StaticCollection](@/cod3x/docs/good-designs/static-collection-representation.md) | Engine objects → data shaped for rules → incremental work with explicit stale-result authority. |
| [Delete Fake Objects](@/cod3x/docs/good-designs/delete-fake-objects.md) | Decorative constructors and nested shapes → ownership, lifetime, and state made explicit. |
| [Earned Shared Infrastructure](@/cod3x/docs/good-designs/earned-shared-infrastructure.md) | Specific solution → repeated use → extracted H3 contract. |

## More material

The same instinct appears elsewhere in the manual. [Generation counters](@/cod3x/docs/paid-for-with-blood/generation-counters.md) give deferred work one identity instead of trying to cancel every stale operation. [Static Switching System's pipeline boundary](@/static_switching_system/docs/concepts/pipelines.md) keeps two different kinds of replacement from becoming one ambiguous rule language. [H3UI](@/h3lp_yours3lf/docs/concepts/h3ui.md) is another promising study in keeping a reusable UI vocabulary above raw `openmw.ui` layout construction.

The point is not that every problem wants a predicate, a facade, a state machine, or a generation number. The point is to look for the smallest contract that preserves the decision the system actually has to make, then let reality—not taste—earn the next layer of machinery.
