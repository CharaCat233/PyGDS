# duty: min/max/round/math 错误文案、print>>提示与函数 repr 对齐
# compare: same_output


def show(label, fn):
    try:
        fn()
    except Exception as e:
        print(label, type(e).__name__ + ":", e)


def t1():
    min([])


def t2():
    max()


def t3():
    min(1)


def t4():
    round("a")


def t5():
    import math
    math.factorial(-1)


def t6():
    import math
    math.comb(3, -1)


def t7():
    import math
    math.perm(3, -1)


def t8():
    sorted([1, "a"])


def t9():
    sorted([1, "a"], reverse=True)


def t10():
    print >> 1


class Child:
    def greet(self):
        pass


show("t1", t1)
show("t2", t2)
show("t3", t3)
show("t4", t4)
show("t5", t5)
show("t6", t6)
show("t7", t7)
show("t8", t8)
show("t9", t9)
show("t10", t10)
c = Child()
print("method_repr", c.greet)
print("func_repr", Child.greet)


def greet():
    pass


print("plain_func", greet)
