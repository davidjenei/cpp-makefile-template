#include <example/factorial.h>

unsigned int Factorial(unsigned int number)
{
    return number <= 1 ? number : Factorial(number - 1) * number;
}

void Unused()
{
    char a[10];
    a[10] = 0;
    return;
}

void Leak()
{
    int* a = new int[10];
    a[0] = 11;
}
