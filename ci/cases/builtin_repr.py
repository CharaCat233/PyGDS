# 职责: repr(None) 与内建类型 repr
# 比对: same_output

# repr(None) 与内建类型的 repr

print(repr(None))
print(str(None), [None], {1: None})
print(repr(repr(None)))
print("%s" % None, "{}".format(None))


# str repr 转义 ASCII 控制字符 (C0 全集 + DEL 按 \xNN)
print(repr("a\x07b"))  # 'a\x07b'
print(repr("a\x01b"))  # C0 其余亦转义 (\x01)
print(repr("a\x1fb"))  # 'a\x1fb'
print(repr("a\x7fb"))  # 'a\x7fb'
print(repr(["a\x07b"]))  # ['a\x07b']
print(repr(("a\x0bb",)))  # ('a\x0bb',)
