# Lang: ... (Ellipsis) 字面量

x = ...
print(x)
print(type(x))
print(bool(...))
print(... is ...)
print(str(...), repr(...))


def stub():
    ...


print(stub())


class WithDefault:
    def m(self, k=...):
        return k is ...


print(WithDefault().m(), WithDefault().m(1))

# 注解位置 (PyGDS 忽略注解, 语法须可接受)
annot: ...
print("annot ok")


def sig(a: ...) -> ...:
    return a


print(sig(7))
