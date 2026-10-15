# 职责: 函数参数/返回值/变量的类型注解
# 比对: same_output


def add(x: int | float, y: int | float) -> int | float:
    return x + y


class Foo:
    def __init__(self, x: int, y: int) -> None:
        self.x = x
        self.y = y

    def say(self, message: str) -> None:
        print(self.x + self.y, message)


number: int = 1
print(add(number, 2.5))  # 3.5

foo: Foo = Foo(5, 6)
foo.say("o'clock")  # 11 o'clock


# PEP 526 属性/下标注解目标
class Ann:
    def __init__(self):
        self.x: int = 5
        self.y: int


a = Ann()
print(a.x, hasattr(a, "y"))
d = {}
d[0]: int = 7
print(d)
o = type("O", (), {})()
o.p: float = 1.5
print(o.p)
