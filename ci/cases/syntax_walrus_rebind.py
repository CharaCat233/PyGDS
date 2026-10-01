# 职责: 赋值表达式重绑定推导式循环变量报错
# 比对: same_error


i = 99
r = [i := 0 for i in range(3)]
print(r)
