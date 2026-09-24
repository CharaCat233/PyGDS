# Feature: 用户类 __getitem__ / __setitem__ / __delitem__

class C:
    def __getitem__(self, i):
        return i * 2

print(C()[3])

class D:
    def __setitem__(self, k, v):
        print('set', k, v)

d = D()
d[1] = 'x'

class E:
    def __delitem__(self, k):
        print('del', k)

e = E()
del e[1]

class F:
    def __getitem__(self, i):
        if i == 0:
            return 'a'
        raise IndexError('no more')

f = F()
print(f[0])
try:
    print(f[1])
except IndexError as ex:
    print('IE:', ex)
