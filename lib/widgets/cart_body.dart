import 'package:flutter/material.dart';

import '../models/cart.dart';

class CartBody extends StatefulWidget {
  const CartBody({
    super.key,
    required this.state,
    required this.onAdd,
    required this.onQtyChanged,
    required this.onApplyCoupon,
    required this.onCheckout,
  });

  final CartState state;
  final void Function(Product) onAdd;
  final void Function(String productId, int delta) onQtyChanged;
  final void Function(String code) onApplyCoupon;
  final VoidCallback onCheckout;

  @override
  State<CartBody> createState() => _CartBodyState();
}

class _CartBodyState extends State<CartBody> {
  final _couponController = TextEditingController();

  @override
  void didUpdateWidget(covariant CartBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.coupon != widget.state.coupon) {
      _couponController.text = widget.state.coupon ?? '';
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon() => widget.onApplyCoupon(_couponController.text);

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final p in catalog)
                  ActionChip(
                    label: Text('${p.name} · ${p.price.toStringAsFixed(0)}'),
                    onPressed: () => widget.onAdd(p),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  decoration: InputDecoration(
                    labelText: 'Coupon code',
                    errorText: state.couponError,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _applyCoupon(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _applyCoupon, child: const Text('Apply')),
            ],
          ),
        ),
        Expanded(
          child: state.lines.isEmpty
              ? const Center(child: Text('Cart is empty'))
              : ListView(
                  children: [
                    for (final l in state.lines)
                      ListTile(
                        key: ValueKey(l.product.id),
                        title: Text(l.product.name),
                        subtitle: Text(
                          '${l.qty} × ${l.product.price.toStringAsFixed(2)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Decrease',
                              icon: const Icon(Icons.remove),
                              onPressed: () =>
                                  widget.onQtyChanged(l.product.id, -1),
                            ),
                            SizedBox(
                              width: 24,
                              child: Text(
                                '${l.qty}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Increase',
                              icon: const Icon(Icons.add),
                              onPressed: () =>
                                  widget.onQtyChanged(l.product.id, 1),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _summaryRow('Items', '${state.itemCount}'),
                _summaryRow('Subtotal', state.subtotal.toStringAsFixed(2)),
                _summaryRow(
                  'Discount',
                  '-${state.discount.toStringAsFixed(2)}',
                ),
                const Divider(),
                _summaryRow(
                  'Total',
                  state.total.toStringAsFixed(2),
                  bold: true,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        state.lines.isEmpty ||
                            state.checkoutStatus == CheckoutStatus.submitting
                        ? null
                        : widget.onCheckout,
                    child: state.checkoutStatus == CheckoutStatus.submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Checkout'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
