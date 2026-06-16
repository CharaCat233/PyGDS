# Error: 多个 except 子句

caught_right = False
caught_wrong = False
try:
    raise ValueError("val error")
except TypeError:
    caught_wrong = True
except ValueError:
    caught_right = True
print(caught_right, caught_wrong)
