# 职责: ArithmeticError 捕获除零异常
# 比对: same_output


arth_caught = False
try:
    x = 1 / 0
except ArithmeticError:
    arth_caught = True
print(arth_caught)
