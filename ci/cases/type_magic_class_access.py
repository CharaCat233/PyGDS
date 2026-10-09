# 职责: 内建类型类上魔法方法描述符可访问与调用 (I2-73)
# 比对: same_output

# 类级魔法方法访问与调用: 标量/容器类型类经描述符表挂载, bool/bytes/bytearray/
# set/frozenset 经分发描述符 (args[0] 路由); list/dict/set/frozenset 的
# __getitem__/__contains__ 为 method_descriptor 形态; __str__ 仅 str/bool 安全挂载,
# __hash__/__call__ 不挂载; 实例运算不受挂载影响

print("str.__add__:", str.__add__)
print("str.__add__ call:", str.__add__("a", "b"))
print("str.__str__:", str.__str__)
print("str.__str__ call:", str.__str__("ab"))
print("str.__bool__:", hasattr(str, "__bool__"))
print("int.__eq__:", int.__eq__)
print("int.__bool__:", int.__bool__)
print("int.__bool__ call:", int.__bool__(0))
print("bool.__or__:", bool.__or__)
print("bool.__or__ call:", bool.__or__(True, False))
print("bool.__add__:", bool.__add__)
print("bool.__add__ call:", bool.__add__(True, True))
print("bool.__str__:", bool.__str__)
print("bytes.__add__ call:", bytes.__add__(b"ab", b"cd"))
print("bytes.__mod__ call:", bytes.__mod__(b"%s", b"x"))
print("bytearray.__add__ call:", bytearray.__add__(bytearray(b"a"), bytearray(b"b")))
print("bytearray.__mod__ call:", bytearray.__mod__(bytearray(b"%s"), bytearray(b"x")))
print("set.__repr__ call:", set.__repr__({1, 2}))
print("frozenset.__repr__ call:", frozenset.__repr__(frozenset([1])))

# method-descriptor 形态
print("list.__getitem__:", list.__getitem__)
print("dict.__getitem__:", dict.__getitem__)
print("dict.__contains__:", dict.__contains__)
print("set.__contains__:", set.__contains__)
print("str.__getitem__:", str.__getitem__)
print("list.__contains__:", list.__contains__)

# 实例运算不受挂载影响
print(b"b" in b"abc")
print(b"b" in bytearray(b"abc"))
print(True | False, True & True)
print({1, 2} | {3}, len(bytearray(b"ab")))
print(bytearray(b"ab") * 2)
