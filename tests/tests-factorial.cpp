#include <catch2/catch.hpp>

#include <example/factorial.h>

TEST_CASE("Factorials are computed", "[factorial]")
{
    REQUIRE(Factorial(1) == 1);
    REQUIRE(Factorial(2) == 2);
    REQUIRE(Factorial(3) == 6);
    REQUIRE(Factorial(10) == 3628800);
}

TEST_CASE("One added", "[factorial]")
{
    REQUIRE(AddOne(1) == 2);
}

TEST_CASE("Leak", "[leak]")
{
    REQUIRE_NOTHROW(Leak());
}
