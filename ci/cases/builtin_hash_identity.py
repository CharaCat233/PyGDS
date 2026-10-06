# duty: 身份哈希的模式无关不变量: 同对象哈希稳定 / 等值同哈希 / 对象作字典与集合键
# 比对: same_output
# 锚定: CPython 3.12
class W:
    pass

a = W()
b = W()
print(hash(a) == hash(a), hash(None) == hash(None))
try:
    print(hash(a) == hash(b))
except Exception as e:
    print(type(e).__name__)
d = {a: "va", None: "vn"}
print(d[a], d[None])
s = {a, None}
print(len(s), a in s, None in s)
print(hash(1) == hash(True), hash(1.0) == hash(1))
print(hash((1, 2)) == hash((1, 2)))
