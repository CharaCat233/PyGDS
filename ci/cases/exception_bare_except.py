# 职责: 裸 except 捕获任意类型异常
# 比对: same_output


try:
    raise TypeError("type error")
except:
    print("caught all")
