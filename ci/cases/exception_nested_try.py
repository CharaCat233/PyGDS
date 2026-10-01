# 职责: 嵌套 try 由内层按类型捕获
# 比对: same_output


inner_matched = False
outer_matched = False
try:
    try:
        raise ValueError("nested test")
    except TypeError:
        outer_matched = True
    except ValueError:
        inner_matched = True
except:
    outer_matched = True
print(inner_matched, outer_matched)
