import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/riverpod/cart_notifier.dart';
import 'package:cart_four_ways/services/checkout_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class FakeCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  test('SAVE10 makes the total 88.2', () {
    final box = ProviderContainer();
    addTearDown(box.dispose);
    box.listen(cartProvider, (before, after) {});

    final cart = box.read(cartProvider.notifier);
    cart
      ..add(catalog.first)
      ..add(catalog.first)
      ..applyCoupon('SAVE10');

    expect(box.read(cartProvider).total, 88.2);
  });

  test('failed checkout keeps the lines', () async {
    final api = FakeCheckoutApi();
    when(() => api.submit(any()))
        .thenThrow(const CheckoutException('Card declined'));

    final box = ProviderContainer(
      overrides: [checkoutApiProvider.overrideWithValue(api)],
    );
    addTearDown(box.dispose);
    box.listen(cartProvider, (before, after) {});

    final cart = box.read(cartProvider.notifier);
    cart.add(catalog.first);
    await cart.checkout();

    final now = box.read(cartProvider);
    expect(now.checkoutStatus, CheckoutStatus.failure);
    expect(now.lines, isNotEmpty);
  });
}
