import 'dart:math';

class Complex {
  final double real;
  final double imag;

  const Complex(this.real, this.imag);

  double abs() => sqrt(real * real + imag * imag);
  double magnitude() => sqrt(real * real + imag * imag);

  //creates the complex number e^(i*theta),
  //required for the FFT twiddle factors (Euler's formula: cos(theta) + i*sin(theta))
  static Complex expi(double theta) {
    return Complex(cos(theta), sin(theta));
  }

  Complex operator +(Complex b) => Complex(real + b.real, imag + b.imag);
  Complex operator -(Complex b) => Complex(real - b.real, imag - b.imag);

  Complex operator *(Complex b) =>
      Complex(real * b.real - imag * b.imag, real * b.imag + imag * b.real);
}