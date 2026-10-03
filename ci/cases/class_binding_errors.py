# 职责: 函数绑定错误文案的限定名 (方法 Class.name, 嵌套 outer.<locals>.inner, 顶层与 lambda 原名)
# 比对: same_output


class Pair:
    def __init__(self, items):
        self.items = items


class Method:
    def m(self, x):
        return x

    @staticmethod
    def s(x):
        return x

    @classmethod
    def c(cls, x):
        return x


# __init__ 与各类方法的缺参 / 多参 / 关键字错误均带类名限定
try:
    Pair()
except TypeError as e:
    print("init-missing:", e)
try:
    Pair(1, 2)
except TypeError as e:
    print("init-extra:", e)
try:
    Pair(items=1, other=2)
except TypeError as e:
    print("init-kw:", e)
try:
    Pair(1, items=2)
except TypeError as e:
    print("init-multi:", e)
try:
    Method().m()
except TypeError as e:
    print("method-missing:", e)
try:
    Method.m(())
except TypeError as e:
    print("unbound-missing:", e)
try:
    Method.s()
except TypeError as e:
    print("static-missing:", e)
try:
    Method.c()
except TypeError as e:
    print("classmethod-missing:", e)


# 嵌套函数: outer.<locals>.inner 限定
def outer():
    def inner(x):
        return x
    return inner


try:
    outer()()
except TypeError as e:
    print("nested-missing:", e)


# 顶层普通函数与 lambda: 原名与 <lambda>
def plain(x):
    return x


try:
    plain()
except TypeError as e:
    print("plain-missing:", e)
try:
    (lambda x: x)()
except TypeError as e:
    print("lambda-missing:", e)


# keyword-only 与给定数短语形态 (was/were 与括注有无按 CPython)
def kwonly(a, *, k):
    return k


try:
    kwonly(1, 2, k=3)
except TypeError as e:
    print("kwonly-extra:", e)
try:
    kwonly(1, 2)
except TypeError as e:
    print("kwonly-nokw:", e)


def nokw(*, k):
    return k


try:
    nokw(1)
except TypeError as e:
    print("nokw-one:", e)
try:
    nokw(1, 2)
except TypeError as e:
    print("nokw-two:", e)
