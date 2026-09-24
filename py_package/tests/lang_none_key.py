# Feature: None 可作字典键

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
