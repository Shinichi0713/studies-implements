#pragma once
#include <vector>
#include "Card.h"
using namespace std;

class Hand
{
public:
	Hand();
	void Add(Card card);
	void ShowHand();
	void Remove(int index);
private:
	std::vector<Card> cards;  // © ƒNƒ‰ƒX‚Ìƒƒ“ƒo‚Æ‚µ‚ÄéŒ¾
};

