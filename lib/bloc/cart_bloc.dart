import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import 'cart_event.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc(this._api) : super(const CartState()) {
    on<CartProductAdded>(_onAdd);
    on<CartProductRemoved>(_onRemove);
    on<CartQtyChanged>(_onQtyChanged);
    on<CartCouponApplied>(_onCoupon);
    on<CartCheckoutRequested>(_onCheckout, transformer: droppable());
    on<CartUndone>(_onUndo);
  }

  final CheckoutApi _api;

  void _apply(CartEvent event, CartState next, Emitter<CartState> emit) {
    if (next == state) return;
    final history = event.isUndoable
        ? [...state.history, state.copyWith(history: const [])]
        : state.history;
    emit(next.copyWith(history: history, canUndo: history.isNotEmpty));
  }

  void _onAdd(CartProductAdded event, Emitter<CartState> emit) {
    _apply(
      event,
      state.copyWith(lines: state.lines.withProduct(event.product)),
      emit,
    );
  }

  void _onRemove(CartProductRemoved event, Emitter<CartState> emit) {
    _apply(
      event,
      state.copyWith(lines: state.lines.without(event.productId)),
      emit,
    );
  }

  void _onQtyChanged(CartQtyChanged event, Emitter<CartState> emit) {
    _apply(
      event,
      state.copyWith(
        lines: state.lines.changeQty(event.productId, event.delta),
      ),
      emit,
    );
  }

  void _onCoupon(CartCouponApplied event, Emitter<CartState> emit) {
    final clean = event.code.trim().toUpperCase();
    final next = clean == 'SAVE10'
        ? state.copyWith(coupon: 'SAVE10', couponError: null)
        : state.copyWith(coupon: null, couponError: 'Invalid coupon code');
    _apply(event, next, emit);
  }

  Future<void> _onCheckout(
    CartCheckoutRequested event,
    Emitter<CartState> emit,
  ) async {
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
      if (emit.isDone) return;

      final history = [...state.history, state.copyWith(history: const [])];
      emit(
        state.copyWith(
          lines: const [],
          coupon: null,
          couponError: null,
          checkoutStatus: CheckoutStatus.success,
          orderId: orderId,
          canUndo: true,
          history: history,
        ),
      );
    } on CheckoutException catch (err) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          checkoutStatus: CheckoutStatus.failure,
          checkoutError: err.message,
        ),
      );
    }
  }

  void _onUndo(CartUndone event, Emitter<CartState> emit) {
    if (state.history.isEmpty) return;
    final previous = state.history.last;
    final history = state.history.sublist(0, state.history.length - 1);
    emit(previous.copyWith(history: history, canUndo: history.isNotEmpty));
  }
}
