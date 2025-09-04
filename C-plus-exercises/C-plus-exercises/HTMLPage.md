# purpose

to make rehabilitation of c-code.
make c++ project.



## c++ black jack

if the case if rehabilitation, not difficult game is appropriate.
with chat-gpt, the recommend game is 'black jack'.

__advice__

```
1. ブラックジャック（21）

ルール: プレイヤーとディーラーにカードを配り、合計が21に近い方が勝ち。ただし21を超えるとバースト（負け）。

特徴:

カードの合計を計算するロジックが中心。

A（エース）の1または11の扱いを工夫するところが面白い。

難易度: 初心者向け（簡単に始められる）
```

### reference

implementation

https://qiita.com/fj91/items/16f3e8976d0552af5182

rule

https://bright777.com/rules_blackjack

### composition

__struct__

Card: the structure of card

__class__

1. Deck


2. Hand

vector: Card, which player holds.

printHand: show the hands

returnValue: count the value of cards

askYesNo: choice discard or decide

replaceCard: replace card







