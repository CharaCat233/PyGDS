# Feature: 切片赋值与切片删除 (含扩展切片)

a = [1, 2, 3, 4]
del a[1:3]
print(a, len(a))

b = [1, 2, 3, 4]
b[1:3] = [9]
print(b)

c = [1, 2, 3, 4]
c[1:3] = [9, 8, 7]
print(c)

d = [1, 2, 3, 4, 5]
del d[::2]
print(d)

e = [0, 1, 2, 3, 4]
e[::2] = [7, 8, 9]
print(e)

f = [1, 2, 3, 4]
del f[-3:-1]
print(f)

g = [1, 2, 3]
g[5:9] = [8, 9]
print(g)

h = [1, 2, 3, 4]
h[::-1] = [1, 2, 3, 4]
print(h)

i2 = [1, 2, 3, 4]
del i2[:]
print(i2)

try:
    a[1:3] = 5
except TypeError:
    print('TE')
try:
    b[::2] = [1, 2]
except ValueError as ex:
    print('VE')
try:
    del t3
except NameError:
    print('NE')
t3 = (1, 2, 3)
try:
    del t3[1:2]
except TypeError:
    print('TT')
s = 'abc'
try:
    del s[1:2]
except TypeError:
    print('TS')
