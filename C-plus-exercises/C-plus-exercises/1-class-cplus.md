## C++のクラスの定義
### ヘッダーファイル
クラスの名前、メンバ関数、メンバ変数などの「仕様」を書く

外部からクラスを使うときに必要な情報だけを提供する

__例：MyClass.hpp__
```c
#ifndef MYCLASS_HPP
#define MYCLASS_HPP

class MyClass {
public:
    MyClass();
    void sayHello();
private:
    int value;
};

#endif
```

実装ファイル（定義）

実際の関数の中身を書く

__例：MyClass.cpp__
```c
#include "MyClass.hpp"
#include <iostream>

MyClass::MyClass() : value(0) {}

void MyClass::sayHello() {
    std::cout << "Hello! Value is " << value << std::endl;
}
```

