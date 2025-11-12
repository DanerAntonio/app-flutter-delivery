import 'package:flutter_test/flutter_test.dart';

int sumar(int a, int b) => a + b;

void main() {
  test('Debe sumar correctamente dos números', () {
    expect(sumar(2, 3), 5);
  });
}
