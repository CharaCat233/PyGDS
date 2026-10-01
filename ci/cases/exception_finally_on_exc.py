# 职责: 异常被处理后外层 finally 仍执行
# 比对: same_output


finally_ran2 = False
try:
    try:
        raise RuntimeError("boom")
    except RuntimeError:
        _ = 1
finally:
    finally_ran2 = True
print(finally_ran2)
