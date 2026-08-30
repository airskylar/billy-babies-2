# Runtime inspection

Read this rule when inspecting or driving a running Coreflame build, diagnosing behavior that depends
on current Flutter or Flame state, or changing state and actions that AI agents need to observe or
control.

## Available interface

Coreflame debug builds expose a versioned JSON protocol over the Dart VM service. The repository CLI
at `tool/coreflame_inspect.dart` provides:

- semantic and visual game snapshots;
- a bounded, sequence-addressable event journal;
- revision-checked semantic actions for gameplay and settings;
- the Flame component tree and Flutter widget tree; and
- pause, resume, and deterministic step controls.

Copy the VM service URL printed by `flutter run` and pass it with `--uri` or set
`COREFLAME_VM_SERVICE_URL`. Treat the URL as ephemeral local access data: do not commit it or place it
in durable logs. Use `dart run tool/coreflame_inspect.dart --help` as the canonical command catalog
and the README for the human-facing quick start. The custom Coreflame extensions are available only
in debug builds.

## Inspection workflow

Prefer the narrowest structured query that answers the question:

1. Start with a semantic `snapshot` for authoritative match, feedback, lifecycle, viewport, scene,
   and stable component state.
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
- Read a fresh snapshot and pass its revision with `--expected-revision` before mutating state.
- Treat `staleRevision` as a signal to inspect the returned current snapshot and reconsider the
  action; do not blindly retry it.
- Use the snapshot returned by a command as the immediate postcondition, then use the event cursor
  when transition history also matters.
- Keep automated actions within the authority and task scope granted by the user. Runtime tooling
  changes how an action is expressed, not whether it is authorized.

## Maintaining observability

When an implementation task changes state that agents need to reason about or manipulate:

- derive snapshots from the authoritative state owner instead of maintaining a parallel debug model;
- preserve stable component IDs and derive parent/child relationships from the component tree;
- keep semantic snapshots compact and deterministic, placing geometry and continuously changing
  render details in visual snapshots;
- record meaningful state transitions with typed event kinds, action origins, and outcomes, without
  including credentials or private user data;
- expose agent mutations as strict typed commands with revision checks rather than arbitrary method
  invocation;
- keep state mutation in update, lifecycle, or semantic action paths so `render` remains observational;
- bump the snapshot schema version for an incompatible protocol change and update consumers; and
- update the CLI help, README, and focused snapshot/event/command tests when the public inspection
  contract changes.

For diagnosis-only tasks, report a material observability gap rather than expanding scope to change
the protocol without authorization.
