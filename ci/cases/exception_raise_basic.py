# 职责: raise 后经 except as 捕获并打印
# 比对: same_output


try:
    raise ValueError("test error")
except ValueError as e:
    print("caught:", e)
