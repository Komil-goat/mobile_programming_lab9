import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';

final checkoutApiProvider = Provider<CheckoutApi>((ref) => CheckoutApi());

class CartNotifier extends Notifier<CartState> {
  final _history = <CartState>[];

  @override
  CartState build() => const CartState();

  bool get canUndo => _history.isNotEmpty;

  void _update(CartState next) {
    if (next == state) return;
    _history.add(state);
    state = next;
  }

  void add(Product product) {
    _update(state.copyWith(lines: state.lines.withProduct(product)));
  }

  void changeQty(String id, int delta) {
    _update(state.copyWith(lines: state.lines.changeQty(id, delta)));
  }

  void applyCoupon(String code) {
    final clean = code.trim().toUpperCase();
    if (clean == 'SAVE10') {
      _update(state.copyWith(coupon: 'SAVE10', couponError: null));
    } else {
      _update(state.copyWith(coupon: null, couponError: 'Invalid coupon code'));
    }
  }

  void undo() {
    if (_history.isEmpty) return;
    state = _history.removeLast();
  }

  Future<void> checkout() async {
    if (state.lines.isEmpty ||
        state.checkoutStatus == CheckoutStatus.submitting) {
      return;
    }

    final total = state.total;
    state = state.copyWith(
      checkoutStatus: CheckoutStatus.submitting,
      checkoutError: null,
      orderId: null,
    );

    final api = ref.read(checkoutApiProvider);
    try {
      final orderId = await api.submit(total);
      final before = state.copyWith(
        checkoutStatus: CheckoutStatus.idle,
        orderId: null,
        checkoutError: null,
      );
      _history.add(before);
      state = state.copyWith(
        lines: const [],
        coupon: null,
        couponError: null,
        checkoutStatus: CheckoutStatus.success,
        orderId: orderId,
      );
    } on CheckoutException catch (err) {
      state = state.copyWith(
        checkoutStatus: CheckoutStatus.failure,
        checkoutError: err.message,
      );
    }
  }
}

final cartProvider = NotifierProvider.autoDispose<CartNotifier, CartState>(
  CartNotifier.new,
);

final canUndoProvider = Provider.autoDispose<bool>((ref) {
  ref.watch(cartProvider);
  return ref.read(cartProvider.notifier).canUndo;
});
