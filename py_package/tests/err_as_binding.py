# Error: ArithmeticError as 绑定

arth_msg = ""
try:
    x = 1 / 0
except ArithmeticError as e:
    arth_msg = str(e)
print(arth_msg != "")
