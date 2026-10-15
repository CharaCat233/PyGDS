# 职责: print 的 sep/end 与 type() 查询
# 比对: same_output


# 测试内置函数

print()
print(1)
print(1.5)
print("a")
print("a", "b")
print("a", "b", "c", sep=", ")
print("a", "b", "c", end=" --\n")
print("a", "b", "c", sep=", ", end=" --\n")
print("a", "b", "c", sep=", ", end=" --\n")

print(type(0))
print(type(""))

# sep/end 类型校验 (sep=None 按默认分隔符, 非 str/None 报 TypeError)
print(1, 2, sep=None)
print(1, 2, end=None)
try:
    print(1, sep=1)
except TypeError as e:
    print("TE-sep:", e)
try:
    print(1, end=1)
except TypeError as e:
    print("TE-end:", e)
try:
    print("a", "b", sep=3.5)
except TypeError as e:
    print("TE-sep2:", e)
