# 职责: enumerate 的大数起始编号与 bool 起始
# 比对: same_output

# enumerate(start=大数) 此前静默从 0 计数 (大数 value 恒 0)
# CPython 3.12 对任意精度 start 随步进递增计数
print(list(enumerate("ab", start=10 ** 30)))
print(list(enumerate("ab", start=10 ** 30))[1][0] - 10 ** 30)

# 大数 start 逐项递增 (任意精度不落 int64)
e = enumerate(range(3), start=2 ** 64)
print(list(e))

# 普通 start 不变
print(list(enumerate("ab", start=3)))
print(list(enumerate("ab")))

# bool start 按 int 子类 (True -> 1)
print(list(enumerate("ab", start=True)))
print(list(enumerate("ab", start=False)))

# 非整数 start 报错
try:
    print(list(enumerate("ab", start="x")))
except TypeError as e:
    print("TE", str(e))

# 位置实参与关键字等价
print(list(enumerate("ab", 5)) == list(enumerate("ab", start=5)))

# 大数 start 为负: 递增但起点为负 (CPython 允许)
print(list(enumerate("ab", start=-(10 ** 30))))
