# 职责: NaN 参与有序比较全部为 False
# 比对: same_output

# 无序哨兵此前被直接当比较结果用, 1 < nan 恒为 True
# CPython IEEE 语义: 任一操作数为 NaN 时有序比较 (< <= > >=) 全部 False

nan = float("nan")
print(1 < nan)
print(1 <= nan)
print(1 > nan)
print(1 >= nan)
print(nan < 1)
print(nan <= 1)
print(nan > 1)
print(nan >= 1)
print(nan < nan)
print(nan <= nan)
print(nan > nan)
print(nan >= nan)
print(1 == nan, 1 != nan)
print(nan == nan)
print(nan != nan)
# 正常数值不受影响
print(2 < 3.5, 3.5 > 2, 2 <= 2.0, 3 >= 3.0)
print(2 < nan == False)
print(1.5 > nan == False)
print(not (1 < nan), not (nan >= 1))
