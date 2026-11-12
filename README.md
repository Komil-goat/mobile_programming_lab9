# cart_four_ways

### Lab notes

## Why is `CartLine` immutable with `copyWith` instead of a mutable `qty`?

Because a `CartLine` is treated as a **value**, not as a little box that gets edited in place.

- Every state change produces a new line (and a new list), so the old state stays a real snapshot. That makes old/new comparisons meaningful, which is exactly what Riverpod, Cubit, and Bloc depend on.
- The same line can be held by more than one place: an old state object, a test, a widget, a debug log. If one place changes `qty`, all of them change at once, even though they think they still have the old value.
- `copyWith` makes the update explicit and small: change only `qty`, keep the rest. It also keeps working when the model gets more fields.
- It makes tests simpler: compare two states and you know exactly whether anything changed.

Mutation looks convenient, but it turns state changes into hidden side effects. Immutable lines keep the cart predictable.

## Which styles still "work" with mutation, and why is that a trap?

**`setState` still works with mutation.** Calling `setState(() {})` always asks Flutter to rebuild, no matter whether the object changed or not. So this "works" on screen:

```dart
lines.first.qty++; // mutating in place
setState(() {});
```

The other three rely on comparing old and new state:

- **Riverpod** uses `updateShouldNotify` (by default `previous != next`).
- **Cubit and Bloc** check `state == _state` inside `emit`.

If you mutate the same list or the same line and then set/emit that same object, they see "old == new" and do nothing. No rebuild, no error, just a stale screen.

That is the trap: the `setState` version teaches you that mutating state is fine, so you carry the habit into Riverpod, Cubit, or Bloc. There, the same habit silently stops working. The UI may keep showing old data while the cart object has already changed, which makes the bug confusing to find.

Mutation also rewrites "old" snapshots. If an old state still points at the same line you just changed, it no longer represents the past. Undo, logs, tests, and devtools become misleading.

You can technically mutate and then emit a freshly copied list, and it will work. But it only works because you copied something — so it is better to make copying the normal rule. That is what the immutable `CartLine` and `copyWith` do.

## Why does `CartBody` take callbacks instead of importing a provider or a bloc?

`CartBody` is a **presentational** widget. It shows the cart and reports user actions. It does not decide what happens next.

- Data goes in (`lines`), and actions go out (`onAdd`, `onRemove`). This is the usual "data down, events up" flow.
- The same `CartBody` works for all four versions: setState, Riverpod, Cubit, and Bloc. Only the page around it changes. That keeps the comparison fair — the UI is identical, only the state plumbing differs.
- It can be tested or previewed without wrapping it in a `ProviderScope` or `BlocProvider`. Just pass some lines and simple callbacks.
- If `CartBody` imported a provider or bloc, it would be tied to that one solution. The other three pages would need wrappers or a different widget, and the "same UI, different state management" idea would be lost.
- It also avoids context and lifecycle questions inside a shared widget. The page owns the state and the actions; the body only displays and calls back.
