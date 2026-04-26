# Specs

This directory holds the **specifications** for every non-trivial feature of Paamalai. We use spec-driven development (SDD): the spec is written before the code, and the code is judged against the spec.

## Folder structure

```
specs/
├── 0001-bible-reader/
│   ├── spec.md          # what & why
│   ├── design.md        # how
│   └── tasks.md         # ordered implementation steps
├── 0002-yearly-plan/
├── 0003-daily-devotion/
├── 0004-audio-reader/
└── 0000-master-v1.md    # the umbrella v1 spec that seeds the four above
```

## Workflow

1. **Open the spec.** If it doesn't exist for the change you're about to make, write it first.
2. **Update the spec when reality changes it.** If implementation reveals the spec is wrong, change the spec in the same PR. Drift between code and spec is a bug.
3. **Reference FR/NFR IDs in commits and PRs.** Example commit subject: `reader: highlight currently spoken verse [FR-AR-02]`.
4. **Acceptance criteria are the test plan.** A feature is done when the verification table in its `spec.md` passes — not when the code compiles.

## Spec file template

```markdown
# <Feature name>  (specs/000N-<slug>/spec.md)

## Context
Why this feature exists. The problem it solves.

## Personas
Which personas it serves (link to master spec §2).

## Functional requirements
FR-XX-NN — short title
- User story
- **Given/When/Then** acceptance criteria

## Non-functional requirements
NFR-XX-NN — title and target

## Data contracts
Tables, columns, API request/response shapes touched by this feature.

## Out of scope
What this feature is *not* doing in this iteration.

## Risks / open questions

## Verification
ID → manual or automated test that proves it.
```

`design.md` and `tasks.md` follow the structure used in this folder's existing files — see `0001-bible-reader/` for a reference.

## Master v1 spec

`0000-master-v1.md` is the umbrella spec for the whole v1 release. Per-feature specs in `0001..0004` carry the authoritative copies of their FRs; if there is ever a contradiction, the per-feature spec wins and the master is updated to match.
