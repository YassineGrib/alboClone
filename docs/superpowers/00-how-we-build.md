# How we build this app

Source of truth for product intent: `albo-clone-technical-plan.md`.
Settled decisions live in `docs/superpowers/decisions/`.
Current stage: `docs/superpowers/STATUS.md`.

Do not write app code until the current stage says **execute** and a plan exists.

## The loop

```
Grill-me  →  Spec  →  Plan  →  Execute (TDD)  →  Review  →  next slice
```

One slice at a time. A slice is a vertical cut that a user can tap: API + Flutter screen + tests. Not "all of Laravel" then "all of Flutter".

## Stages

### 1. Grill
Trigger: `/grill-me` or "grill me on the plan".

Skill: `grilling`.

Output: `docs/superpowers/decisions/YYYY-MM-DD-<topic>.md`

Stop when the frontier is empty and the human confirms shared understanding.

### 2. Spec
Trigger: "write the spec" after grill is confirmed.

Skill: Superpowers `brainstorming` (architectural path, write-spec step only).

Output: `docs/superpowers/specs/YYYY-MM-DD-<slice>-design.md`

First slice only. Later slices get their own spec. Do not spec the whole Albo clone in one file.

### 3. Plan
Trigger: human approved the spec.

Skill: Superpowers `writing-plans`.

Output: `docs/superpowers/plans/YYYY-MM-DD-<slice>.md`

Bite-sized TDD tasks. Exact files, exact tests, exact commits.

### 4. Execute
Trigger: human picks subagent-driven or inline.

Skills:
- Superpowers `subagent-driven-development` (default) or `executing-plans`
- Superpowers `test-driven-development` on every feature/fix
- Superpowers `using-git-worktrees` before isolated feature work
- Flutter: `flutter-apply-architecture-best-practices`, `flutter-add-widget-test`
- UI: `impeccable` (`/impeccable polish` / `/impeccable critique`)
- Motion: `emil-design-eng`, `animate`, `review-animations`
- Taste: `design-taste-frontend` only when building marketing/web surfaces

Never skip the failing test. Never silently drop a save.

### 5. Review and finish
Skills: `requesting-code-review`, `verification-before-completion`, `finishing-a-development-branch`.

Bugs: `systematic-debugging` before proposing a fix.

## Suggested first slice

Matches the technical plan's day-to-day order:

1. Laravel Sanctum auth + `saves` CRUD (no parser yet)
2. Flutter login + save list + paste-a-URL field
3. Then `ParseSaveJob`, then share extension, then collections, then map, then sharing, then importers

Share sheet, maps, collab, and TikTok import are later slices. They are not v1 until grill + spec say they are.

## Copy-paste prompts

New chat, grilling:

```
/grill-me the plan in albo-clone-technical-plan.md using docs/superpowers/00-how-we-build.md
```

After grill is confirmed:

```
Write the spec for the first slice only. Follow docs/superpowers/00-how-we-build.md
```

After spec is approved:

```
Use writing-plans on the approved spec. First slice only.
```

After plan is saved:

```
Execute the plan with subagent-driven-development. TDD on every task.
```
