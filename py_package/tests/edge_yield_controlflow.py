# 生成器与控制流结构测试 (if/while/for/try/break/continue/else)

# yield 在 if/else 中
def gif(flag):
    if flag:
        yield "yes"
    else:
        yield "no"
print(list(gif(True)))      # ['yes']
print(list(gif(False)))     # ['no']

# yield 在 while 中 (含 break/continue)
def gwhile():
    i = 0
    while True:
        i += 1
        if i == 2:
            continue
        yield i
        if i >= 4:
            break
print(list(gwhile()))       # [1, 3, 4]

# yield 在 for 中 (含 for-else: break 时 else 不执行)
def gfor():
    for i in range(3):
        yield i
        if i == 1:
            break
    else:
        yield "no-break"
print(list(gfor()))         # [0, 1]

def gfor2():
    for i in range(3):
        yield i
    else:
        yield "no-break"
print(list(gfor2()))        # [0, 1, 2, 'no-break']

# yield 在 while-else 中
def gwhile_else():
    i = 0
    while i < 2:
        yield i
        i += 1
    else:
        yield "while-done"
print(list(gwhile_else()))  # [0, 1, 'while-done']

# yield 在 try/except/finally 中
def gtry():
    try:
        yield 1
        yield 2
    finally:
        yield "finally"
print(list(gtry()))         # [1, 2, 'finally']

# yield from 在循环中
def inner():
    yield "a"
    yield "b"
def gouter():
    for i in range(2):
        yield i
        yield from inner()
print(list(gouter()))       # [0, 'a', 'b', 1, 'a', 'b']

print("done")
