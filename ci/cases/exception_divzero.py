# 职责: 裸 except 捕获除零异常
# 比对: same_output


caught_div = False
try:
    x = 1 / 0
except:
    caught_div = True
print(caught_div)
