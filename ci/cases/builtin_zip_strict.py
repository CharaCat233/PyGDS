# 职责: zip strict 长度校验报错
# 比对: same_output

# zip 的 strict 参数 (P2-26)
try:
    list(zip([1, 2], [3], strict=True))
except ValueError as e:
    print(e)
try:
    list(zip([1], [2, 3], strict=True))
except ValueError as e:
    print(e)
print(list(zip([1, 2], [3, 4], strict=True)))
print(list(zip([1], strict=True)))
print(list(zip(strict=True)))
try:
    list(zip([1, 2], [3], [4, 5], strict=True))
except ValueError as e:
    print(e)
try:
    list(zip([1], [2], [3, 4], [5, 6], strict=True))
except ValueError as e:
    print(e)
try:
    list(zip([1], [2], [3], [4, 5], strict=True))
except ValueError as e:
    print(e)
try:
    list(zip([1, 2], [3], [4], strict=True))
except ValueError as e:
    print(e)
try:
    list(zip([1, 2], [3], strict=1))
except ValueError as e:
    print(e)
print(list(zip([1, 2], [3], strict=False)))
try:
    list(zip("ab", [1], strict=True))
except ValueError as e:
    print(e)
