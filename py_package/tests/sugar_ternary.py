# Sugar: 三目运算符

print(1 if 2 > 1 else 0)  # 1
print(1 if False else 2)  # 2
print(1 if False else 2 if True else 3)  # 2
print(1 if True else 2 if True else 3)  # 1
print((10 if 5 > 2 else 20) + 5)  # 15
