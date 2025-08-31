#pragma once
#ifndef CARD_H
#define CARD_H

#include <string>

class Card {
private:
    std::string suit; // スート (♠, ♥, ♦, ♣)
    int rank;         // 数字 (1〜13)

public:
    // コンストラクタ
    Card(std::string s, int r);

    // カードの情報を文字列で返す
    std::string toString() const;
};

#endif // CARD_H

