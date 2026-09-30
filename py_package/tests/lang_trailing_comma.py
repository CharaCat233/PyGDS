# 参数表尾随逗号 (def / lambda, P1-57)


def f1(a,):
    return a


def f2(a, b=2,):
    return (a, b)


def f3(*, x, y=1,):
    return (x, y)


def f4(*args,):
    return args


def f5(**kw,):
    return sorted(kw.items())


def f6(a, /, b,):
    return (a, b)


def f7(
    a,
    b=3,
):
    return a + b


lam = lambda x, y=1: (x, y)
lam2 = lambda **kw, : sorted(kw)
lam3 = lambda x, : x * 2
lam4 = lambda *, m, n=1: (m, n)

print(f1(5), f2(1), f3(x=1), f4(1, 2), f5(z=3), f6(1, 2), f7(1))
print(lam(1), lam2(a=1), lam3(4), lam4(m=9))


class C:
    def m(self, a,):
        return a


print(C().m(7))


def outer():
    def inner(x,):
        return x
    return inner(8)


print(outer())
