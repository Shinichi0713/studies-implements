// main.swift

// 1. 変数と定数
var message = "Hello, Swift!"  // 変数（再代入可能）
let pi = 3.14159               // 定数（再代入不可）

print("1. 変数と定数")
print("message = \(message)")
print("pi = \(pi)")

message = "こんにちは、Swift！"
print("変更後: \(message)")
print()

// 2. 型推論と明示的な型指定
var count: Int = 10            // 明示的に Int 型を指定
var name: String = "Taro"      // 明示的に String 型を指定

print("2. 型推論と明示的な型指定")
print("count: \(count), name: \(name)")
print("count の型: \(type(of: count))")
print("name の型: \(type(of: name))")
print()

// 3. 関数
func greet(person: String) -> String {
    return "こんにちは、\(person)さん！"
}

func add(_ a: Int, _ b: Int) -> Int {
    return a + b
}

print("3. 関数")
print(greet(person: "Yamada"))
print("3 + 5 = \(add(3, 5))")
print()

// 4. 条件分岐（if / switch）
let score = 85

print("4. 条件分岐")
if score >= 80 {
    print("成績: 優秀")
} else if score >= 60 {
    print("成績: 合格")
} else {
    print("成績: 不合格")
}

let grade: String
switch score {
case 90...100:
    grade = "A"
case 80..<90:
    grade = "B"
case 70..<80:
    grade = "C"
case 60..<70:
    grade = "D"
default:
    grade = "F"
}
print("スコア \(score) のグレードは \(grade) です")
print()

// 5. ループ（for / while）
print("5. ループ")
print("for-in ループ:")
for i in 1...5 {
    print("i = \(i)")
}

let fruits = ["りんご", "ばなな", "みかん"]
print("配列のループ:")
for fruit in fruits {
    print("- \(fruit)")
}

var n = 3
print("while ループ:")
while n > 0 {
    print("n = \(n)")
    n -= 1
}
print()

// 6. 構造体（値型）
struct Point {
    var x: Double
    var y: Double
    
    func description() -> String {
        return "(x: \(x), y: \(y))"
    }
}

var p1 = Point(x: 1.0, y: 2.0)
print("6. 構造体")
print("p1: \(p1.description())")

// 7. クラス（参照型）
class Person {
    var name: String
    var age: Int
    
    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
    
    func introduce() -> String {
        return "私は \(name)、\(age)歳です。"
    }
}

let person1 = Person(name: "鈴木", age: 25)
print("7. クラス")
print(person1.introduce())
print()

// 8. オプショナル型（nil を許容する型）
var optionalName: String? = "山田"
var optionalAge: Int? = nil

print("8. オプショナル型")
print("optionalName: \(optionalName ?? "nil")")
print("optionalAge: \(optionalAge ?? -1)")

// オプショナルバインディング（if-let）
if let name = optionalName {
    print("名前は \(name) です")
} else {
    print("名前はありません")
}

// 強制アンラップ（nilでないと確信できる場合のみ）
// print(optionalName!) // nil の場合はクラッシュするので注意
print()

// 9. 配列と辞書
var numbers = [1, 2, 3, 4, 5]
var userInfo: [String: Any] = [
    "name": "佐藤",
    "age": 30,
    "isStudent": false
]

print("9. 配列と辞書")
print("numbers: \(numbers)")
print("userInfo: \(userInfo)")

numbers.append(6)
userInfo["country"] = "Japan"

print("更新後 numbers: \(numbers)")
print("更新後 userInfo: \(userInfo)")
print()

// 10. エラーハンドリング（do-try-catch）
enum CalculationError: Error {
    case divisionByZero
}

func divide(_ a: Int, _ b: Int) throws -> Int {
    if b == 0 {
        throw CalculationError.divisionByZero
    }
    return a / b
}

print("10. エラーハンドリング")
do {
    let result = try divide(10, 2)
    print("10 / 2 = \(result)")
    
    // 0除除算を試す（エラー発生）
    // let errorResult = try divide(10, 0)
    // print(errorResult) // ここには到達しない
} catch CalculationError.divisionByZero {
    print("エラー: 0で割ることはできません")
} catch {
    print("予期せぬエラー: \(error)")
}
print()

// 11. クロージャ（無名関数）
let numbersToDouble = numbers.map { $0 * 2 }
print("11. クロージャ")
print("numbers: \(numbers)")
print("numbersToDouble: \(numbersToDouble)")

let sayHello = { (name: String) -> String in
    return "Hello, \(name)!"
}
print(sayHello("Swift"))
print()

// 12. プロトコルと準拠
protocol Describable {
    var description: String { get }
}

struct Book: Describable {
    var title: String
    var author: String
    
    var description: String {
        return "『\(title)』 by \(author)"
    }
}

print("12. プロトコルと準拠")
let book = Book(title: "Swift入門", author: "山田太郎")
print(book.description)

// メイン関数（@main エントリポイント）
@main
struct BasicSwiftExample {
    static func main() {
        // 上記のコードはすべてここで実行される
        print("=== Swift 基本サンプル実行開始 ===")
        // 各セクションの print が順に実行される
        print("=== 実行完了 ===")
    }
}