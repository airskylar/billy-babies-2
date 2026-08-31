# Runtime inspection

Read this rule when inspecting or driving a running Coreflame build, diagnosing behavior that depends
on current Flutter or Flame state, or changing state and actions that AI agents need to observe or
control.

## Available interface

Coreflame debug builds expose a versioned JSON protocol over the Dart VM service. The repository CLI
at `tool/coreflame_inspect.dart` provides:

- semantic and visual game snapshots;
- a bounded, sequence-addressable event journal;
- a discoverable command manifest and revision-checked semantic actions;
- the Flame component tree and Flutter widget tree; and
- pause, resume, and deterministic step controls.

Copy the VM service URL printed by `flutter run` and pass it with `--uri` or set
`COREFLAME_VM_SERVICE_URL`. Treat the URL as ephemeral local access data: do not commit it or place it
in durable logs. Use `dart run tool/coreflame_inspect.dart --help` as the canonical command catalog
and the README for the human-facing quick start. Run `capabilities` before driving an unfamiliar or
newly replaced game. Every `capabilities`, `snapshot`, `events`, and `dispatch` response—and every
pushed Coreflame event—carries a top-level `sessionId` for the current game mount. If it changes,
discard cached revisions and event cursors before continuing. The custom Coreflame extensions are
available only in debug builds.

## Inspection workflow

Prefer the narrowest structured query that answers the question:

1. Start with a semantic `snapshot` for authoritative engine, viewport, stable component, and
   `game.state` data. Read the active game ID and schema version instead of assuming the demo shape.
2. Read `events` from the last observed sequence to understand transitions and their action origin.
   If a batch reports `truncated: true`, reacquire a full snapshot and continue after the batch's
   `latestSequence` rather than inferring the missing history.
3. Use `tree` for Flame ownership and `widget-tree` for the Flutter shell and widget composition.
4. Request a visual snapshot only when the task depends on bounds, transforms, hit targets, or
   animation progress.
5. Use `pause` and `step` when a frame-stable observation matters.

Use screenshots for rendered appearance, golden comparison, or evidence that structured state cannot
represent. Do not treat screenshots, coordinate tapping, ad hoc debug prints, or debugger reads of
private fields as the primary state interface when the protocol already exposes the answer.

## Driving the game

- Prefer `dispatch` actions over pointer coordinates unless the task specifically tests hit testing
  or gesture routing.
- Discover command names and parameter types with `capabilities`; pass game-defined parameters as
  `NAME=VALUE` arguments instead of assuming Tiny Tactics commands.
- Read a fresh snapshot and pass its revision with `--expected-revision` before mutating state.
- Treat `staleRevision` as a signal to inspect the returned current snapshot and reconsider the
  action; do not blindly retry it.
- Commands execute serially. Each result reports a `disposition` of `rejected`, `noChange`, or
  `applied`; use the returned snapshot as the completed postcondition, then use the event cursor when
  transition history also matters.
- An applied command that emits no state-changing game event receives a generic `commandApplied`
  fallback event. Unrelated events that occur while the command is pending do not fulfill this
  revision guarantee.
- A dispatch response keeps the session that accepted the command, and command-owned events are
  publishable only through that initiating session. If the game remounted or another mount replaced
  it while the command was running, discard the response instead of treating its snapshot as current.
- Keep automated actions within the authority and task scope granted by the user. Runtime tooling
  changes how an action is expressed, not whether it is authorized.

## Maintaining observability

When an implementation task changes state that agents need to reason about or manipulate:

- keep `runtime_inspection.dart`, `inspectable_flame_game.dart`, the VM bridge, and the CLI free of
  demo imports, state names, event kinds, and commands;
- put game-specific snapshots, typed event kinds, strict command parsing, and semantic dispatch in
  that game's inspection protocol and `RuntimeInspectionAdapter`;
- derive snapshots from the authoritative state owner instead of maintaining a parallel debug model;
- preserve stable component IDs and derive parent/child relationships from the component tree;
- keep semantic snapshots compact and deterministic, placing geometry and continuously changing
  render details in visual snapshots;
- record meaningful state transitions with typed event kinds, action origins, and outcomes, without
  including credentials or private user data;
- expose agent mutations as strict typed commands with revision checks rather than arbitrary method
  invocation;
- keep state mutation in update, lifecycle, or semantic action paths so `render` remains observational;
- bump the adapter's game schema version for an incompatible game-state change; bump the runtime
  protocol version only when the generic envelope changes; and
- update the CLI help, README, and focused snapshot/event/command tests when the public inspection
  contract changes.

For diagnosis-only tasks, report a material observability gap rather than expanding scope to change
the protocol without authorization.
