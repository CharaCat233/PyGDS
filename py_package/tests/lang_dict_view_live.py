# dict 视图实时性: 修改后视图反映新内容, 迭代中增删键报错 (v0.6.0-alpha.2)

# 视图实时性: 修改后视图反映新内容
d = {"a": 1}
kv = d.keys()
d["b"] = 2
print(list(kv))
print(kv)
print(len(kv), bool(kv))
d["a"] = 99
print(list(kv))
d.pop("b")
print(list(kv), kv)

# 值视图与键值对视图同样实时
d2 = {"x": 1}
vv = d2.values()
iv = d2.items()
d2["y"] = 2
print(list(vv), list(iv))
d2["x"] = 10
print(list(vv), list(iv))
print(len(vv), len(iv))

# 迭代中增删键报 RuntimeError (可捕获), 值替换不触发
d3 = {"a": 1, "b": 2}
it = iter(d3.keys())
d3["c"] = 3
try:
    print(list(it))
except RuntimeError:
    print("keys-mutate")

d4 = {"a": 1, "b": 2}
it2 = iter(d4.values())
d4.pop("a")
try:
    print(list(it2))
except RuntimeError:
    print("values-mutate")

d5 = {"a": 1, "b": 2}
it3 = iter(d5.items())
d5["a"] = 100
print(list(it3))

# for 循环直接迭代视图
d6 = {"p": 1, "q": 2}
for v in d6.values():
    print("for-v", v)
for pair in d6.items():
    print("for-i", pair)

# 复合键经迭代还原 (元组键不被编码污染)
d7 = {(1, 2): "x", "a": 1}
print(list(d7))
print(list(d7.keys()))
print(list(d7.items()))
for k in d7:
    print(k, type(k).__name__)

# 复合键经 copy / update 传播
d8 = {(1, 2): "t"}
d9 = d8.copy()
print(list(d9))
d10 = {}
d10.update(d8)
print(list(d10), list(d10.keys()))

print("done_view")
