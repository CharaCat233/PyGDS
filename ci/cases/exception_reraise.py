# 职责: 裸 raise 重抛当前异常再次捕获
# 比对: same_output


caught_re = False
try:
    try:
        raise ValueError("to re-raise")
    except ValueError:
        raise
except ValueError:
    caught_re = True
print(caught_re)
