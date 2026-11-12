Lab notes

Why is CartLine immutable?
A line is a value. copyWith makes a new line and leaves the old one alone. If qty changed in place, old states, tests and widgets could change without anyone noticing. It also lets the state classes see a real change.

Which styles still work with mutation?
setState still works because it always rebuilds. That's the trap. Riverpod, Cubit and Bloc compare old and new state. Mutating the same object can look like no change, so the screen stays stale.

Why does CartBody take callbacks?
CartBody is just the UI. Data goes in, actions come out. All four versions can reuse it, and it can be tested without a provider or bloc wrapper.

Why not store total?
Every add, remove, quantity change and coupon change would have to update it too. Miss one and the total is wrong. A getter recalculates, so it can't go stale.

What happens without if (!mounted) return;?
The page can be popped while checkout is waiting. setState or context after that throws. The check stops the code once the page is gone.

How would an order history page read the cart?
It can't right now. The cart is private to SetStateCartPage. Lift it above both pages, or use an InheritedWidget. For past orders, a shared service is enough.

Where does _history live, and what happens on hot restart vs hot reload?
It's in the page's State object. Hot reload keeps it. Hot restart clears it, and popping the page clears it too.

Part 3 notes

Does copying the same coupon notify?
No. I added == and hashCode to CartState (and CartLine), so the new state is equal when nothing changed. Riverpod sees no change, so listeners don't run.

Where did I use ref.read?
Page: ref.read(cartProvider.notifier) to get add, changeQty, applyCoupon, checkout and undo.
Notifier: ref.read(checkoutApiProvider) inside checkout.
Listener: ref.read(cartProvider) to get the order id or error text.

Where did I use ref.watch?
The cart view watches the lines, coupon and couponError.
The summary card watches only the values it shows: item count, subtotal, discount, total and checkout status.
The small canUndoProvider also watches cartProvider so the Undo button updates. It's autoDispose too, so it doesn't keep the cart alive.

Why does the summary rebuild less?
It's a separate ConsumerWidget. Typing in the coupon field doesn't touch provider state. An invalid Apply only changes couponError, which the summary doesn't watch. A quantity change changes the numbers, so it rebuilds. In setState the whole page rebuilds.

Why no mounted check in Riverpod?
The notifier is not a widget, and there is no BuildContext or setState after the await. Riverpod removes the page's listeners when the page closes, so the callback doesn't run on a dead widget.

What happens to history when the page is popped?
cartProvider is autoDispose. When the page closes, its listeners go away and the provider is disposed. _history lives on CartNotifier, so it is destroyed too. Reopening starts fresh. In the tests I keep a listener open so the provider is not disposed mid-test.

Part 4 notes

What breaks if BlocProvider is inside CartBody?
CartBody would be tied to Cubit and could no longer be shared by the four versions. The summary, Undo button and listener are outside it, so they could not find the cubit because the provider is below them.

Riverpod equivalents:
BlocProvider -> a provider plus ProviderScope.
BlocBuilder -> ConsumerWidget or Consumer with ref.watch.
BlocListener -> ref.listen.
context.read -> ref.read.
buildWhen -> ref.watch(provider.select(...)).

What happens when the same coupon is applied twice?
The second state is equal to the first (CartState has == and hashCode), so it is skipped. There is no onChange print and no rebuild.

Why does the Cubit summary rebuild less?
Its BlocBuilder uses buildWhen on item count, subtotal, discount, total and status. Typing or a coupon error does not change those, so it skips.

What does emit do after close()?
It throws. The isClosed guard after the await stops that.

Why can't the Undo button use cubit.canUndo?
A getter on the cubit is not part of the emitted state, so BlocBuilder and BlocSelector never see it change. I put canUndo in CartState and select it.

What happens to the cubit and history when the page is popped?
BlocProvider closes the cubit, so its _history is gone. Reopening starts a fresh cart.

Part 5 notes

Where is the undo history?
It is a history list on CartState, not a field on the bloc. The Undo button selects canUndo from the state. I left history out of == because canUndo is the part the UI watches.

Which events are undoable?
Only cart edits: added, removed, qty changed and coupon applied. Checkout status changes and undo itself are not saved. A successful checkout clears the cart, so it saves one snapshot for that clear.

What does the transition log add?
It prints the event that caused the change. Cubit's onChange only shows the old and new state, so it does not say what the user did.

When is the event layer worth it?
It is better for checkout: droppable() drops extra taps and the log shows which event ran. It is overhead for simple add, remove or quantity changes, where Cubit methods are shorter.

Which style can drop duplicate taps declaratively?
Bloc, with transformer: droppable(). Riverpod and Cubit need a manual guard like if (status == submitting) return; setState needs the same guard or a disabled button.

What happens with three quick checkout taps?
Bloc runs the first and drops the rest. Cubit would run the first and its status guard would make the other calls return. After the await, the bloc checks emit.isDone before emitting again.

Final checkpoint

Where state lives and when it dies:
setState: in the page State, gone when the page is popped.
Riverpod: in the container, gone when autoDispose has no listeners.
Cubit: in the cubit owned by BlocProvider, gone when the page is popped.
Bloc: in the bloc owned by BlocProvider, gone when the page is popped.

Public mutation API:
Riverpod: set state on the Notifier.
Cubit: methods that call emit.
Bloc: add(event).
setState has none; the page just calls setState.

Mapping:
ref.watch -> BlocBuilder
ref.read -> context.read
ref.listen -> BlocListener
setState is its own thing: it marks the widget dirty and rebuilds it.

Why skip equal states:
They avoid rebuilds when nothing changed. CartState needs == and hashCode, and the lines need value equality too.

Guards after the checkout await:
setState: if (!mounted) return;
Riverpod: none.
Cubit: if (isClosed) return;
Bloc: if (emit.isDone) return;
They differ because each style owns state in a different place.
