# 职责: 元组字面量各种书写形式与打印
# 比对: same_output


tup1 = 1,
tup2 = 1, 2, 3
tup3 = ()
tup4 = (1,)
tup5 = (1, 2, 3)

print(tup1)
print(tup2)
print(tup3)
print(tup4)
print(tup5)

# tuple.index / tuple.count (此前描述符指向不存在方法, 恒返回 None)
t = (1, 2, 2)
print(t.index(2))
print(t.count(2))
print((1, 2, 2).count(1))
try:
    (1, 2).index(9)
except ValueError as e:
    print("VE:", e)
print(tuple("ab").index("b"))
