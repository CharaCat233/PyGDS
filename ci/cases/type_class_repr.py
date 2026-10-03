# 职责: 类对象 repr 与 str 同为 <class 'X'> 形态 (容器元素与格式化路径一并覆盖)
# 比对: same_output

# 内建类型与用户类的 repr / str / 容器内 / 格式化全路径
print(repr(int), repr(type), repr(object))
print(str(int))


class Pair:
    pass


print(repr(Pair))
print(f"{Pair!r}")
print([int, str])
print(repr(type(5)))


def f():
    return 1


print(repr(type(f)))

# 类对象作为字典值 / 异常类的 repr
d = {"t": int}
print(d)
print(repr(ValueError))

# type 三参建类与 type() 本身的形态
C = type("C", (), {})
print(repr(C))
