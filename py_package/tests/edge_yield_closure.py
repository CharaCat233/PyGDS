# 生成器与闭包 / 默认参数 / 类方法

# 闭包变量跨 yield 可见
def make(limit):
    def gen():
        i = 0
        while i < limit:
            yield i
            i += 1
    return gen
print(list(make(3)()))      # [0, 1, 2]

# 默认参数 / 位置参数
def with_default(start=0, step=1):
    n = start
    while n < 3:
        yield n
        n += step
print(list(with_default(1)))        # [1, 2]
print(list(with_default(0, 2)))     # [0, 2]

# 类方法 (self 绑定)
class C:
    def __init__(self, name):
        self.name = name
    def gen(self):
        yield self.name
        yield self.name.upper()
c = C("py")
print(list(c.gen()))        # ['py', 'PY']

# 嵌套生成器各自独立挂起状态
def a():
    for i in range(2):
        yield ("a", i)
def b():
    for i in range(2):
        yield ("b", i)
ia, ib = a(), b()
print(list(zip(ia, ib)))    # [(('a', 0), ('b', 0)), (('a', 1), ('b', 1))]

print("done")
