# 职责: 内层类型不匹配异常向外层传播
# 比对: same_output


mismatch_caught = False
mismatch_outer = False
try:
    try:
        raise ValueError("mismatch")
    except TypeError:
        mismatch_caught = True
except:
    mismatch_outer = True
print(mismatch_caught, mismatch_outer)
