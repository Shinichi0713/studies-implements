//#include <bits/stdc++.h>
//using namespace std;
//
//// ------------------------------
//// Simple Console Blackjack (C++17)
//// Player vs Dealer, Hit/Stand, dealer stands on all 17
//// ------------------------------
//
//struct Card {
//    int rank; // 1..13 (Ace=1, Jack=11, Queen=12, King=13)
//    int suit; // 0..3 (♠ ♥ ♦ ♣)
//};
//
//static const char* SUIT_UTF8[4] = { "\u2660", "\u2665", "\u2666", "\u2663" }; // ♠ ♥ ♦ ♣
//static const string RANK_STR[14] = {
//    "?", "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"
//};
//
//string cardToString(const Card& c) {
//    return RANK_STR[c.rank] + string(" ") + SUIT_UTF8[c.suit];
//}
//
//class Deck {
//public:
//    Deck(int decks = 1) { reset(decks); }
//
//    void reset(int decks = 1) {
//        cards.clear();
//        cards.reserve(52 * decks);
//        for (int d = 0; d < decks; ++d) {
//            for (int s = 0; s < 4; ++s) {
//                for (int r = 1; r <= 13; ++r) {
//                    cards.push_back(Card{ r, s });
//                }
//            }
//        }
//        shuffle();
//    }
//
//    void shuffle() {
//        std::random_device rd;
//        std::mt19937 rng(rd());
//        std::shuffle(cards.begin(), cards.end(), rng);
//        next = 0;
//    }
//
//    bool needsReshuffle(size_t threshold = 15) const {
//        return remaining() < threshold;
//    }
//
//    size_t remaining() const { return cards.size() - next; }
//
//    Card deal() {
//        if (next >= cards.size()) {
//            throw runtime_error("Deck is empty");
//        }
//        return cards[next++];
//    }
//
//private:
//    vector<Card> cards;
//    size_t next = 0;
//};
//
//class Hand {
//public:
//    void clear() { cards.clear(); }
//    void add(const Card& c) { cards.push_back(c); }
//
//    // Best blackjack value: Aces as 11 then downgrade to 1 as needed
//    int value() const {
//        int total = 0; int aces = 0;
//        for (auto& c : cards) {
//            if (c.rank == 1) { // Ace
//                total += 11; aces++;
//            }
//            else if (c.rank >= 10) {
//                total += 10;
//            }
//            else {
//                total += c.rank;
//            }
//        }
//        while (total > 21 && aces > 0) { total -= 10; aces--; }
//        return total;
//    }
//
//    bool isBlackjack() const { return cards.size() == 2 && value() == 21; }
//    bool isBust() const { return value() > 21; }
//
//    const vector<Card>& get() const { return cards; }
//
//private:
//    vector<Card> cards;
//};
//
//void printHand(const string& owner, const Hand& h, bool hideHole = false) {
//    cout << owner << ": ";
//    const auto& v = h.get();
//    for (size_t i = 0; i < v.size(); ++i) {
//        if (hideHole && i == 1) {
//            cout << "[Hidden]";
//        }
//        else {
//            cout << cardToString(v[i]);
//        }
//        if (i + 1 < v.size()) cout << ", ";
//    }
//    if (!hideHole) cout << "  (" << h.value() << ")";
//    cout << "\n";
//}
//
//bool askYesNo(const string& prompt) {
//    while (true) {
//        cout << prompt << " (y/n): ";
//        string s; getline(cin, s);
//        if (s.empty()) continue;
//        char c = tolower(static_cast<unsigned char>(s[0]));
//        if (c == 'y') return true;
//        if (c == 'n') return false;
//        cout << "Please enter 'y' or 'n'.\n";
//    }
//}
//
//char askHitStand() {
//    while (true) {
//        cout << "[H]it or [S]tand? ";
//        string s; getline(cin, s);
//        if (s.empty()) continue;
//        char c = tolower(static_cast<unsigned char>(s[0]));
//        if (c == 'h' || c == 's') return c;
//        cout << "Please enter 'H' or 'S'.\n";
//    }
//}
//
//int main() {
//    ios::sync_with_stdio(false);
//    cin.tie(nullptr);
//
//    cout << "==============================\n";
//    cout << "      Console Blackjack      \n";
//    cout << "   (Dealer stands on 17)     \n";
//    cout << "==============================\n\n";
//
//    Deck deck(1); // single deck
//    Hand player, dealer;
//
//    int wins = 0, losses = 0, pushes = 0;
//
//    while (true) {
//        if (deck.needsReshuffle()) {
//            cout << "-- Reshuffling deck --\n";
//            deck.reset(1);
//        }
//
//        player.clear();
//        dealer.clear();
//
//        // Initial deal
//        player.add(deck.deal());
//        dealer.add(deck.deal());
//        player.add(deck.deal());
//        dealer.add(deck.deal());
//
//        // Show hands (dealer hole card hidden)
//        printHand("Dealer", dealer, /*hideHole=*/true);
//        printHand("Player", player);
//        cout << "\n";
//
//        // Check for naturals
//        bool playerBJ = player.isBlackjack();
//        bool dealerBJ = dealer.isBlackjack();
//        if (playerBJ || dealerBJ) {
//            // Reveal dealer
//            printHand("Dealer", dealer, /*hideHole=*/false);
//            printHand("Player", player);
//            if (playerBJ && dealerBJ) {
//                cout << "Push! Both have Blackjack.\n";
//                pushes++;
//            }
//            else if (playerBJ) {
//                cout << "Blackjack! You win.\n";
//                wins++;
//            }
//            else {
//                cout << "Dealer has Blackjack. You lose.\n";
//                losses++;
//            }
//        }
//        else {
//            // Player turn
//            while (true) {
//                if (player.isBust()) break;
//                char action = askHitStand();
//                if (action == 'h') {
//                    Card c = deck.deal();
//                    player.add(c);
//                    cout << "You drew: " << cardToString(c) << "\n";
//                    printHand("Player", player);
//                }
//                else {
//                    break; // stand
//                }
//            }
//
//            if (player.isBust()) {
//                cout << "You bust. Dealer wins.\n";
//                losses++;
//            }
//            else {
//                // Dealer turn (reveal)
//                cout << "\nDealer reveals...\n";
//                printHand("Dealer", dealer, /*hideHole=*/false);
//                while (dealer.value() < 17) {
//                    Card c = deck.deal();
//                    dealer.add(c);
//                    cout << "Dealer draws: " << cardToString(c) << "\n";
//                    printHand("Dealer", dealer, /*hideHole=*/false);
//                }
//
//                // Determine outcome
//                if (dealer.isBust()) {
//                    cout << "Dealer busts. You win!\n";
//                    wins++;
//                }
//                else {
//                    int pv = player.value();
//                    int dv = dealer.value();
//                    if (pv > dv) { cout << "You win!\n"; wins++; }
//                    else if (pv < dv) { cout << "Dealer wins.\n"; losses++; }
//                    else { cout << "Push.\n"; pushes++; }
//                }
//            }
//        }
//
//        cout << "\nScore  W:" << wins << "  L:" << losses << "  P:" << pushes << "\n\n";
//        if (!askYesNo("Play another round?")) break;
//        cout << "\n";
//    }
//
//    cout << "Thanks for playing!\n";
//    return 0;
//}
