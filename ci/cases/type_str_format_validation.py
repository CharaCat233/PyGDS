# duty: format/f-string 类型×说明符校验与数值边界 (inf/nan/-0.0/bool 数值化), str.rsplit/title/istitle 数字分隔语义
# 比对: same_output
def show(label, fn):
    try:
        print(label, "OK", repr(fn()))
    except Exception as e:
        print(label, type(e).__name__)

# === 类型×说明符兼容性 (CPython: int 拒 's', float 拒 b/c/d/o/x/X/s, str 拒数值, 容器拒任何说明符) ===
show("int s", lambda: format(42, "s"))
show("bool s", lambda: format(True, "s"))
show("float d", lambda: format(3.5, "d"))
show("float x", lambda: format(3.5, "x"))
show("float c", lambda: format(3.5, "c"))
show("str d", lambda: format("hi", "d"))
show("str x", lambda: format("hi", "#x"))
show("list d", lambda: format([1], "d"))
show("list s", lambda: format([1], "s"))
show("list w", lambda: format([1], "10"))
show("tuple f", lambda: f"{(1, 2):f}")
dd = {"a": 1}
show("dict x", lambda: f"{dd:x}")
# 合法组合不受影响
print("int f", format(42, "f"))
print("int e", format(42, "e"))
print("int %", format(42, "%"))
print("int c", format(65, "c"))
print("int #x", format(255, "#x"))
print("float e", format(3.5, ".3e"))
print("str s", format("hi", "s"))

# === bool 按数值格式化 (符号/备用/对齐/零填充) ===
print("bool #x", format(True, "#x"))
print("bool #o", format(False, "#o"))
print("bool +d", format(True, "+d"))
print("bool sp", format(True, " d"))
print("bool w", format(True, "10"))
print("bool #010x", format(True, "#010x"))

# === inf/nan 格式化 (含 E/F/G 大写与 % 后缀) ===
print("inf f", format(float("inf"), "f"))
print("inf e", format(float("inf"), "e"))
print("inf g", format(float("inf"), "g"))
print("inf %", format(float("inf"), "%"))
print("inf G", format(float("inf"), "G"))
print("inf E", format(float("inf"), "E"))
print("inf F", format(float("inf"), "F"))
print("inf w", format(float("inf"), ">8"))
print("inf +", format(float("inf"), "+f"))
print("ninf f", format(float("-inf"), "f"))
print("nan f", format(float("nan"), "f"))
print("nan G", format(float("nan"), "G"))

# === -0.0 在 e/g/f 保持符号 ===
print("nz e", format(-0.0, "e"))
print("nz g", format(-0.0, "g"))
print("nz G", format(-0.0, "G"))
print("nz .3e", format(-0.0, ".3e"))
print("nz f", format(-0.0, "f"))

# === str.rsplit 默认空白分割 / 顺序 / maxsplit ===
print("rs1", "Hello World".rsplit())
print("rs2", "line1\nline2".rsplit())
print("rs3", "a  b  c".rsplit(None, 1))
print("rs4", "a  b  c".rsplit(None, 2))
print("rs5", "a,b,c".rsplit(","))
print("rs6", "a,b,c".rsplit(",", 1))
print("rs7", "  a  b  ".rsplit())
print("rs8", "".rsplit())

# === str.title / istitle 数字分隔语义 ===
print("t1", "hello world".title())
print("t2", "hell0 w0rld".title())
print("t3", "a1b".title())
print("t4", "123abc def".title())
print("it1", "12345".istitle())
print("it2", "A1B".istitle())
print("it3", "Mixed Case".istitle())
print("it4", "a1b".istitle())
print("it5", "Hello World".istitle())
