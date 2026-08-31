## Compatibility

- This game template is unreleased and pre-alpha. Treat pre-release behavior and internal
  implementation as changeable.
- Prefer clean, direct changes over compatibility layers, migrations, legacy fallbacks, shims, or
  wrappers.
- When replacing pre-release behavior, remove obsolete paths rather than preserving legacy branches.

## Getting started

When the root-level `.getting-started` sentinel exists, read `.agents/getting-started.md` before
planning or changing application code. It contains the one-time initialization guidance for
replacing the placeholder game.

## Git and integration

- Never switch the checked-out branch of the primary checkout without the user's explicit permission.
- Do not offer to switch the primary checkout's branch.
- In the primary checkout, make changes on the branch that is already checked out and use the normal
  local workflow to finish the work.
- Only linked worktrees may integrate into the local `dev` branch. In the primary checkout, do not
  run `agent-merge` or inspect, check out, update, merge, or rebase against the local `dev` branch.
- In a linked worktree, follow the repository's integration workflow only after the intended work is
  committed, verified, clean, and ready for manual testing.
- Do not integrate partial, exploratory, uncommitted, unverified, or dirty work.

## Architecture

- Flutter owns the application shell and safe-area handling.
- Flame owns the game loop, canvas rendering, resizing, and pointer input.
- Keep game rules free of Flutter and Flame types so they remain quick to unit test and easy to
  replace.

## Runtime inspection

- Debug builds expose versioned Flutter/Flame snapshots, an event journal, semantic commands, both
  framework trees, and game-loop controls through `tool/coreflame_inspect.dart`.
- Before debugging live state, driving the game, or adding state that agents must observe or control,
  read `.agents/rules/runtime-inspection.md` and prefer that protocol over screenshots, coordinate
  tapping, ad hoc logging, or private-field probing.
- Keep the inspection contract, CLI help, documentation, and focused tests synchronized with changes
  to observable state or agent-facing actions.
- Keep the runtime kernel, Flame host, VM bridge, and CLI game-independent. Put concrete state,
  events, commands, and dispatch behavior in the active game's `RuntimeInspectionAdapter`.

## Consistency

- Derive collections from their authoritative source when membership is already represented in code,
  configuration, schemas, or metadata. Avoid duplicating that membership in manually maintained
  lists that can drift as the source changes. Use a static collection only when it intentionally
  expresses a distinct subset, ordering, or policy, and make that intent clear nearby.
- Keep state ownership as narrow as practical.

## Third-party packages

- When a third-party package blocks or complicates the intended implementation, pause and explain the
  issue to the user before changing course.
- Present the viable options and obtain the user's approval before implementing a workaround,
  replacing the package, patching or forking it, or reimplementing its behavior.
- For every proposed workaround, explicitly describe its tradeoffs, including added complexity,
  maintenance burden, upgrade risk, behavioral differences, and any security or reliability concerns.

## Rulesets

Read the scoped rule below before making related changes:

- `.agents/rules/dart-code-quality.md` — read when creating, changing, reviewing, or refactoring Dart
  code in Flutter or other native platform projects.
- `.agents/rules/runtime-inspection.md` — read when inspecting or driving a running Coreflame build,
  debugging Flutter/Flame state, or changing state and actions exposed to agents.
