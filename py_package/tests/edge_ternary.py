# Edge: 三目运算符嵌套结合性

print(1 if True else 2)           # 1
print(1 if False else 2)          # 2
print(1 if True else 2 if True else 3)   # 1 (右结合)
print(1 if False else 2 if True else 3)  # 2
print(1 if False else 2 if False else 3) # 3
print((1 if False else 2) if True else 3) # 2 (括号改变结合性)
print(1 if 0 else 2)              # 2 (0 为假)
print(1 if [] else 2)             # 2
print(1 if None else 2)           # 2
print(1 if "a" else 2)            # 1
print("a" if True else "b" + "c") # a (条件为真时不求值 else)