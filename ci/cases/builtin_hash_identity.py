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

# 大数与等值浮点哈希一致 (此前 hash(10**20) != hash(float(10**20)))
# CPython 不变量: 相等的对象必须有相等哈希; 整值浮点经精确整数展开走同一 int 哈希
print(hash(10**20) == hash(float(10**20)))
print(hash(10**20) == hash(1e20))
print(hash(-(10**20)) == hash(float(-(10**20))))
print(hash(-1.0) == hash(-1))
print(hash(2.0) == hash(2))
print(hash(0.0) == hash(0))
print(hash(1e30) == hash(10**30))
print(hash(1.5) == hash(1.5))
d = {10**20: 1, float(10**20): 2}
print(len(d))
