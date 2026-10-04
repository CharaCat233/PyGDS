# duty: close() 驱动 finally 体挂起的语句级重放 (输出行序与 CPython 同步 close 一致)
# compare: same_output
# anchor: CPython 3.12

import time

# CPython 的 close() 同步执行 finally 体后才返回, finally 内输出先于返回值;
# PyGDS 的 close 驱动挂起经语句级重放续驱 finally 完成, 行序一致
def g():
    try:
        yield 1
        yield 2
    finally:
        time.sleep(0.05)
        print("gfin")

it = g()
next(it)
print(it.close())
print("after-close")

# close 在表达式链中: finally 完成后 close 的 None 参与 or 求值
def g2():
    try:
        yield 1
    finally:
        time.sleep(0.05)
        print("g2fin")
it2 = g2()
next(it2)
x = it2.close() or "d"
print("chain:", x)

# for 循环正常耗尽 (不 close) 的收尾路径不受 close 语义改动影响
def g3():
    try:
        yield 1
        yield 2
    finally:
        time.sleep(0.05)
        print("g3fin")
for v in g3():
    print("for:", v)

# with 管理器 __exit__ 路径中的显式 close: finally 先于 __exit__ 后续语句
class CM:
    def __init__(self, gen):
        self.gen = gen
    def __enter__(self):
        return self
    def __exit__(self, *a):
        self.gen.close()
        print("cm-exit")
def g4():
    try:
        yield 1
    finally:
        time.sleep(0.05)
        print("g4fin")
cm = CM(g4())
next(cm.gen)
with cm:
    print("in-with")

# close 体捕获 GeneratorExit 后 sleep 再 yield: RuntimeError (generator ignored GeneratorExit)
def g5():
    try:
        yield 1
    except GeneratorExit:
        time.sleep(0.05)
        print("g5caught")
        yield 2
it5 = g5()
next(it5)
try:
    it5.close()
except RuntimeError as e:
    print("g5 RuntimeError:", e)

# 嵌套两层生成器委托的 close: 内层 finally 先于外层收尾
def inner():
    try:
        yield "i1"
        yield "i2"
    finally:
        time.sleep(0.05)
        print("inner-fin")
def outer():
    try:
        yield from inner()
    finally:
        print("outer-fin")
it6 = outer()
next(it6)
it6.close()
print("after-delegate-close")

# finally 内多段 sleep: 重放轮逐段续驱后 close 才返回
def g7():
    try:
        yield 1
    finally:
        time.sleep(0.05)
        print("g7fin1")
        time.sleep(0.05)
        print("g7fin2")
it7 = g7()
next(it7)
print(it7.close())
