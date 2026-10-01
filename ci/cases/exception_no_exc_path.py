# 职责: try 无异常时不进入 except 分支
# 比对: same_output


no_error = False
try:
    no_error = True
except:
    no_error = False
print(no_error)
