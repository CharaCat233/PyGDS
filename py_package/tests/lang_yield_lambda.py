# 生成器 lambda 测试 (Python 3.12+: lambda 体内允许 yield)

fl = lambda: (yield 7)
print(type(fl()))           # <class 'generator'>
g = fl()
print(next(g))              # 7
print(list(g))              # [] 已耗尽

# lambda 内的 yield 属于 lambda, 不使外层函数成为生成器
def outer():
    l = lambda: (yield 5)
    return l
print(type(outer()()))      # <class 'generator'>
print(list(outer()()))      # [5]

print("done")
