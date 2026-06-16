# Error: 多层继承 (ArithmeticError)

arth_caught = False
try:
    x = 1 / 0
except ArithmeticError:
    arth_caught = True
print(arth_caught)
