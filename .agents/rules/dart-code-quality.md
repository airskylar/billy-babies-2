## Dart code quality

1. **Model closed domains with types.**
   Use enums, sealed classes, and exhaustive pattern matching for values with a known set of
   states or variants. Avoid magic strings, loosely typed maps, and other ad hoc representations
   inside application code. Convert to and from serialized forms only at system boundaries.

2. **Keep rendering pure.**
   UI-building code should describe the interface from existing state. It should not initialize,
   synchronize, or mutate state as a side effect of rendering.

3. **Represent workflows as explicit state.**
   When multiple booleans, nullable values, or flags collectively describe one process, replace
   them with a single state model. Make valid states explicit and invalid combinations
   unrepresentable.

4. **Make choices explicit at the call site.**
   Avoid positional booleans and other arguments whose meaning cannot be understood without
   reading the function definition. Prefer named parameters for simple options and enums or typed
   variants when the values represent distinct modes.

5. **Do not add structure for its own sake.**
   Apply these rules with the smallest abstraction necessary. Do not introduce classes, helpers,
   layers, or file splits merely to appear cleaner. Every abstraction should make the state, intent,
   or behavior easier to understand.

6. **Generate strict JSON models at serialized-data boundaries.**
   Use `json_serializable` with checked decoding and unrecognized-key rejection for app-owned JSON,
   platform-channel, WebView, and other untrusted serialized values. Mark nullable wire fields as
   required when omission differs from an explicit `null`. Keep small post-decode checks only for
   semantic constraints the generator cannot express, such as non-empty identifiers or finite
   numbers.
