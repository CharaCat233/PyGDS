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

# index start/end 实参: float/str/None 报 slice indices TypeError, 大数按 ±∞ 钳制
def _arg_exc(label, fn):
    try:
        print(label, repr(fn()))
    except Exception as e:
        print(label, type(e).__name__, str(e))


_arg_exc("ti_float", lambda: (1, 2, 3).index(3, 1.5))
_arg_exc("ti_none", lambda: (1, 2, 3).index(3, 0, None))
_arg_exc("ti_big_start", lambda: (1, 2, 3).index(3, 10**100))
_arg_exc("ti_big_neg_end", lambda: (1, 2, 3).index(1, 0, -10**100))
print((1, 2, 3).index(1, -10**100))
print((1, 2, 3).index(3, 0, 10**100))

# 多余位置实参: CPython 参数数文案
_arg_exc("tcount-2", lambda: (1,).count(1, 2))
