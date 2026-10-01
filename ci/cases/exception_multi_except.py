# 职责: 多个 except 子句按序命中正确分支
# 比对: same_output


caught_right = False
caught_wrong = False
try:
    raise ValueError("val error")
except TypeError:
    caught_wrong = True
except ValueError:
    caught_right = True
print(caught_right, caught_wrong)
