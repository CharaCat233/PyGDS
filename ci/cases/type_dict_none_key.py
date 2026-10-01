# 职责: None 作字典键的存取与相等
# 比对: same_output


d = {None: 1}
print(d)
print(d[None])
print(None in d)
print(list(d))
d[None] = 2
print(d[None], len(d))
d2 = {'n': 1}
print(d2)
print({None: 1} == {'n': 1})
