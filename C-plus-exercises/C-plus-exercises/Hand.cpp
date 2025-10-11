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
// index = 0 or 1
void Hand::Remove(int index) {
	if (index >= 0 && index < cards.size())
	cards.erase(cards.begin() + index); // インデックス1の要素を削除
}

void Hand::Replace() {
	cout << "どのカードを捨てますか?(0 or 1)";
	int indexRemove=-1;
	while (indexRemove < 0) {
		try {
			cin >> indexRemove;
			if (indexRemove == 0 || indexRemove == 1) break;
			else indexRemove = -1;
		}
		catch (const std::runtime_error& e) {
			indexRemove = -1;
			cout << "数値で指定してください" << endl;
		}
	}
	Hand::Remove(indexRemove);
	// request alternative card

}

// replace
void Hand::Ask() {
	// show
	Hand::ShowHand();
	char decide;
	// decide
	cout << "カード交換しますか？(y or n)";
	
	while (true) {
		cin >> decide;
		if (decide == 'y' || decide == 'n') break;
	}
	// replace
	if (decide == 'y') Hand::Replace();
		
}
