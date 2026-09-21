# 生成器体内异常传播与结束语义

# 生成器内抛异常: 从 next() 传播到调用方, 生成器进入已结束状态
def gerr():
    yield 1
    raise ValueError("boom")

it = gerr()
print(next(it))             # 1
try:
    next(it)
except ValueError as e:
    print("caught:", e)     # caught: boom
# 异常后生成器已结束
print(list(it))             # []
try:
    next(it)
except StopIteration:
    print("closed")         # closed

# 生成器 return 值
def gr():
    yield 1
    return 5
g2 = gr()
print(next(g2))             # 1
try:
    next(g2)
except StopIteration as e:
    print("stop:", e.value)  # stop: 5

# return 与异常混合: 裸 return
def gr2():
    yield 1
    return
g3 = gr2()
print(next(g3))             # 1
try:
    next(g3)
except StopIteration as e:
    print("bare:", e.value)  # bare: None

print("done")
