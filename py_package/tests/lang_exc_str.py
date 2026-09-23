# 异常 str / repr / args 与 CPython 对齐测试

# 单参数: str 取参数, repr 带类型名
try:
    raise ValueError("plain")
except ValueError as e:
    print("1", str(e), repr(e), e.args)

# 无参数: str 为空串, repr 为空括号
try:
    raise ValueError()
except ValueError as e:
    print("2", repr(str(e)), repr(e), e.args)

# 多参数: str 为参数元组
try:
    raise ValueError("a", "b")
except ValueError as e:
    print("3", str(e), repr(e), e.args)

# KeyError 是特例: str 用参数的 repr
try:
    raise KeyError("k")
except KeyError as e:
    print("4", str(e), repr(e), e.args)

# KeyError 非字符串参数
try:
    raise KeyError(1)
except KeyError as e:
    print("5", str(e), repr(e), e.args)

try:
    raise KeyError()
except KeyError as e:
    print("6", repr(str(e)), repr(e), e.args)

# 字典取值缺失: 键按 repr 显示
d = {"a": 1}
try:
    d["b"]
except KeyError as e:
    print("7", str(e), e.args)

try:
    d[2]
except KeyError as e:
    print("8", str(e), e.args)

# 其余字典/集合方法的 KeyError 文案
try:
    {}.popitem()
except KeyError as e:
    print("9", str(e))

try:
    set().pop()
except KeyError as e:
    print("10", str(e))

try:
    {}.pop("z")
except KeyError as e:
    print("11", str(e))

try:
    del {}["z"]
except KeyError as e:
    print("12", str(e))

# 非 KeyError 异常仍用 str 语义
try:
    raise TypeError(1, 2)
except TypeError as e:
    print("13", str(e), repr(e))



# range 对象不可变 (与 CPython 一致)
r = range(3)
try:
    r[0] = 9
except TypeError as e:
    print("14", e)

try:
    del r[0]
except TypeError as e:
    print("15", e)

lst2 = [1, 2, 3]
lst2[0] = 9
del lst2[0]
print("16", lst2)

print("done")
