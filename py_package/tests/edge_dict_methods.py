# Edge: dict.pop / setdefault / update / popitem

d = {"a": 1, "b": 2}
print(d.pop("a"))              # 1
print(d)                       # {'b': 2}

# pop 带默认值
print(d.pop("x", "default"))   # default
print(d.pop("b", "default"))   # 2

# pop 不带默认值且 key 不存在
try:
    d.pop("missing")
except KeyError as e:
    print(type(e).__name__)    # KeyError

# setdefault
e = {}
e.setdefault("a", 0)
print(e)                       # {'a': 0}
e.setdefault("a", 999)
print(e)                       # {'a': 0} (key 存在不覆盖)
print(e.setdefault("b"))       # None (无默认值返回 None)

# update 多种形式
f = {}
f.update({"x": 1})
print(f)                       # {'x': 1}
f.update(y=2, z=3)
print(f)                       # {'x': 1, 'y': 2, 'z': 3}
f.update([("p", 4), ("q", 5)])
print(f)                       # {'x': 1, 'y': 2, 'z': 3, 'p': 4, 'q': 5}

# popitem
g = {"a": 1, "b": 2}
popped = g.popitem()
print(type(popped))            # <class 'tuple'>
print(popped[0] in ["a", "b"]) # True
print(len(g))                  # 1

print("done")