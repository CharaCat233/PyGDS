# 语句与作用域: finally 流控 / 局部名 / PEP 479 / 递归上限
def f1():
    try:
        raise ValueError("v")
    finally:
        return "f1"
print(f1())

def f2():
    for i in range(1):
        try:
            raise ValueError("v")
        finally:
            break
    return "f2"
print(f2())

x = "global"
def shadow():
    print(x)
    x = 1
try:
    shadow()
except UnboundLocalError as e:
    print("UBL:", type(e).__name__)

def f3():
    try:
        raise ValueError("inner")
    except ValueError:
        try:
            raise TypeError("outer")
        except TypeError as e:
            print("ctx-none:", e.__context__ is None)
    return "f3"
print(f3())

def g():
    raise StopIteration("hidden")
    yield 1
try:
    for v in g():
        pass
except RuntimeError as e:
    print("P479:", e)

def deep(n):
    if n <= 0:
        return 0
    return deep(n - 1)
print(deep(20))
def runaway(n):
    return runaway(n + 1)
try:
    runaway(0)
except RecursionError as e:
    print("RE:", type(e).__name__)
