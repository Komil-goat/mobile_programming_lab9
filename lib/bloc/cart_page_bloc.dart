import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import '../widgets/cart_summary.dart';
import 'cart_bloc.dart';
import 'cart_event.dart';

class BlocCartPage extends StatelessWidget {
  const BlocCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CartBloc(CheckoutApi()),
      child: const _BlocView(),
    );
  }
}

class _BlocView extends StatelessWidget {
  const _BlocView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · Bloc'),
        actions: const [_UndoButton()],
      ),
      body: BlocListener<CartBloc, CartState>(
        listenWhen: (before, after) =>
            before.checkoutStatus != after.checkoutStatus,
        listener: (context, state) {
          if (state.checkoutStatus == CheckoutStatus.success) {
            final orderId = state.orderId;
            if (orderId == null) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentMaterialBanner()
              ..showSnackBar(SnackBar(content: Text('Order $orderId placed')));
          } else if (state.checkoutStatus == CheckoutStatus.failure) {
            final message = state.checkoutError ?? 'Checkout failed';
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
        },
        child: const Column(
          children: [
            Expanded(child: _CartView()),
            _SummaryCard(),
          ],
        ),
      ),
    );
  }
}

class _CartView extends StatelessWidget {
  const _CartView();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CartBloc>();
    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (before, after) =>
          before.lines != after.lines ||
          before.coupon != after.coupon ||
          before.couponError != after.couponError,
      builder: (context, state) => CartBody(
        lines: state.lines,
        coupon: state.coupon,
        couponError: state.couponError,
        onAdd: (product) => bloc.add(CartProductAdded(product)),
        onQtyChanged: (id, delta) => bloc.add(CartQtyChanged(id, delta)),
        onApplyCoupon: (code) => bloc.add(CartCouponApplied(code)),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CartBloc>();
    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (before, after) =>
          before.itemCount != after.itemCount ||
          before.subtotal != after.subtotal ||
          before.discount != after.discount ||
          before.total != after.total ||
          before.checkoutStatus != after.checkoutStatus,
      builder: (context, state) {
        debugPrint('bloc summary build: total ${state.total}');
        return CartSummaryCard(
          itemCount: state.itemCount,
          subtotal: state.subtotal,
          discount: state.discount,
          total: state.total,
          checkoutStatus: state.checkoutStatus,
          onCheckout: () => bloc.add(const CartCheckoutRequested()),
        );
      },
    );
  }
}

class _UndoButton extends StatelessWidget {
  const _UndoButton();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CartBloc, CartState, bool>(
      selector: (state) => state.canUndo,
      builder: (context, canUndo) => IconButton(
        tooltip: 'Undo',
        onPressed: canUndo
            ? () => context.read<CartBloc>().add(const CartUndone())
            : null,
        icon: const Icon(Icons.undo),
      ),
    );
  }
}
