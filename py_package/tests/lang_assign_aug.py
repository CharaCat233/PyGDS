# Lang: 增强赋值目标形态与 del 括号目标

# 切片增强赋值
s = [1, 2, 3]
s[0:1] *= 2
print(s)
t = [1, 2, 3, 4]
t[1:3] += [10]
print(t)
text = "ab"
lst = [text]
lst[0] += "cd"
print(lst[0])
grid = [[1, 2], [3, 4]]
grid[1][0] *= 5
print(grid)

# 用户类原地方法 (__iadd__ / __isub__)
class Acc:
    def __init__(self):
        self.items = []

    def __iadd__(self, o):
        self.items.append("add:" + str(o))
        return self

    def __isub__(self, o):
        self.items.append("sub:" + str(o))
        return self


acc = Acc()
acc += 5
acc -= 6
print(acc.items)

# 增强赋值错误可捕获
try:
    missing_var += 1
except NameError:
    print("aug name err")


class NoOps:
    pass


try:
    NoOps().v += 1
except (TypeError, AttributeError):
    print("aug attr err")

# del 括号 / 方括号元组目标
a, b = 1, 2
del (a, b)
try:
    print(a)
except NameError:
    print("a gone")
try:
    print(b)
except NameError:
    print("b gone")

c, d, e = 3, 4, 5
del [c, d]
try:
    print(c)
except NameError:
    print("c gone")
print(e)

f, (g1, g2) = 6, (7, 8)
del f, (g1, g2)
try:
    print(f)
except NameError:
    print("f gone")
try:
    print(g1)
except NameError:
    print("g gone")
print(g2 if False else "g2 gone too")
