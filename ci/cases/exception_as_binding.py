# 职责: 除零异常经 as 绑定后取其消息
# 比对: same_output


arth_msg = ""
try:
    x = 1 / 0
except ArithmeticError as e:
    arth_msg = str(e)
print(arth_msg != "")
