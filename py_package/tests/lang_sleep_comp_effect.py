import time

# eager 推导式元素表达式的副作用只执行一次 (P0-2)
# 迭代源含 sleep 时, 语句会整体重放; 推导式必须只产出尚未产出的元素


def a():
    for i in range(3):
        time.sleep(0)
        yield i


seen = []
print([seen.append(v) or v for v in a()])
print("seen1:", seen)

seen2 = []
print([seen2.append(v * 10) or v * 10 for v in a()])
print("seen2:", seen2)


def f(v):
    seen3.append(v)
    return v


seen3 = []
print([f(v) for v in a()])
print("seen3:", seen3)

seen4 = []
print(sorted({seen4.append(v) or v for v in a()}))
print("seen4:", seen4)

seen5 = []
print({(seen5.append(v) or v): (seen5.append(v) or v * 2) for v in a()})
print("seen5:", seen5)

seen6 = []
print([seen6.append(v) or v for v in a() if seen6.append(v) or True])
print("seen6:", seen6)

# 条件内副作用
seen7 = []
print([v for v in a() if seen7.append(v) or v == 99])
print("seen7:", seen7)

# 无副作用的推导式取值不受影响 (回归护栏)
print([v * 10 for v in a()])
print([v for v in a() if v % 2 == 0])
print({v: v * 2 for v in a()})
print(tuple(v for v in a()))
print([[y for y in range(2)] for _ in range(2)])
