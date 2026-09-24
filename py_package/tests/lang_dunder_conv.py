# Feature: 用户类 __int__ / __float__ 转换协议

class C:
    def __int__(self):
        return 42
    def __float__(self):
        return 1.5

print(int(C()))
print(float(C()))

class D:
    def __int__(self):
        return 'bad'

try:
    int(D())
except TypeError:
    print('TE')
