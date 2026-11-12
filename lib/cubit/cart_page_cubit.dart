import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import '../widgets/cart_summary.dart';
import 'cart_cubit.dart';

class CubitCartPage extends StatelessWidget {
  const CubitCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CartCubit(CheckoutApi()),
      child: const _CubitView(),
    );
  }
}

class _CubitView extends StatelessWidget {
  const _CubitView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · Cubit'),
        actions: const [_UndoButton()],
      ),
      body: BlocListener<CartCubit, CartState>(
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
    final cubit = context.read<CartCubit>();
    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (before, after) =>
          before.lines != after.lines ||
          before.coupon != after.coupon ||
          before.couponError != after.couponError,
      builder: (context, state) => CartBody(
        lines: state.lines,
        coupon: state.coupon,
        couponError: state.couponError,
        onAdd: cubit.add,
        onQtyChanged: cubit.changeQty,
        onApplyCoupon: cubit.applyCoupon,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CartCubit>();
    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (before, after) =>
          before.itemCount != after.itemCount ||
          before.subtotal != after.subtotal ||
          before.discount != after.discount ||
          before.total != after.total ||
          before.checkoutStatus != after.checkoutStatus,
      builder: (context, state) {
        debugPrint('cubit summary build: total ${state.total}');
        return CartSummaryCard(
          itemCount: state.itemCount,
          subtotal: state.subtotal,
          discount: state.discount,
          total: state.total,
          checkoutStatus: state.checkoutStatus,
          onCheckout: cubit.checkout,
        );
      },
    );
  }
}

class _UndoButton extends StatelessWidget {
  const _UndoButton();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CartCubit, CartState, bool>(
      selector: (state) => state.canUndo,
      builder: (context, canUndo) => IconButton(
        tooltip: 'Undo',
        onPressed: canUndo ? () => context.read<CartCubit>().undo() : null,
        icon: const Icon(Icons.undo),
      ),
    );
  }
}
