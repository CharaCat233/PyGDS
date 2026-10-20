# 职责: 函数与方法的类型类名及 __name__
# 比对: same_output


# 函数与方法的类型类
def fn():
    pass


lam = lambda: 1


class C:
    def m(self):
        pass


inst = C()
print(type(fn).__name__)
print(type(lam).__name__)
print(type(len).__name__)
print(type(inst.m).__name__)
print(type(fn))
print(type(len))
print(isinstance(fn, type))
print(type(fn) is type(print))
print(C.m.__name__)
print(inst.m.__name__)
print(len.__name__)


# 关键字实参 args= 被静默吸入 *args 形参 (应落入 **kwargs)
# CPython: *args/**kwargs 形参名不参与关键字实参匹配
def fa(*args, **kw):
    return (args, sorted(kw.items()))


print(fa(args=(2, 3), extra=9))


def fb(*kwargs, **args):
    return (kwargs, sorted(args.items()))


print(fb(kwargs=1, args=2))


def fc(*a):
    return a


try:
    fc(a=1)
except TypeError as e:
    print("TE-fc:", e)


def fd(**kw):
    return sorted(kw.items())


print(fd(args=7))


# 函数对象支持自定义属性 (CPython function.__dict__)
def f19():
    pass


f19.custom = 1
print(f19.custom)
f19.other = "x"
print((f19.custom, f19.other))
print(f19.__dict__)
print(f19.__name__)


# __kwdefaults__ (kw-only 默认值字典)
def kwf(a, *, b=1, c=2):
    pass


print(kwf.__kwdefaults__)


def kwf2(a, *, b):
    pass


print(kwf2.__kwdefaults__)
it153 = iter([1, 2, 3])
print(it153.__length_hint__())

# repr 与 str 同形且带限定名 (地址双端不同, 用前缀/包含判定)
print(C.m.__qualname__)
print(repr(C.m).startswith("<function C.m at 0x"))
print(str(C.m) == repr(C.m))
print("<function C.m" in repr(C.m))
print(repr(inst.m).startswith("<bound method C.m of <"))
print(str(inst.m) == repr(inst.m))
print(inst.m.__func__ is C.m)
print(repr(inst.m.__func__).startswith("<function C.m at 0x"))
print(repr(fn).startswith("<function fn at 0x"))
print(repr(lam).startswith("<function <lambda> at 0x"))


def outer2():
    def inner():
        pass

    return inner


print(repr(outer2()).startswith("<function outer2.<locals>.inner at 0x"))
