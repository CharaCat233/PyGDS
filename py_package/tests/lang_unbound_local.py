# UnboundLocalError: 局部名静态收集与类型层级 (P2-19)
def f():
    try:
        x = x + 1
    except UnboundLocalError as e:
        print("UL:", e)
    except NameError as e:
        print("NE:", e)
f()
print(issubclass(UnboundLocalError, NameError))

def g():
    try:
        y = y + 1
    except NameError as e:
        print("as NE:", type(e).__name__)
g()

z = 100
def h():
    global z
    print(z)
h()

def outer():
    def inner():
        return w
    w = 5
    return inner()
print(outer())

def a2():
    try:
        q += 1
    except UnboundLocalError as e:
        print("aug:", e)
a2()

def m():
    try:
        print(n)
    except UnboundLocalError as e:
        print("msg:", e)
    except NameError as e:
        print("global-read:", type(e).__name__)
m()

def c():
    try:
        print(k)
    except NameError as e:
        print("cls-name:", type(e).__name__)
c()

def for_local():
    try:
        for i in range(2):
            pass
        print(i)
    except UnboundLocalError as e:
        print("for:", type(e).__name__)
for_local()
