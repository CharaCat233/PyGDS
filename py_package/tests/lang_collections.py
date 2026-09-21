# collections 模块测试: Counter / defaultdict

from collections import Counter, defaultdict

# Counter 计数
c = Counter("abca")
print(sorted(c.items()))        # [('a', 2), ('b', 1), ('c', 1)]
print(c["a"])                   # 2
print(c["b"])                   # 1
print(len(c))                   # 3

# Counter 数值计数
c2 = Counter([1, 1, 2, 3])
print(sorted(c2.items()))       # [(1, 2), (2, 1), (3, 1)]
print(c2[1])                    # 2

# Counter 缺失键返回 0
print(Counter("abc")["z"])      # 0

# Counter 空
print(len(Counter()))           # 0

# defaultdict 基础
dd = defaultdict(list)
dd["a"].append(1)
dd["a"].append(2)
print(dd["a"])                  # [1, 2]
print(dd["b"])                  # [] (自动创建)
print(len(dd))                  # 2

# defaultdict 整数工厂
dc = defaultdict(int)
dc["x"] += 5
print(dc["x"])                  # 5
print(dc["y"])                  # 0 (int() 默认 0)

# defaultdict 字符串工厂
ds = defaultdict(str)
print(ds["k"])                  # "" (str() 默认 "")
ds["k"] = "v"
print(ds["k"])                  # v

# defaultdict 集合工厂
dset = defaultdict(set)
dset["s"].add(1)
print(dset["s"])                # {1}

# defaultdict 带初始映射
di = defaultdict(list, {"pre": [9]})
print(di["pre"])                # [9]

# in / 键访问
print("a" in dd)                # True
print("z" in dd)                # False

print("done")
