# Sugar: 解包赋值

n1, n2, (n3, n4, n5), *more = 0, 1, [2, 3, 4], (5, 6), 7,

print(n1)  # 0
print(n2)  # 1
print(n3)  # 2
print(n4)  # 3
print(n5)  # 4
print(more)  # [(5, 6), 7]

dt = {"a": 10, "b": 20}
for k, v in dt.items():
    print(k, v)  # a 20 / b 20
