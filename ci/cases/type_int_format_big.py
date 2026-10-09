# duty: 大数 (> int64) 在 f-string / format / str.format 数值分支的格式化 (x/X/o/b/c/d/f/e/g/%, 异常类比对)
# 比对: same_output
big = 0xFFFF_FFFF_FFFF_FFFF_FFFF_FFFF  # 96-bit, 超出 int64
huge = 10**400  # 超出 double 范围

def show(label, fn):
    try:
        print(label, "OK", fn())
    except Exception as e:
        print(label, type(e).__name__)

# x/X/o/b: 输出正确进制 (含 # 备用形式与 _ 分组)
print("fx", f"{big:x}")
print("fX", f"{big:X}")
print("fo", f"{big:o}")
print("fb", f"{big:b}")
print("fmtx", format(big, "x"))
print("fmtX", format(big, "X"))
print("fmto", format(big, "o"))
print("fmtb", format(big, "b"))
print("fmt#x", format(big, "#x"))
print("f#X", f"{big:#X}")
print("fmt#o", format(big, "#o"))
print("f#b", f"{big:#b}")
print("fmt_x", format(big, "_x"))
print("negx", f"{-big:x}")
print("neg#x", f"{-big:#x}")
print("fmt#bneg", format(-big, "#b"))
# d: 十进制与千分位
print("fd", f"{big:d}")
print("f,d", f"{big:,d}")
# c: 大数报 OverflowError (异常类比对, C long 边界为平台差异)
show("fc", lambda: f"{big:c}")
show("fmtc", lambda: format(big, "c"))
# f/e/g/%: 可转 float 时正常输出
print("ff", f"{big:f}")
print("fmtf", format(big, "f"))
print("fe", f"{big:e}")
print("fg", f"{big:g}")
print("fpct", f"{big:%}")
# 超出 double 范围: OverflowError
show("hugef", lambda: f"{huge:f}")
show("hugee", lambda: f"{huge:e}")
show("hugeg", lambda: format(huge, "g"))
show("hugepct", lambda: f"{huge:%}")
# 大 float 定点格式化 (连带修复 _fixed_format_parts)
print("bigfloat", f"{1e30:f}")
print("bigfloat2", format(79228162514264337593543950336.0, "f"))
# format() 内建的错误传播 (last_error 不再被吞)
show("fmt,s", lambda: format(1, ",s"))
show("fmt,x", lambda: format(255, ",x"))
