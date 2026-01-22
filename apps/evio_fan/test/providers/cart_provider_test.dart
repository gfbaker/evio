import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_fan/providers/order_provider.dart';

void main() {
  late ProviderContainer container;
  
  setUp(() {
    container = ProviderContainer();
  });
  
  tearDown(() {
    container.dispose();
  });

  group('CartState', () {
    test('inicializa vacío', () {
      final state = CartState();
      
      expect(state.eventId, isNull);
      expect(state.items, isEmpty);
      expect(state.couponCode, isNull);
      expect(state.discountAmount, isNull);
      expect(state.isEmpty, true);
      expect(state.totalItems, 0);
    });

    test('copyWith actualiza campos correctamente', () {
      final initial = CartState();
      
      final withEvent = initial.copyWith(eventId: 'event-123');
      expect(withEvent.eventId, 'event-123');
      expect(withEvent.items, isEmpty);
      
      final withItems = withEvent.copyWith(items: {'tier-1': 2, 'tier-2': 1});
      expect(withItems.eventId, 'event-123');
      expect(withItems.items, {'tier-1': 2, 'tier-2': 1});
      expect(withItems.totalItems, 3);
      expect(withItems.isEmpty, false);
    });

    test('totalItems suma todas las cantidades', () {
      final state = CartState(
        items: {'tier-a': 5, 'tier-b': 3, 'tier-c': 2},
      );
      
      expect(state.totalItems, 10);
    });
  });

  group('CartNotifier', () {
    test('setEvent limpia carrito si cambia de evento', () {
      final notifier = container.read(cartProvider.notifier);
      
      // Agregar items al evento 1
      notifier.setEvent('event-1');
      notifier.addItem('tier-1', quantity: 3);
      
      expect(container.read(cartProvider).items, {'tier-1': 3});
      
      // Cambiar a evento 2 - debe limpiar
      notifier.setEvent('event-2');
      
      final state = container.read(cartProvider);
      expect(state.eventId, 'event-2');
      expect(state.items, isEmpty);
    });

    test('setEvent no limpia si es mismo evento', () {
      final notifier = container.read(cartProvider.notifier);
      
      notifier.setEvent('event-1');
      notifier.addItem('tier-1', quantity: 3);
      
      // Volver a setear mismo evento
      notifier.setEvent('event-1');
      
      expect(container.read(cartProvider).items, {'tier-1': 3});
    });

    test('addItem incrementa cantidad existente', () {
      final notifier = container.read(cartProvider.notifier);
      
      notifier.addItem('tier-1', quantity: 2);
      expect(container.read(cartProvider).items['tier-1'], 2);
      
      notifier.addItem('tier-1', quantity: 3);
      expect(container.read(cartProvider).items['tier-1'], 5);
    });

    test('removeItem decrementa cantidad', () {
      final notifier = container.read(cartProvider.notifier);
      
      notifier.addItem('tier-1', quantity: 5);
      notifier.removeItem('tier-1', quantity: 2);
      
      expect(container.read(cartProvider).items['tier-1'], 3);
    });

    test('removeItem elimina si llega a 0', () {
      final notifier = container.read(cartProvider.notifier);
      
      notifier.addItem('tier-1', quantity: 2);
      notifier.removeItem('tier-1', quantity: 2);
      
      expect(container.read(cartProvider).items.containsKey('tier-1'), false);
    });

    test('removeItem elimina si cantidad negativa', () {
      final notifier = container.read(cartProvider.notifier);
      
      notifier.addItem('tier-1', quantity: 2);
      notifier.removeItem('tier-1', quantity: 5);
      
      expect(container.read(cartProvider).items.containsKey('tier-1'), false);
    });

    test('setQuantity establece cantidad exacta', () {
      final notifier = container.read(cartProvider.notifier);
      
      notifier.setQuantity('tier-1', 10);
      expect(container.read(cartProvider).items['tier-1'], 10);
      
      notifier.setQuantity('tier-1', 3);
      expect(container.read(cartProvider).items['tier-1'], 3);
    });

    test('setQuantity con 0 elimina item', () {
      final notifier = container.read(cartProvider.notifier);
      
      notifier.setQuantity('tier-1', 5);
      notifier.setQuantity('tier-1', 0);
      
      expect(container.read(cartProvider).items.containsKey('tier-1'), false);
    });

    test('applyCoupon setea código y descuento', () {
      final notifier = container.read(cartProvider.notifier);
      
      notifier.applyCoupon('DESCUENTO20', 200000);
      
      final state = container.read(cartProvider);
      expect(state.couponCode, 'DESCUENTO20');
      expect(state.discountAmount, 200000);
    });

    test('clear resetea todo incluyendo cupón', () {
      final notifier = container.read(cartProvider.notifier);
      
      notifier.setEvent('event-1');
      notifier.addItem('tier-1', quantity: 5);
      notifier.addItem('tier-2', quantity: 3);
      notifier.applyCoupon('CODE', 1000);
      
      notifier.clear();
      
      final state = container.read(cartProvider);
      expect(state.eventId, isNull);
      expect(state.items, isEmpty);
      expect(state.couponCode, isNull);
      expect(state.discountAmount, isNull);
    });

    test('múltiples tiers se manejan independientemente', () {
      final notifier = container.read(cartProvider.notifier);
      
      notifier.setEvent('event-1');
      notifier.addItem('tier-vip', quantity: 2);
      notifier.addItem('tier-general', quantity: 4);
      notifier.addItem('tier-premium', quantity: 1);
      
      final state = container.read(cartProvider);
      
      expect(state.items['tier-vip'], 2);
      expect(state.items['tier-general'], 4);
      expect(state.items['tier-premium'], 1);
      expect(state.totalItems, 7);
      
      // Modificar uno no afecta otros
      notifier.removeItem('tier-general', quantity: 2);
      
      expect(container.read(cartProvider).items['tier-vip'], 2);
      expect(container.read(cartProvider).items['tier-general'], 2);
      expect(container.read(cartProvider).items['tier-premium'], 1);
    });
  });
}
