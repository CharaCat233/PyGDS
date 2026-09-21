# dict 合并运算符 | 与 ** 解包测试 (Python 3.9+)

# 基础合并
d1 = {"a": 1, "b": 2}
d2 = {"b": 3, "c": 4}
print(d1 | d2)              # {'a': 1, 'b': 3, 'c': 4} (右侧覆盖左侧同键)

# |= 增强赋值 (原地合并)
d3 = {"a": 1}
d3 |= d2
print(d3)                   # {'a': 1, 'b': 3, 'c': 4}

# 合并不改变原字典
print(d1)                   # {'a': 1, 'b': 2}
print(d2)                   # {'b': 3, 'c': 4}

# 多个合并
print(d1 | d2 | {"z": 9})   # {'a': 1, 'b': 3, 'c': 4, 'z': 9}

# {**a, **b} 字典字面量解包
print({**d1, **d2})         # {'a': 1, 'b': 3, 'c': 4}
print({**d1, "z": 9})       # {'a': 1, 'b': 2, 'z': 9}
print({"z": 9, **d1})       # {'z': 9, 'a': 1, 'b': 2}

# 混合: 显式键覆盖解包值
print({**d1, "a": 100})     # {'a': 100, 'b': 2}
print({"a": 100, **d1})     # {'a': 1, 'b': 2} (后者覆盖)

# dict.fromkeys 类方法
print(dict.fromkeys(["a", "b"], 0))     # {'a': 0, 'b': 0}
print(dict.fromkeys([1, 2]))            # {1: None, 2: None}
print(dict.fromkeys("ab", "x"))         # {'a': 'x', 'b': 'x'}

print("done")
