import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../widgets/cart_body.dart';
import '../widgets/cart_summary.dart';
import 'cart_notifier.dart';

class RiverpodCartPage extends ConsumerWidget {
  const RiverpodCartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartProvider.notifier);

    ref.listen(cartProvider.select((s) => s.coupon), (before, after) {
      debugPrint('coupon: $before -> $after');
    });

    ref.listen(cartProvider.select((s) => s.checkoutStatus), (before, after) {
      final now = ref.read(cartProvider);
      if (after == CheckoutStatus.success) {
        final orderId = now.orderId;
        if (orderId == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentMaterialBanner()
          ..showSnackBar(SnackBar(content: Text('Order $orderId placed')));
      } else if (after == CheckoutStatus.failure) {
        final message = now.checkoutError ?? 'Checkout failed';
        final messenger = ScaffoldMessenger.of(context);
        messenger
          ..hideCurrentMaterialBanner()
          ..showMaterialBanner(
            MaterialBanner(
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: messenger.hideCurrentMaterialBanner,
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · Riverpod'),
        actions: [_UndoButton(onUndo: cart.undo)],
      ),
      body: Column(
        children: [
          Expanded(
            child: _CartView(
              onAdd: cart.add,
              onQtyChanged: cart.changeQty,
              onApplyCoupon: cart.applyCoupon,
            ),
          ),
          _SummaryCard(onCheckout: cart.checkout),
        ],
      ),
    );
  }
}

class _CartView extends ConsumerWidget {
  const _CartView({
    required this.onAdd,
    required this.onQtyChanged,
    required this.onApplyCoupon,
  });

  final void Function(Product) onAdd;
  final void Function(String productId, int delta) onQtyChanged;
  final void Function(String code) onApplyCoupon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = ref.watch(
      cartProvider.select(
        (s) => (lines: s.lines, coupon: s.coupon, couponError: s.couponError),
      ),
    );

    return CartBody(
      lines: shown.lines,
      coupon: shown.coupon,
      couponError: shown.couponError,
      onAdd: onAdd,
      onQtyChanged: onQtyChanged,
      onApplyCoupon: onApplyCoupon,
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({required this.onCheckout});

  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picked = ref.watch(
      cartProvider.select(
        (s) => (
          itemCount: s.itemCount,
          subtotal: s.subtotal,
          discount: s.discount,
          total: s.total,
          status: s.checkoutStatus,
        ),
      ),
    );

    debugPrint('summary build: total ${picked.total}');

    return CartSummaryCard(
      itemCount: picked.itemCount,
      subtotal: picked.subtotal,
      discount: picked.discount,
      total: picked.total,
      checkoutStatus: picked.status,
      onCheckout: onCheckout,
    );
  }
}

class _UndoButton extends ConsumerWidget {
  const _UndoButton({required this.onUndo});

  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(canUndoProvider);
    return IconButton(
      tooltip: 'Undo',
      onPressed: enabled ? onUndo : null,
      icon: const Icon(Icons.undo),
    );
  }
}
