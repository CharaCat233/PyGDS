# duty: ascii() 的非 ASCII 转义与各类型 repr 形态
# 比对: same_output

print(ascii("abc"))
print(ascii("a\nb"))
print(ascii("é"))
print(ascii("中"))
print(ascii("aé中"))
print(ascii("\U0001F600"))
print(ascii([1, "é"]))
print(ascii(None), ascii(123))
