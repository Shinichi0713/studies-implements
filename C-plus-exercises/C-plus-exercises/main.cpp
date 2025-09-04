#include <stdio.h>
#include <stdlib.h>
#include <iostream>  // std::cout

#include "Card.h"
#include "Hand.h"

void main() {
    std::cout << "Hello, World!" << std::endl;

    Card c1{ 1, 0 };
    Card c2{ 13,1 };

    std::cout << "Card 1: rank=" << c1.rank << " suit=" << c1.suit << "\n";
    std::cout << "Card 2: rank=" << c2.rank << " suit=" << c2.suit << "\n";

    Hand handPlayer;

}

