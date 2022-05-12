unsigned int Factorial(unsigned int number);

// -std=c++17
constexpr int AddOne(int n) {
  return [n] { return n + 1; }();
}
