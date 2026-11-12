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
