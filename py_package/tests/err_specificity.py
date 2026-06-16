# Error: 多层特异性匹配

base2_caught = False
mid_caught = False
leaf_caught = False
try:
    x = 1 / 0
except ZeroDivisionError:
    leaf_caught = True
except ArithmeticError:
    mid_caught = True
except Exception:
    base2_caught = True
print(leaf_caught, mid_caught, base2_caught)
