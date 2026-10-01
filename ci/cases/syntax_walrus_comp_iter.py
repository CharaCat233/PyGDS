# 职责: 赋值表达式用于推导式可迭代部分报错
# 比对: same_error


r = [x for x in (y := [1, 2])]
print(r)
