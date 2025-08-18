#include <stdio.h>
#include <stdlib.h>
#include <iostream>

#include "Class1.h"

void main() {
	Class1 obj;
	obj.greet();
	obj.set(3);
	int age = obj.get();
	std::cout << age << std::endl;
}


