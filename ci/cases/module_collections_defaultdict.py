# 职责: defaultdict 的 repr 与映射式构造
# 比对: same_output

# defaultdict 的 repr 与映射构造 (P2-22)
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
