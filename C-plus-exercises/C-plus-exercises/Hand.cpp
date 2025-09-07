#include "Hand.h"
#include <iostream>
#include <vector>
#include <string>
#include "Card.h"

using namespace std;

// sonctructor
Hand::Hand() {
	cout << "hand is initialized." << endl;
}

void Hand::Add(Card card) {
	cards.push_back(card);
}

void Hand::ShowHand() {
	cout << "card of hand." << endl;
	for (int i=0; i<cards.size(); i++)
	{
		cout << std::to_string(i) + "th" << endl;
		cout << cards[i].rank << endl;
		cout << cards[i].suit << endl;
	}
}


// remove card
void Hand::Remove(int index) {
	if (index >= 0 && index < cards.size())
	cards.erase(cards.begin() + index); // インデックス1の要素を削除
}