import 'package:bloc_test/bloc_test.dart';
import 'package:cart_four_ways/cubit/cart_cubit.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class FakeCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  late FakeCheckoutApi api;
  final keyboard = catalog.first;

  setUp(() => api = FakeCheckoutApi());

  blocTest<CartCubit, CartState>(
    'adds two keyboards and applies SAVE10',
    build: () => CartCubit(api),
    act: (cubit) {
      cubit.add(keyboard);
      cubit.add(keyboard);
      cubit.applyCoupon('SAVE10');
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

  blocTest<CartCubit, CartState>(
    'checkout keeps the lines when the card is declined',
    setUp: () {
      when(() => api.submit(any()))
          .thenThrow(const CheckoutException('Card declined'));
    },
    build: () => CartCubit(api),
    seed: () => CartState(lines: [CartLine(product: keyboard, qty: 1)]),
    act: (cubit) => cubit.checkout(),
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
}
