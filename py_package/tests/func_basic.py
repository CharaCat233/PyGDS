# Function: 定义与调用

def f1(a, b, /, c, d=0, *args, e, f=1, **kwargs):
    print(a, b, c, d, e, f, args, kwargs)


def f2(a, b, /, c, d=0, *args, e, f=1):
    print(a, b, c, d, e, f, args)


def f3(a, b, /, c, d=0, *, e, f=1):
    print(a, b, c, d, e, f)


def f4(a, b, /, c, d):
    print(a, b, c, d)


f1(1, 2, 3, 4, e=5)  # 1 2 3 4 5 1 () {}
f1(1, 2, 3, 4, 5, e=6)  # 1 2 3 4 6 1 (5,) {}
f1(1, 2, 3, e=4, f=5, g=6)  # 1 2 3 0 4 5 () {'g': 6}
f1(1, 2, 3, 4, 5, 6, 7, e=8, f=9, g=10, h=11)  # 1 2 3 4 8 9 (5, 6, 7) {'g': 10, 'h': 11}
f1(1, 2, 3, 4, 5, 6, 7, e=8)  # 1 2 3 4 8 1 (5, 6, 7) {}
f1(1, 2, 3, 4, 5, 6, 7, e=8, f=9)  # 1 2 3 4 8 9 (5, 6, 7) {}
f1(1, 2, a=3, b=4, c=5, e=6)  # 1 2 5 0 6 1 () {'a': 3, 'b': 4}

# f1()  # TypeError: f1() missing 3 required positional arguments: 'a', 'b', and 'c'
# f1(1, 2, 3)  # TypeError: f1() missing 1 required keyword-only argument: 'e'
# f1(c=3, e=4)  # TypeError: f1() missing 2 required positional arguments: 'a' and 'b'
# f1(a=1, b=2, c=3, e=4)  # TypeError: f1() missing 2 required positional arguments: 'a' and 'b'
# f1(1, 2, 3, 4, e=5, f=6, c=7)  # TypeError: f1() got multiple values for argument 'c'
# f1(1, 2, 3, 4, e=5, 6)  # SyntaxError: positional argument follows keyword argument
# f1(1, 2, 3, 4, e=5, f=6, 7)  # SyntaxError: positional argument follows keyword argument
# f1(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)  # TypeError: f1() missing 1 required keyword-only argument: 'e'
# f1(1, 2, 3, 4, 5, 6, 7, e=8, f=9, c=10)  # TypeError: f1() got multiple values for argument 'c'
# f2(1, 2, 3, 4, 5, 6, 7, e=8, x=9)  # TypeError: f2() got an unexpected keyword argument 'x'
# f3(1, 2, 3, 4, 5, 6, e=7)  # TypeError: f3() takes from 3 to 4 positional arguments but 6 positional arguments (and 1 keyword-only argument) were given
# f4(1, 2, a=3, b=4, c=5, d=6)  # TypeError: f4() got some positional-only arguments passed as keyword arguments: 'a, b'
