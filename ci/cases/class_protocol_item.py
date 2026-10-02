# 职责: 用户类 __getitem__ 下标读写删协议
# 比对: same_output


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

# 仅实现 __getitem__ 的对象支持 in (P1-70): 回退旧式迭代协议逐元素比对
class GetItemOnly:
    def __getitem__(self, i):
        if i > 2:
            raise IndexError
        return ["x", "y", "z"][i]

g = GetItemOnly()
print("y" in g, "w" in g)
print(list(g))
