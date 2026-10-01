# 职责: 生成器表达式产出元组元素与 *args 消费
# 比对: same_output


print(list((x, y) for x in range(2) for y in range(2)))
print(list((x, x) for x in range(2)))
print(sum(x for x in range(3)))
print(list([x, x] for x in range(2)))
def f(*a):
    print(len(a))
f(x for x in range(2))
