# 职责: 比较链 a<b<c 的结合求值
# 比对: same_output


print(1 < 2 < 3)           # True
print(1 < 2 > 3)           # False
print(3 > 2 > 1)           # True
print(1 < 2 == 2)          # True
print(1 == 2 < 3)          # False
print(5 > 3 < 4)           # True
print(5 > 3 > 1)           # True
print(1 < 2 < 3 < 4)       # True
print(1 <= 1 < 2)          # True
print(1 < 2 >= 2)          # True

# 中间操作数只求值一次
calls = []
def side(x):
    calls.append(x)
    return x

print(side(1) < side(2) < side(3))
print(len(calls), calls == [1, 2, 3])
