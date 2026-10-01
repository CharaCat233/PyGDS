# 职责: except 内抛新异常被外层捕获
# 比对: same_output


new_exc_caught = False
try:
    try:
        raise ValueError("original")
    except ValueError:
        raise RuntimeError("new from handler")
except RuntimeError:
    new_exc_caught = True
print(new_exc_caught)
