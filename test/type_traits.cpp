/* traits.cpp
Unit testing for traits
(C) 2016 Niall Douglas http://www.nedproductions.biz/


Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

#include "../include/boost/test/unit_test.hpp"
#include "../include/type_traits.hpp"

#include <array>
#include <initializer_list>
#include <vector>

BOOST_AUTO_TEST_SUITE(all)

BOOST_AUTO_TEST_CASE(works / type_traits, "Tests that the type traits work as intended")
{
  using namespace boost_lite::type_traits;
  static_assert(!is_sequence<char>::value, "");
  static_assert(!is_sequence<void>::value, "");
  static_assert(is_sequence<std::array<char, 2>>::value, "");
  static_assert(is_sequence<std::initializer_list<char>>::value, "");
  static_assert(is_sequence<std::vector<char>>::value, "");
  struct Foo
  {
    Foo() = delete;
    Foo(int) {}
    Foo(const Foo &) = delete;
    Foo(Foo &&) {}
  };
  static_assert(!is_sequence<Foo>::value, "");
  static_assert(is_sequence<std::vector<Foo>>::value, "");
}

BOOST_AUTO_TEST_SUITE_END()
