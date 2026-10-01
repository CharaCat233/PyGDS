# 职责: except Exception 捕获子类异常
# 比对: same_output


base_caught = False
try:
    raise TypeError("subclass")
except Exception:
    base_caught = True
print(base_caught)
