# 职责: 自定义异常未调 super().__init__ 时 str(e) 按 args 格式化 (I2-66)
# 比对: same_output

# 用户异常覆写 __init__ 且不调用 super().__init__ 时, _wrapped 不建立,
# str(e) 退化为类型名 (旧); 现按 CPython 以 args 格式化: 无参空串, 单参 str,
# 多参元组 repr, KeyError 子类单参用 repr

class E2(Exception):
    def __init__(self, x):
        self.x = x


e = E2(7)
print("args:", e.args)
print("str:", str(e))
print("repr:", repr(e))


class E3(Exception):
    pass


print("empty-str:", repr(str(E3())))
print("empty-args:", E3().args)


class E4(Exception):
    def __init__(self):
        pass


print("noarg-str:", repr(str(E4())))


class E5(E2):
    pass


print("sub-str:", str(E5(7)))
print("sub-args:", E5(7).args)


class E6(Exception):
    def __init__(self, x):
        self.args = (x,)


print("setargs-str:", str(E6(7)))


class KErr(KeyError):
    def __init__(self, k):
        self.k = k


print("keyerr-args:", KErr("boom").args)
print("keyerr-str:", repr(str(KErr("boom"))))


# 多参数形态
class Multi(Exception):
    def __init__(self, a, b):
        self.a = a
        self.b = b


print("multi-args:", Multi(1, "two").args)
print("multi-str:", str(Multi(1, "two")))
