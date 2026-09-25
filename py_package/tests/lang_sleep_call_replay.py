# 语句重放时并列调用的副作用只执行一次

import time

log = []

def g(a, b):
    log.append((a, b))
    time.sleep(0)
    return a + b

print("g:", g(1, 2) + g(1, 2) + g(2, 1))
print("log:", log)

log2 = []
print(g(3, 4) * g(3, 4))
print("log2:", log2)

log3 = []
print(g(5, 6) + g(7, 8) + g(5, 6))
print("log3:", log3)

# 递归调用的副作用
depth = []

def f(n):
    depth.append(n)
    time.sleep(0)
    if n <= 0:
        return 0
    return f(n - 1) + 1

print(f(2))
print("depth:", depth)

# 循环体内调用的副作用
loop_log = []

def h(a):
    loop_log.append(a)
    time.sleep(0)
    return a

for i in range(3):
    print(h(i))
print("loop_log:", loop_log)

# 嵌套函数内的并列调用
nest_log = []

def inner(a):
    nest_log.append(a)
    time.sleep(0)
    return a

def outer():
    return inner(1) + inner(1)

print(outer())
print("nest_log:", nest_log)
