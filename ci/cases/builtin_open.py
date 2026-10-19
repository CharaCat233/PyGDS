# duty: open() 的文本/二进制读写/行迭代/seek 与异常文案
# 比对: same_output

fh = open("ci_open_case_data.tmp", "w")
print(fh.writable(), fh.readable())
fh.write("line1\n")
fh.write("line2\n")
fh.close()
print(fh.closed)
fh = open("ci_open_case_data.tmp")
print(fh.read())
fh.close()
fh = open("ci_open_case_data.tmp")
print(fh.readline())
print(fh.readline())
print(fh.readline())
fh.close()
fh = open("ci_open_case_data.tmp")
print(fh.readlines())
fh.close()
fh = open("ci_open_case_data.tmp")
print(list(fh))
fh.close()
fh = open("ci_open_case_data.tmp")
print(fh.seek(0), fh.readline())
fh.close()
lines = []
fh = open("ci_open_case_data.tmp")
for line in fh:
    lines.append(line.strip())
fh.close()
print(lines, len(lines))
fh = open("ci_open_case_data.tmp", "a")
fh.write("line3\n")
fh.close()
fh = open("ci_open_case_data.tmp")
print(fh.readline(), fh.readline(), fh.readline())
fh.close()
fw = open("ci_open_case_data2.tmp", "wb")
fw.writelines([b"x\n", b"y\n"])
fw.close()
fr = open("ci_open_case_data2.tmp", "rb")
print(fr.read())
fr.close()
fb = open("ci_open_case_data2.tmp", "rb")
data = fb.read()
print(type(data).__name__, data)
try:
    fb.write(b"z")
except Exception as e:
    print("WB:", type(e).__name__)
fb.close()
mvb = bytearray(b"hi")
fb2 = open("ci_open_case_data3.tmp", "wb")
fb2.write(mvb)
fb2.close()
fb3 = open("ci_open_case_data3.tmp", "rb")
print(fb3.read())
fb3.close()
try:
    open("_pgds_nonexistent_xyz.tmp")
except FileNotFoundError as e:
    print("FNF:", e)
try:
    open("ci_open_case_data.tmp", "q")
except ValueError as e:
    print("VM:", e)
try:
    fh = open("ci_open_case_data.tmp")
    fh.write("x")
    fh.close()
except Exception as e:
    print("RO:", type(e).__name__)
try:
    fh = open("ci_open_case_data.tmp")
    fh.close()
    fh.read()
except ValueError as e:
    print("CL:", e)
print(fh.name, fh.mode)

# 二进制 readline 返回 bytes; writelines 返回 None; 大数 read size 报 OverflowError
fb = open("i89_case_data.tmp", "wb")
fb.write(b"ab\ncd\n")
print(fb.writelines([b"x", b"y"]))
fb.close()
fb = open("i89_case_data.tmp", "rb")
print(fb.readline())
print(fb.readline())
print(fb.readline())
fb.close()
fb = open("i89_case_data.tmp", "rb")
try:
    print(fb.read(10**30))
except OverflowError as e:
    print("OE:", e)
fb.close()
ft = open("i89_case_data.tmp", "w")
print(ft.writelines(["z"]))
ft.close()
print(repr(open("i89_case_data.tmp").read()))
fb = open("i89_case_data.tmp", "rb")
print(fb.read(2))
fb.close()


# 模式白名单 (r+/wt) 与文件对象权限模型
p47 = "i147_data.tmp"
fh = open(p47, "w")
fh.write("hello")
print(fh.tell())
print(fh.seek(0))
print(fh.seekable())
print(fh.isatty())
print(fh.readable(), fh.writable())
fh.close()
# r+ 合法且可读可写 (文本读缓冲模型的写后读不走, 只验证权限与读)
fh = open(p47, "r+")
print(fh.readable(), fh.writable())
print(fh.read())
print(fh.seek(0))
print(fh.tell())
fh.close()
# wt 合法
fh = open(p47, "wt")
print(fh.writable(), fh.readable())
fh.write("abc")
fh.close()
print(open(p47).read())
# x 模式对已存在文件报 FileExistsError
fh = open(p47, "w")
fh.close()
try:
    open(p47, "x")
except FileExistsError as e:
    print("FEE:", type(e).__name__)
# closed 后 readable/writable 报 ValueError
fh = open(p47)
fh.close()
try:
    fh.readable()
except ValueError as e:
    print("VE-r:", e)
print("W-closed:", fh.writable())
# 文本模式 seek(1,1) 拒
fh = open(p47)
try:
    fh.seek(1, 1)
except OSError as e:
    print("OS-seek:", type(e).__name__)
print(fh.seek(0, 1))
fh.close()
# truncate
fh = open(p47, "w")
fh.write("0123456789")
fh.close()
fh = open(p47, "r+")
print(fh.truncate(4))
print(open(p47).read())
fh.close()
# writelines 接受生成器
fh = open(p47, "w")
fh.writelines(x + "\n" for x in ["a", "b"])
fh.close()
print(open(p47).read())
# 非法模式
try:
    open(p47, "zq")
except ValueError as e:
    print("VE-mode:", e)

# r+ 写后读: 写路径使文本读缓冲失效 (读全量 → 写 → seek → 读得新内容)
d99 = "i099_rw.tmp"
fh = open(d99, "w")
fh.write("hello")
fh.close()
fh = open(d99, "r+")
print(fh.read())
fh.seek(0)
fh.write("X")
fh.seek(0)
print(fh.read())
fh.close()
print(open(d99).read())

# 写后未 seek 直接读: 从写入落点续读
fh = open(d99, "r+")
fh.seek(0)
fh.write("Z")
print(fh.read())
fh.close()

# writelines 后读
fh = open(d99, "r+")
fh.seek(0)
fh.writelines(["ab", "cd"])
fh.seek(0)
print(fh.read())
fh.close()

# truncate 后同句柄读
fh = open(d99, "r+")
fh.read()
fh.seek(0)
fh.truncate(3)
fh.seek(0)
print(fh.read())
fh.close()

# with 块内混合读写
with open(d99, "r+") as w:
    w.write("AA")
    w.seek(0)
    print(w.read())
    w.write("BB")
    w.seek(0)
    print(w.read())
    print(w.tell())
print(open(d99).read())

# a+ 追加写后读 (追加保持尾随)
fh = open(d99, "a+")
fh.write("!")
fh.seek(0)
print(fh.read())
fh.close()
print(open(d99).read())
