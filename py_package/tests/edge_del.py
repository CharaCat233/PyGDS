# Edge: del 语句

# del 简单变量
x = 42
print(x)                   # 42
del x
try:
    print(x)
except NameError:
    print("NameError")     # NameError

# del 列表元素
lst = [1, 2, 3, 4]
del lst[1]
print(lst)                 # [1, 3, 4]
del lst[-1]
print(lst)                 # [1, 3]

# del 字典键
d = {"a": 1, "b": 2}
del d["a"]
print(d)                   # {'b': 2}

# del 属性 (需要自定义类)
try:
    obj = type("Obj", (), {"attr": 5})()
    del obj.attr
    print(obj.attr)
except AttributeError:
    print("AttributeError")