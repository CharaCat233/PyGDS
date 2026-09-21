# string 模块测试 (字符串常量)

import string

# 数字
print(string.digits)                # 0123456789
print(len(string.digits))           # 10
print(string.octdigits)             # 01234567
print(string.hexdigits[:16])        # 0123456789abcdef

# 字母
print(len(string.ascii_lowercase))  # 26
print(len(string.ascii_uppercase))  # 26
print(len(string.ascii_letters))    # 52
print(string.ascii_lowercase[:5])   # abcde
print(string.ascii_uppercase[-5:])  # VWXYZ

# 标点与空白
print(len(string.punctuation))      # 32
print(string.punctuation[:8])       # !"#$%&'(
print(len(string.whitespace))       # 6
print(string.whitespace[0] == " ")  # True (空格)
print("\t" in string.whitespace)    # True (制表符)
print("\n" in string.whitespace)    # True (换行)

# printable 包含数字字母标点空白
print(len(string.printable))        # 100
print(string.ascii_letters in string.printable)  # True

print("done")
