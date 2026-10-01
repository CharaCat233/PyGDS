# 职责: 仅 try/finally 无 except 的流程
# 比对: same_output


finally_only = 0
try:
    finally_only = 1
finally:
    finally_only = 2
print(finally_only)
