# 职责: 字典 pop、setdefault、update 等
# 比对: same_output


d = {"a": 1, "b": 2}
print(d.pop("a"))  # 1
print(d)  # {'b': 2}

# pop 带默认值
print(d.pop("x", "default"))  # default
print(d.pop("b", "default"))  # 2

# pop 不带默认值且 key 不存在
try:
    d.pop("missing")
except KeyError as e:
    print(type(e).__name__)  # KeyError

# setdefault
e = {}
e.setdefault("a", 0)
print(e)  # {'a': 0}
e.setdefault("a", 999)
print(e)  # {'a': 0} (key 存在不覆盖)
print(e.setdefault("b"))  # None (无默认值返回 None)

# update 多种形式
f = {}
f.update({"x": 1})
print(f)  # {'x': 1}
f.update(y=2, z=3)
print(f)  # {'x': 1, 'y': 2, 'z': 3}
f.update([("p", 4), ("q", 5)])
print(f)  # {'x': 1, 'y': 2, 'z': 3, 'p': 4, 'q': 5}

# popitem
g = {"a": 1, "b": 2}
popped = g.popitem()
print(type(popped))  # <class 'tuple'>
print(popped[0] in ["a", "b"])  # True
print(len(g))  # 1


# dict.update(**kwargs) 键编码 (此前以裸字符串写键, 读侧全部 KeyError)
# kwargs 键须与字面量键同编码, 覆盖语义一致
d_kw = {}
d_kw.update(a=1)
print(d_kw["a"])
print("a" in d_kw)
print(d_kw.get("a"))
d_kw2 = {"a": 0}
d_kw2.update(a=9)
print(len(d_kw2))
print(d_kw2["a"])
print(repr(d_kw2))

# dict.update 成对序列 (此前 list 对静默丢弃, 三元素项静默跳过)
d_seq = {}
d_seq.update([("a", 1), ["b", 2]])
print(repr(d_seq))
try:
    d_bad = {}
    d_bad.update([("a", 1, 2)])
except ValueError as e:
    print("VE:", e)
try:
    d_bad2 = {}
    d_bad2.update([1])
except TypeError as e:
    print("TE:", e)
d_seq2 = {}
d_seq2.update((("a", 1),))
print(repr(d_seq2))
d_seq3 = {}
d_seq3.update(zip("ab", [1, 2]))
print(repr(d_seq3))
d_seq4 = {"x": 0}
d_seq4.update({"x": 9}.items())
print(repr(d_seq4))

# 大整数及整值大浮点键的 repr/迭代 (此前泄露内部 "i:" 编码)
print(repr({10**20: 1}))
print(repr({1e20: 1}))
print(list({10**20: 1}))
d_big = {1e20: 1}
d_big[10**20] = 2
print(len(d_big), repr(d_big))
d_big2 = {10**20: 1}
print(1e20 in d_big2)
print(d_big2[1e20])

# 相等键保留首个键对象 (dict 侧: {True:'a',1:'b'} 键为 True 而非 1)
print(list({True: "a", 1: "b"}))
print(list({1: "a", True: "b"}))
print(list({1.0: "a", 1: "b"}))
print(list({1: "a", 1.0: "b"}))
print(list({1 + 0j: "a", 1: "b"}))
d78 = {}
d78[1] = "a"
d78[True] = "b"
print(list(d78), d78[1], d78[True])
print(repr(d78))
d78b = {True: 1}
print(d78b[1], 1 in d78b, True in d78b)
d78c = {1: "a"}
d78c[True] = "z"
print(list(d78c), d78c[True])

# dict.update 可迭代源
u1 = {}
u1.update((("a", 1), ("b", 2)))
print(u1)
u2 = {}
u2.update(zip("xy", [3, 4]))
print(u2)
u3 = {}
u3.update({"p": 5}.items())
print(u3)
u4 = {}
u4.update([("m", 7), ("n", 8)])
print(u4)
