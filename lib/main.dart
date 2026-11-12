import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bloc/cart_page_bloc.dart';
import 'cubit/cart_page_cubit.dart';
import 'models/cart.dart';
import 'riverpod/cart_page_riverpod.dart';
import 'setstate/cart_page_setstate.dart';

class LabBlocObserver extends BlocObserver {
  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    final next = transition.nextState;
    if (next is CartState) {
      debugPrint(
        '${bloc.runtimeType}: ${transition.event.runtimeType} -> '
        '${next.checkoutStatus}, total ${next.total}',
      );
    }
  }
}

void main() {
  Bloc.observer = LabBlocObserver();
  runApp(const ProviderScope(child: CartFourWaysApp()));
}

class CartFourWaysApp extends StatelessWidget {
  const CartFourWaysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cart Four Ways',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart Four Ways')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () => _push(context, const SetStateCartPage()),
              child: const Text('SetState'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _push(context, const RiverpodCartPage()),
              child: const Text('Riverpod'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _push(context, const CubitCartPage()),
              child: const Text('Cubit'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _push(context, const BlocCartPage()),
              child: const Text('Bloc'),
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}
