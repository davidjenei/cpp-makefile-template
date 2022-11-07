#include <iostream>
#include <list>
#include <ostream>
#include <stdlib.h>

#include "image.hpp"

int main()
{
    std::list<int> l = {7, 5, 16, 8};
    std::cout << "Hello world!" << std::endl;

    size_t const width = 32;
    size_t const height = 32;

    std::ofstream file("generated.png", std::ios::binary);
    pixel_generator generator(width, height);
    generator.write(file);
    int* i = new int{1};
    delete i;
    return *i;
}
