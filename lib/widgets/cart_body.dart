import 'package:flutter/material.dart';

import '../models/cart.dart';

class CartBody extends StatefulWidget {
  const CartBody({
    super.key,
    required this.lines,
    this.coupon,
    this.couponError,
    required this.onAdd,
    required this.onQtyChanged,
    required this.onApplyCoupon,
  });

  final List<CartLine> lines;
  final String? coupon;
  final String? couponError;
  final void Function(Product) onAdd;
  final void Function(String productId, int delta) onQtyChanged;
  final void Function(String code) onApplyCoupon;

  @override
  State<CartBody> createState() => _CartBodyState();
}

class _CartBodyState extends State<CartBody> {
  final _couponController = TextEditingController();

  @override
  void didUpdateWidget(covariant CartBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coupon != widget.coupon) {
      if (widget.coupon != null) {
        _couponController.text = widget.coupon!;
      } else if (widget.couponError == null) {
        _couponController.clear();
      }
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
                    errorText: widget.couponError,
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
          child: widget.lines.isEmpty
              ? const Center(child: Text('Cart is empty'))
              : ListView(
                  children: [
                    for (final l in widget.lines)
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
      ],
    );
  }
}
