# Function: 错误处理

def f1(a, b, /, c, d=0, *args, e, f=1, **kwargs):
    print(a, b, c, d, e, f, args, kwargs)


def f2(a, b, /, c, d=0, *args, e, f=1):
    print(a, b, c, d, e, f, args)


def f3(a, b, /, c, d=0, *, e, f=1):
    print(a, b, c, d, e, f)


def f4(a, b, /, c, d):
    print(a, b, c, d)


try:
    f1()
except Exception as e:
    print(type(e), e)

try:
    f1(1, 2, 3)
except Exception as e:
    print(type(e), e)

try:
    f1(c=3, e=4)
except Exception as e:
    print(type(e), e)

try:
    f1(a=1, b=2, c=3, e=4)
except Exception as e:
    print(type(e), e)

try:
    f1(1, 2, 3, 4, e=5, f=6, c=7)
except Exception as e:
    print(type(e), e)

try:
    f1(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
except Exception as e:
    print(type(e), e)

try:
    f1(1, 2, 3, 4, 5, 6, 7, e=8, f=9, c=10)
except Exception as e:
    print(type(e), e)

try:
    f2(1, 2, 3, 4, 5, 6, 7, e=8, x=9)
except Exception as e:
    print(type(e), e)

try:
    f3(1, 2, 3, 4, 5, 6, e=7)
except Exception as e:
    print(type(e), e)

try:
    f4(1, 2, a=3, b=4, c=5, d=6)
except Exception as e:
    print(type(e), e)
