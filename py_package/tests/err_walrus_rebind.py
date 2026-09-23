# Error: 赋值表达式重绑定推导式循环变量 (Python: SyntaxError)

i = 99
r = [i := 0 for i in range(3)]
print(r)
