class Product {
  const Product({required this.id, required this.name, required this.price});
  final String id;
  final String name;
  final double price;
}

const catalog = [
  Product(id: 'p1', name: 'Keyboard', price: 49),
  Product(id: 'p2', name: 'Mouse', price: 25),
  Product(id: 'p3', name: 'Monitor', price: 199),
];

class CartLine {
  const CartLine({required this.product, required this.qty});
  final Product product;
  final int qty;
  double get subtotal => product.price * qty;
  CartLine copyWith({int? qty}) =>
      CartLine(product: product, qty: qty ?? this.qty);

  @override
  bool operator ==(Object other) =>
      other is CartLine && other.product.id == product.id && other.qty == qty;

  @override
  int get hashCode => Object.hash(product.id, qty);
}

/// Pure, style-independent cart logic. Every state holder calls these.
extension CartLines on List<CartLine> {
  List<CartLine> withProduct(Product p) {
    final i = indexWhere((l) => l.product.id == p.id);
    if (i == -1) return [...this, CartLine(product: p, qty: 1)];
    return [
      for (final l in this)
        l.product.id == p.id ? l.copyWith(qty: l.qty + 1) : l,
    ];
  }

  List<CartLine> without(String productId) => [
    for (final l in this)
      if (l.product.id != productId) l,
  ];

  List<CartLine> changeQty(String productId, int delta) {
    final line = where((l) => l.product.id == productId).firstOrNull;
    if (line == null) return this;
    final newQty = line.qty + delta;
    if (newQty <= 0) return without(productId);
    return [
      for (final l in this)
        l.product.id == productId ? l.copyWith(qty: newQty) : l,
    ];
  }

  double get subtotal => fold(0, (s, l) => s + l.subtotal);
  int get itemCount => fold(0, (s, l) => s + l.qty);
}

enum CheckoutStatus { idle, submitting, success, failure }

const _unset = Object();

class CartState {
  const CartState({
    this.lines = const [],
    this.coupon,
    this.couponError,
    this.checkoutStatus = CheckoutStatus.idle,
    this.orderId,
    this.checkoutError,
    this.canUndo = false,
  });

  final List<CartLine> lines;
  final String? coupon;
  final String? couponError;
  final CheckoutStatus checkoutStatus;
  final String? orderId;
  final String? checkoutError;
  final bool canUndo;

  int get itemCount => lines.itemCount;
  double get subtotal => lines.subtotal;
  double get discount => coupon == 'SAVE10' ? subtotal * 0.1 : 0;
  double get total => subtotal - discount;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartState &&
        _sameLines(lines, other.lines) &&
        coupon == other.coupon &&
        couponError == other.couponError &&
        checkoutStatus == other.checkoutStatus &&
        orderId == other.orderId &&
        checkoutError == other.checkoutError &&
        canUndo == other.canUndo;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(lines),
    coupon,
    couponError,
    checkoutStatus,
    orderId,
    checkoutError,
    canUndo,
  );

  CartState copyWith({
    List<CartLine>? lines,
    Object? coupon = _unset,
    Object? couponError = _unset,
    CheckoutStatus? checkoutStatus,
    Object? orderId = _unset,
    Object? checkoutError = _unset,
    bool? canUndo,
  }) {
    return CartState(
      lines: lines ?? this.lines,
      coupon: identical(coupon, _unset) ? this.coupon : coupon as String?,
      couponError: identical(couponError, _unset)
          ? this.couponError
          : couponError as String?,
      checkoutStatus: checkoutStatus ?? this.checkoutStatus,
      orderId: identical(orderId, _unset) ? this.orderId : orderId as String?,
      checkoutError: identical(checkoutError, _unset)
          ? this.checkoutError
          : checkoutError as String?,
      canUndo: canUndo ?? this.canUndo,
    );
  }
}

bool _sameLines(List<CartLine> a, List<CartLine> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
