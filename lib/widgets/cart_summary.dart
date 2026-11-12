import 'package:flutter/material.dart';

import '../models/cart.dart';

class CartSummaryCard extends StatelessWidget {
  const CartSummaryCard({
    super.key,
    required this.itemCount,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.checkoutStatus,
    required this.onCheckout,
  });

  final int itemCount;
  final double subtotal;
  final double discount;
  final double total;
  final CheckoutStatus checkoutStatus;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final busy = checkoutStatus == CheckoutStatus.submitting;
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _row('Items', '$itemCount'),
            _row('Subtotal', subtotal.toStringAsFixed(2)),
            _row('Discount', '-${discount.toStringAsFixed(2)}'),
            const Divider(),
            _row('Total', total.toStringAsFixed(2), bold: true),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: itemCount == 0 || busy ? null : onCheckout,
                child: busy
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
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
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
