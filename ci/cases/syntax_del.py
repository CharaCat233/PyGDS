# 职责: del 变量/列表元素/字典键/属性
# 比对: same_output


# del 简单变量
x = 42
print(x)  # 42
del x
try:
    print(x)
except NameError:
    print("NameError")  # NameError

# del 列表元素
lst = [1, 2, 3, 4]
del lst[1]
print(lst)  # [1, 3, 4]
del lst[-1]
print(lst)  # [1, 3]

# del 字典键
d = {"a": 1, "b": 2}
del d["a"]
print(d)  # {'b': 2}

# del 属性 (需要自定义类)
try:
    obj = type("Obj", (), {"attr": 5})()
    del obj.attr
    print(obj.attr)
except AttributeError:
    print("AttributeError")

# del 实例属性 (成功路径)
obj2 = type("Obj2", (), {})()
obj2.own = 1
del obj2.own
print(hasattr(obj2, "own"))  # False

# del 目标列表尾逗号
a = 1
b = 2
c = 3
del (
    a,
    b,
)
try:
    print(a)
except NameError:
    print("a deleted")
try:
    print(b)
except NameError:
    print("b deleted")
print(c)


# 函数体内 del 未定义局部名报 UnboundLocalError (模块级仍 NameError)
def f():
    del undefined_local_qq


try:
    f()
except UnboundLocalError as e:
    print("del-unbound:", str(e))
try:
    del module_undefined_qq
except NameError as e:
    print("del-name:", str(e))


# 不可删除对象的 del 文案统一 doesn't (CPython 同)
def _del_str():
    s = "abc"
    del s[0]


def _del_range():
    r = range(3)
    del r[0]


def _del_bytes():
    b = b"abc"
    del b[0]


try:
    _del_str()
except TypeError as e:
    print("del-str:", type(e).__name__, str(e))
try:
    _del_range()
except TypeError as e:
    print("del-range:", type(e).__name__, str(e))
try:
    _del_bytes()
except TypeError as e:
    print("del-bytes:", type(e).__name__, str(e))
