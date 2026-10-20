# 职责: Counter 构造保留计数/kwargs/相等比较/most_common 保真
# 比对: same_output

from collections import Counter, defaultdict

# Counter 四处静默数据损坏

# 相等性: Counter 按底层映射比较 (此前落到引用恒等恒 False)
print(Counter({"a": 1}) == Counter({"a": 1}))
print(Counter({"a": 1}) == {"a": 1})
print(Counter({"a": 1}) != Counter({"a": 2}))
print(defaultdict(int, {1: 2}) == {1: 2})
print(Counter() == Counter())

# 负计数保留 (此前构造过滤非正计数)
print(repr(Counter({"a": -1})))
print(Counter({"a": -1})["a"])
print(repr(Counter({"a": -1}) + Counter({"a": 1})))
print(Counter({"a": -1}) + Counter({"a": 2}))

# kwargs 计数 (此前被丢弃)
print(repr(Counter(a=1)))
# 多 kwargs 的顺序是 CPython 实现细节, 断言改为顺序无关
print(sorted(Counter(a=2, b=3).items()))
print(Counter(a=1)["a"])
print(Counter(a=1, b=2) == Counter({"a": 1, "b": 2}))

# 多元素 repr 按计数降序 (CPython 经 most_common 渲染), 同计数保持插入序
print(repr(Counter(a=2, b=3)))
print(repr(Counter({"a": 1, "b": 2})))
print(repr(Counter("abbc")))
print(repr(Counter("abbcccdddd")))
print(repr(Counter(a=1, b=1, c=2, d=1)))
print(repr(Counter({1: 2.5, 2: 2.5, 3: 0.5})))
print(repr(Counter(a=2, b=3).items() == Counter(a=2, b=3).items()))

# 浮点/大数计数保留
print(repr(Counter({"a": 1.5})))
print(Counter({"a": 1.5})["a"])
print(repr(Counter({10**20: 1})))
print(Counter({10**20: 1})[10**20])

# most_common 保真 (此前浮点计数取整为 0 被过滤)
print(Counter({"a": 1.5}).most_common())
print(Counter({"a": 1.5, "b": 2.0}).most_common())
print(Counter({10**20: 1}).most_common())

# Counter.update(a=1) 键编码 (此前 kwargs 键损坏)
c = Counter()
c.update(a=1)
print(c["a"])
c.update(b=2)
print(sorted(c.items()))
print(c == Counter({"a": 1, "b": 2}))

# 空 Counter repr 对齐
print(repr(Counter()))
print(repr(Counter({"a": 1}) - Counter({"a": 1})))

# Counter.most_common 接受 bool
print(Counter({"a": 1}).most_common(True))
