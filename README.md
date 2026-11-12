cart_four_ways

Why is CartLine immutable with copyWith instead of a mutable qty?

A CartLine is a value. Changing it creates a new line, so old state stays old. If we mutate qty, every place sharing that line changes too, including tests and old states. copyWith changes just qty and leaves the rest. It also lets state libraries see that something changed.

Which of the four styles would still work with mutation, and why is that a trap?

setState still works with mutation because setState always rebuilds. The trap is that this teaches you mutating is fine. Riverpod, Cubit, and Bloc compare old and new state. If you mutate the same object, they think nothing changed and do not update the screen. Then you get a stale UI with no error.

Why does CartBody take callbacks instead of importing a provider or a bloc?

CartBody only shows the cart. The page gives it lines and tells it what to do when a user adds or removes. So the same widget works for all four styles, and it is easy to test without provider wrappers. If it imported Riverpod or Bloc, it would be tied to one style.
