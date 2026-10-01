# 职责: 用户类 __int__ 数值转换协议与错误类型
# 比对: same_output


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
