# Edge: 扩展字符串方法

print("hello".capitalize())            # Hello
print("HELLO".casefold())              # hello
print("hello world".title())           # Hello World
print("Hello".swapcase())              # hELLO
print("aaa".count("a"))                # 3
print("aaa".count("a", 1))             # 2
print("aaa".count("a", 0, 2))          # 2
print("hello".isdigit())               # False
print("123".isdigit())                 # True
print("hello".isalpha())               # True
print("hello123".isalpha())            # False
print("hello".isalnum())               # True
print("   ".isspace())                 # True
print("hello".islower())               # True
print("HELLO".isupper())               # True
print("Hello".istitle())               # True
print("hello".center(10))              # '  hello   '
print("hello".center(10, "-"))         # '--hello---'
print("hello".ljust(10))               # 'hello     '
print("hello".rjust(10))               # '     hello'
print("hello".zfill(10))               # '00000hello'
print("  hello  ".strip())             # hello
print("done")