# 职责: 迭代中增删字典键触发可捕获 RuntimeError
# 比对: same_output


d = {"a": 1}
it = iter(d)
d["b"] = 2
try:
    list(it)
except RuntimeError as e:
    print('caught:', str(e))

d2 = {"x": 1, "y": 2}
caught = False
try:
    for k in d2:
        d2.pop(k)
except RuntimeError:
    caught = True
print(caught)

d3 = {"a": 1}
d3["a"] = 9
n = 0
for k in d3:
    n += d3[k]
print(n)
print('done')
