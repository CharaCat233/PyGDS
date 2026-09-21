# 生成器函数测试 (yield 基础)

# 类型与基本消费
def gen():
    yield 1
    yield 2
    yield 3
print(type(gen()))          # <class 'generator'>
print(list(gen()))          # [1, 2, 3]
print(tuple(gen()))         # (1, 2, 3)

# next() 逐次推进 (一次性迭代器)
g = gen()
print(next(g))              # 1
print(next(g))              # 2
print(list(g))              # [3]
print(list(g))              # [] 已耗尽

# next() 默认值
g2 = gen()
print(next(g2, -1))         # 1
print(next(g2, -1))         # 2
print(next(g2, -1))         # 3
print(next(g2, -1))         # -1 耗尽返回默认值

# for 循环耗尽不报错
total = 0
for x in gen():
    total += x
print(total)                # 6

# 生成器函数体在迭代前不执行
def lazy():
    print("BODY")
    yield 1
g3 = lazy()
print("no-body-yet")
print(next(g3))             # 1 (BODY 在首次 next 时输出)

# 局部变量跨 yield 保持
def counter():
    n = 0
    while n < 3:
        yield n
        n += 1
print(list(counter()))      # [0, 1, 2]

# return 结束生成器, StopIteration.value
def with_return():
    yield 1
    return 42
g4 = with_return()
print(next(g4))             # 1
try:
    next(g4)
except StopIteration as e:
    print("value:", e.value)  # 42

# 两个生成器交替 next()
def ga():
    for i in range(3):
        yield 'a' + str(i)
def gb():
    for i in range(3):
        yield 'b' + str(i)
ia, ib = ga(), gb()
print(next(ia), next(ib), next(ia), next(ib), next(ia), next(ib))

# 嵌套生成器 (生成器内消费另一个生成器)
def inner():
    yield 1
    yield 2
def outer():
    for x in inner():
        yield x * 10
print(list(outer()))        # [10, 20]

# 生成器方法 (self 绑定可用)
class Box:
    def gen(self):
        yield self.tag
        yield self.tag + "!"
b = Box()
b.tag = "hi"
print(list(b.gen()))        # ['hi', 'hi!']

# 默认参数 / *args / **kwargs (参数绑定在调用时完成)
def gargs(a, b=10, *args, **kwargs):
    yield a
    yield b
    yield args
    yield kwargs
print(list(gargs(1, 2, 3, 4, x=9)))     # [1, 2, (3, 4), {'x': 9}]
print(list(gargs(5)))                   # [5, 10, (), {}]

print("done")
