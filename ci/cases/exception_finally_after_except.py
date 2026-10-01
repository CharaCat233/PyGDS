# 职责: except 之后 finally 仍执行并改值
# 比对: same_output


finally_val = 0
try:
    raise ValueError("test")
except ValueError:
    finally_val = 1
finally:
    finally_val = finally_val + 10
print(finally_val)
