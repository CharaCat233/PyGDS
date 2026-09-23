# Error: 赋值表达式出现在推导式可迭代表达式内 (Python: SyntaxError)

r = [x for x in (y := [1, 2])]
print(r)
