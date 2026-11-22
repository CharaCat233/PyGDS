# 职责: 编码类异常与 SyntaxError 的结构化 args 与属性面
# 比对: same_output

try:
    "héllo".encode("ascii")
except UnicodeEncodeError as e:
    print(e.args)
    print(e.encoding, e.object, e.start, e.end, e.reason)
    print(str(e))

try:
    b"h\xc3\xa9llo".decode("ascii")
except UnicodeDecodeError as e:
    print(e.args)
    print(e.encoding, e.start, e.end, e.reason)
    print(e.object)

try:
    b"h\xc3\xa9llo".decode("utf-8")
except UnicodeDecodeError as e:
    print(e.args)

try:
    compile("def bad(a=1, b): pass", "<t>", "exec")
except SyntaxError as e:
    print(e.msg)
    print(e.filename, e.lineno, e.offset, e.end_lineno, e.end_offset)
    print(repr(e.text), repr(str(e)))

s = SyntaxError("manual")
print(s.msg, s.filename, s.lineno, s.offset, s.text)
print(repr(s))
