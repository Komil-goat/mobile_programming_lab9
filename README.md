# Lab Notes

Why is CartLine immutable with copyWith instead of a mutable qty?

A CartLine is a value. Changing it creates a new line, so old state stays old. If we mutate qty, every place sharing that line changes too, including tests and old states. copyWith changes just qty and leaves the rest. It also lets state libraries see that something changed.

Which of the four styles would still work with mutation, and why is that a trap?

setState still works with mutation because setState always rebuilds. The trap is that this teaches you mutating is fine. Riverpod, Cubit, and Bloc compare old and new state. If you mutate the same object, they think nothing changed and do not update the screen. Then you get a stale UI with no error.

Why does CartBody take callbacks instead of importing a provider or a bloc?

CartBody only shows the cart. The page gives it lines and tells it what to do when a user adds or removes. So the same widget works for all four styles, and it is easy to test without provider wrappers. If it imported Riverpod or Bloc, it would be tied to one style.

Why would storing total be a bug waiting to happen?

The total is made from the lines and the coupon. If we store it, every add, remove, quantity change, and coupon change must also update it. Forget one place and the screen shows a wrong number. A getter always calculates from the current state, so it cannot go stale.

What happens without if (!mounted) return; after the await?

The page can be closed while checkout is running. Without the check, the code calls setState and uses context after the page is gone. That throws errors. The check stops the rest of the code when the page no longer exists.

After T4, how would a second page, like an order history page, read the cart? What would you have to change?

Right now the cart lives inside SetStateCartPage, so another page cannot see it. Move the cart state up to a shared owner above both pages, such as the app widget, and pass it and its callbacks down. Or put it in an InheritedWidget. If the second page only needs past orders, store those in a shared service instead.

After T5, where does _history live, and what happens to it on hot restart versus hot reload?

_history lives in the State object of SetStateCartPage, next to _state. Hot reload keeps the State object, so the history usually stays. Hot restart starts the app again, so the history is lost. It is also lost when the page is popped.
