# 职责: defaultdict 的 repr 与映射式构造
# 比对: same_output

# defaultdict 的 repr 与映射构造
from collections import defaultdict

dd = defaultdict(int)
print(dd)
print(repr(dd))
dd["a"] = 1
print(dd)
print(defaultdict(None))
print(defaultdict())
print(defaultdict(list, {"x": 2}))
print(str(defaultdict(int, {"a": [1]})))
print(dict(dd))
d2 = defaultdict(int, dd)
print(d2["a"], d2["b"])


# defaultdict 缺省工厂抛出的异常此前被 KeyError 顶替
class BoomFactory:
    def __call__(self):
        raise ValueError("boom")


db = defaultdict(BoomFactory())
try:
    db["x"]
except ValueError as e:
    print("VE:", str(e))


# 工厂返回 None 等普通值时正常 (CPython: 不触发工厂时返回默认)
class NoneFactory:
    def __call__(self):
        return None


dn = defaultdict(NoneFactory())
print(dn["missing"])
print("missing" in dn)


# 工厂产生副作用且成功: 存入
class ListFactory:
    def __call__(self):
        return []


dl = defaultdict(ListFactory())
dl["k"].append(1)
print(dl["k"])

# int 工厂缺失键返回 0
di = defaultdict(int)
print(di["a"])
print(di["a"] + 1)


# defaultdict 构造校验 (factory 可调用) 与键值对序列初始化; 异常 kwargs 拒绝
try:
    defaultdict(3)
except TypeError as e:
    print("dd-int:", str(e))
dd = defaultdict(int, [("a", 1), ("b", 2)])
print("dd-seq:", dict(dd))
try:
    ValueError(foo=1)
except TypeError as e:
    print("exc-kw:", str(e))
