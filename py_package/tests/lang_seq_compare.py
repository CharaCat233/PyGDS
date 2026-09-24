# Feature: list/tuple 字典序比较; sorted/min/max 的 key 参数; 比较失败明确报错

print((1,) < (3,))
print([1] < [3])
print((1, 2) < (1, 3))
print([2] > [1, 99])
print([1, 2] <= [1, 2])
print([1, 2] >= [1, 2])
print((1, 'a') < (1, 'b'))
print([True, 2] < [1, 3])
print((1,) < (1, 0))

print(sorted([(2, 'b'), (1, 'a')]))
print(sorted([[2, 'b'], [1, 'a']]))
print(sorted([(3,), (1,), (2,)]))
print(max([(2, 'b'), (1, 'a')]))
print(min([(2, 'b'), (1, 'a')]))

print(max([1, 2, 3], key=lambda x: -x))
print(min([1, 2, 3], key=lambda x: -x))
print(max('ba', 'ab', key=lambda s: s[1]))
print(max([(1, 9), (2, 0)], key=lambda t: t[0]))

try:
    sorted([1, 'a'])
except TypeError:
    print('TE1')
try:
    min([1, 'a'])
except TypeError:
    print('TE2')
l = [1, 'a']
try:
    l.sort()
except TypeError:
    print('TE3')
