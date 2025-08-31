#include "Card.h"

// コンストラクタ
Card::Card(std::string s, int r) : suit(s), rank(r) {}

// toStringメソッド
std::string Card::toString() const {
    static const std::string rankNames[14] =
    { "", "A", "2", "3", "4", "5", "6", "7",
     "8", "9", "10", "J", "Q", "K" };
    return suit + rankNames[rank];
}