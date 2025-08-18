## C++�̃N���X�̒�`
### �w�b�_�[�t�@�C��
�N���X�̖��O�A�����o�֐��A�����o�ϐ��Ȃǂ́u�d�l�v������

�O������N���X���g���Ƃ��ɕK�v�ȏ�񂾂���񋟂���

__��FMyClass.hpp__
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

�����t�@�C���i��`�j

���ۂ̊֐��̒��g������

__��FMyClass.cpp__
```c
#include "MyClass.hpp"
#include <iostream>

MyClass::MyClass() : value(0) {}

void MyClass::sayHello() {
    std::cout << "Hello! Value is " << value << std::endl;
}
```

