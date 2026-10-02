# duty: complex 类型与 1j 字面量的构造/算术/比较/字典键
# 比对: same_output

print(1j, 2j, 1 + 2j, 3 - 4j)
print(-2j)
print(complex(3), complex(3, 4), complex("3+4j"), complex("(1+2j)"), complex("j"))
print(complex(2j))
print(complex())
print(1j * 1j)
print((1 + 2j) * (3 + 4j))
print((1 + 2j) / (3 + 4j))
print(abs(3 + 4j))
print((1 + 2j).real, (1 + 2j).imag)
print((1 + 2j).conjugate())
print(1 + 0j == 1, (1 + 2j) == (1 + 2j), (1 + 2j) != 3, 1j == 1.0)
print(bool(0j), bool(1j))
print(str(1 + 2j))
print((1 + 2j) ** 2)
print((1 + 2j) - 1, (1 + 2j) / 2, 1 / (1j))
print(True + 1j, 2 * 3j, 10 - 2j / 2)
print({1 + 0j: "a"}[1])
print({3 + 4j: "b"}[3 + 4j])
d = {}
d[1 + 2j] = "x"
print(d[complex(1, 2)])
s = {1j, 1j, 2j}
print(len(s))
print(type(1j).__name__)
print(isinstance(2 + 3j, complex))
try:
    int(1j)
except TypeError as e:
    print("TE1:", e)
try:
    float(1j)
except TypeError as e:
    print("TE2:", e)
try:
    1 < 2j
except TypeError as e:
    print("TE3:", e)
try:
    (1 + 2j) // 2
except TypeError as e:
    print("TE4:", e)
try:
    divmod(1 + 2j, 3)
except TypeError as e:
    print("TE5:", e)
try:
    complex(None)
except TypeError as e:
    print("TE6:", e)
try:
    complex(1, "x")
except TypeError as e:
    print("TE7:", e)
try:
    complex("abc")
except ValueError as e:
    print("VE1:", e)
try:
    1 / 0j
except ZeroDivisionError as e:
    print("ZD:", e)
try:
    0j ** -1
except ZeroDivisionError as e:
    print("ZD2:", e)
x = 1 + 2j
x += 1
print(x)
print(1j * 1j == -1)
sq = (0.5 + 0.5j) ** 2
print(round(sq.real, 6), round(sq.imag, 6))
print(ascii(1j))
