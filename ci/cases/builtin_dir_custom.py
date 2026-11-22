# 职责: 用户自定义 __dir__ 协议 (实例 / 类 / 元类, 非可迭代返回值)
# 比对: same_output


class C:
    def __dir__(self):
        return ["zz", "aa"]


print(dir(C()))


class D:
    def __dir__(self):
        yield "y"
        yield "x"


print(dir(D()))


class M(type):
    def __dir__(cls):
        return ["meta"]


class E(metaclass=M):
    pass


print(dir(E))


class F:
    def __dir__(self):
        return 42


try:
    print(dir(F()))
except TypeError as err:
    print("te:", err)


class G:
    def __dir__(self):
        return [2, 1]


print(dir(G()))
