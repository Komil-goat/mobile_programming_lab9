import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';

class SetStateCartPage extends StatefulWidget {
  const SetStateCartPage({super.key});

  @override
  State<SetStateCartPage> createState() => _SetStateCartPageState();
}

class _SetStateCartPageState extends State<SetStateCartPage> {
  final _api = CheckoutApi();
  final _history = <CartState>[];
  CartState _state = const CartState();

  void _mutate(CartState next) {
    setState(() {
      _history.add(_state);
      _state = next;
    });
  }

  void _add(Product product) {
    _mutate(_state.copyWith(lines: _state.lines.withProduct(product)));
  }

  void _changeQty(String productId, int delta) {
    _mutate(_state.copyWith(lines: _state.lines.changeQty(productId, delta)));
  }

  void _applyCoupon(String input) {
    if (input.trim().toUpperCase() == 'SAVE10') {
      _mutate(_state.copyWith(coupon: 'SAVE10', couponError: null));
    } else {
      _mutate(
        _state.copyWith(coupon: null, couponError: 'Invalid coupon code'),
      );
    }
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() => _state = _history.removeLast());
  }

  Future<void> _checkout() async {
    if (_state.lines.isEmpty ||
        _state.checkoutStatus == CheckoutStatus.submitting) {
      return;
    }

    final total = _state.total;
    setState(() {
      _state = _state.copyWith(
        checkoutStatus: CheckoutStatus.submitting,
        checkoutError: null,
        orderId: null,
      );
    });

    try {
      final orderId = await _api.submit(total);
      if (!mounted) return;

      final cartBeforeCheckout = _state.copyWith(
        checkoutStatus: CheckoutStatus.idle,
        orderId: null,
        checkoutError: null,
      );
      setState(() {
        _history.add(cartBeforeCheckout);
        _state = _state.copyWith(
          lines: const [],
          coupon: null,
          couponError: null,
          checkoutStatus: CheckoutStatus.success,
          orderId: orderId,
        );
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentMaterialBanner()
        ..showSnackBar(SnackBar(content: Text('Order $orderId placed')));
    } on CheckoutException catch (error) {
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      setState(() {
        _state = _state.copyWith(
          checkoutStatus: CheckoutStatus.failure,
          checkoutError: error.message,
        );
      });

      messenger
        ..hideCurrentMaterialBanner()
        ..showMaterialBanner(
          MaterialBanner(
            content: Text(error.message),
            actions: [
              TextButton(
                onPressed: messenger.hideCurrentMaterialBanner,
                child: const Text('Dismiss'),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SetStateCartPage'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed: _history.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo),
          ),
        ],
      ),
      body: CartBody(
        state: _state,
        onAdd: _add,
        onQtyChanged: _changeQty,
        onApplyCoupon: _applyCoupon,
        onCheckout: _checkout,
      ),
    );
  }
}
