# 职责: str/bytes 转义序列解码与 \N 命名转义
# 比对: same_output

# 含未识别转义/超范围八进制的源码经动态编译求值: CPython 解析期警告走 stderr,
# PyGDS 走 print 通道, 捕获打印后双端 stdout 对齐 (单次 exec 解析, 每字面量告警一次)
have_warnings = False
try:
    import warnings

    have_warnings = True
except ImportError:
    pass


def esc_val(src):
    ns = {}
    if have_warnings:
        with warnings.catch_warnings(record=True) as w:
            warnings.simplefilter("always")
            exec(src, ns)
            for wi in w:
                print(wi.category.__name__ + ": " + str(wi.message))
    else:
        exec(src, ns)
    print(ns["r"])


print(len("\x41"), "\x41")
print(len("\u4e2d"), "\u4e2d")
print(len("\101"), "\101")
print(len("\N{BULLET}"), "\N{BULLET}")
print(ord("\a"), ord("\b"), ord("\f"), ord("\v"))
print("\x412")
print("\U0001F600")
esc_val("r = ('\\8', '\\p', len('\\8'))")
print("cont-ok")

print(len(b"\x41"), list(b"\x41"))
print(len(b"\x00"), list(b"\x00"))
esc_val("r = (list(b'\\xff'), list(b'\\400'))")
esc_val("r = (b'\\u4e2d', len(b'\\u4e2d'))")
esc_val("r = (b'\\N{BULLET}', len(b'\\N{BULLET}'))")
print("\N{LATIN CAPITAL LETTER A}", "\N{SPACE}")
print(chr(92) + "x41" == "\x41")
print(r"\x41" == chr(92) + "x41")
print(len(r"\n"), len("\n"))
