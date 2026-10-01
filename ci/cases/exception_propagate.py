# 职责: 内层未匹配异常传播到外层捕获
# 比对: same_output


caught_outer = False
try:
    try:
        raise ValueError("inner uncaught")
    except TypeError:
        caught_outer = False
except ValueError:
    caught_outer = True
print(caught_outer)
