import 'package:bloc_test/bloc_test.dart';
import 'package:cart_four_ways/bloc/cart_bloc.dart';
import 'package:cart_four_ways/bloc/cart_event.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class FakeCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  late FakeCheckoutApi api;
  final keyboard = catalog.first;

  setUp(() => api = FakeCheckoutApi());

  blocTest<CartBloc, CartState>(
    'adds two keyboards and applies SAVE10',
    build: () => CartBloc(api),
    act: (bloc) {
      bloc
        ..add(CartProductAdded(keyboard))
        ..add(CartProductAdded(keyboard))
        ..add(const CartCouponApplied('SAVE10'));
    },
    expect: () => [
      CartState(lines: [CartLine(product: keyboard, qty: 1)], canUndo: true),
      CartState(lines: [CartLine(product: keyboard, qty: 2)], canUndo: true),
      CartState(
        lines: [CartLine(product: keyboard, qty: 2)],
        coupon: 'SAVE10',
        canUndo: true,
      ),
    ],
  );

  blocTest<CartBloc, CartState>(
    'checkout keeps the lines when the card is declined',
    setUp: () {
      when(() => api.submit(any()))
          .thenThrow(const CheckoutException('Card declined'));
    },
    build: () => CartBloc(api),
    seed: () => CartState(lines: [CartLine(product: keyboard, qty: 1)]),
    act: (bloc) => bloc.add(const CartCheckoutRequested()),
    expect: () => [
      CartState(
        lines: [CartLine(product: keyboard, qty: 1)],
        checkoutStatus: CheckoutStatus.submitting,
      ),
      CartState(
        lines: [CartLine(product: keyboard, qty: 1)],
        checkoutStatus: CheckoutStatus.failure,
        checkoutError: 'Card declined',
      ),
    ],
  );

  blocTest<CartBloc, CartState>(
    'drops extra checkout taps while one is running',
    setUp: () {
      when(() => api.submit(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        throw const CheckoutException('Card declined');
      });
    },
    build: () => CartBloc(api),
    seed: () => CartState(lines: [CartLine(product: keyboard, qty: 1)]),
    act: (bloc) {
      bloc
        ..add(const CartCheckoutRequested())
        ..add(const CartCheckoutRequested())
        ..add(const CartCheckoutRequested());
    },
    wait: const Duration(milliseconds: 100),
    expect: () => [
      CartState(
        lines: [CartLine(product: keyboard, qty: 1)],
        checkoutStatus: CheckoutStatus.submitting,
      ),
      CartState(
        lines: [CartLine(product: keyboard, qty: 1)],
        checkoutStatus: CheckoutStatus.failure,
        checkoutError: 'Card declined',
      ),
    ],
    verify: (bloc) {
      verify(() => api.submit(any())).called(1);
    },
  );
}
