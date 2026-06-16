# Error: 嵌套 try-except

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
