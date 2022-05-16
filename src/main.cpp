#include <iostream>
#include <ostream>

#include "hidden.h"
#include "image.hpp"

int main()
{
    std::cout << "Hello world!" << std::endl;
    std::cout << hidden << std::endl;

    size_t const width = 32;
    size_t const height = 32;

    std::ofstream file("generated.png", std::ios::binary);
    pixel_generator generator(width, height);
    generator.write(file);
}
