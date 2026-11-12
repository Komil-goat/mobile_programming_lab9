import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit(this._api) : super(const CartState());

  final CheckoutApi _api;
  final _history = <CartState>[];

  bool get canUndo => _history.isNotEmpty;

  void _change(CartState next) {
    if (next == state) return;
    _history.add(state);
    emit(next.copyWith(canUndo: true));
  }

  void add(Product product) {
    _change(state.copyWith(lines: state.lines.withProduct(product)));
  }

  void changeQty(String id, int delta) {
    _change(state.copyWith(lines: state.lines.changeQty(id, delta)));
  }

  void applyCoupon(String code) {
    final clean = code.trim().toUpperCase();
    if (clean == 'SAVE10') {
      _change(state.copyWith(coupon: 'SAVE10', couponError: null));
    } else {
      _change(state.copyWith(coupon: null, couponError: 'Invalid coupon code'));
    }
  }

  void undo() {
    if (_history.isEmpty) return;
    final previous = _history.removeLast();
    emit(previous.copyWith(canUndo: _history.isNotEmpty));
  }

  Future<void> checkout() async {
    if (state.lines.isEmpty ||
        state.checkoutStatus == CheckoutStatus.submitting) {
      return;
    }

    final total = state.total;
    emit(
      state.copyWith(
        checkoutStatus: CheckoutStatus.submitting,
        checkoutError: null,
        orderId: null,
      ),
    );

    try {
      final orderId = await _api.submit(total);
      if (isClosed) return;

      final before = state.copyWith(
        checkoutStatus: CheckoutStatus.idle,
        orderId: null,
        checkoutError: null,
      );
      _history.add(before);
      emit(
        state.copyWith(
          lines: const [],
          coupon: null,
          couponError: null,
          checkoutStatus: CheckoutStatus.success,
          orderId: orderId,
          canUndo: true,
        ),
      );
    } on CheckoutException catch (err) {
      if (isClosed) return;
      emit(
        state.copyWith(
          checkoutStatus: CheckoutStatus.failure,
          checkoutError: err.message,
        ),
      );
    }
  }

  @override
  void onChange(Change<CartState> change) {
    debugPrint(
      'cubit: total ${change.nextState.total}, coupon ${change.nextState.coupon}',
    );
    super.onChange(change);
  }
}
