#include "Class1.h"
#include <iostream>
using namespace std;

void Class1::greet()
{
	std::cout << "Hello World!" << std::endl;
}

void Class1::set(int number) {
	age = number;
}

int Class1::get() {
	return age;
}
