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
