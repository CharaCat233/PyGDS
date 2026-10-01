# 职责: 同引号嵌套、多行字段与注释等 PEP 701 形态
# 比对: same_output


d = {"k": 1, "": 5}
x = 42
w = 8
s = "it's"

print(f"{d["k"]}")
print(f"{d['k']} and {d["k"]}")
print(f"{d[""]}")
print(f"nested {f"{x}"} end")
print(f"{f"{d["k"]}"}")
print(f"""triple {d["k"]}""")
print(f"""{d["""k"""]}""")
print(f'{"it\'s"} {f"{s}"}')
print(f"{d["k"]}{d["k"]}")
print(f"{ {1: 2} }")
print(f"{rf"{x}"}")
print(f"{f"{x!r}":>{w}}")
print(f"{x:>{'8'}}")

print(f"{1 != 2}")
a = [10, 20, 30]
print(f"{a[1:2]}")
print(f"{x!r:>3}")
print(f"{x!r:>{w}}")
print(f"\"")
print(f"{x=}")
print(f"""{
x + 1
}""")
print(f"""{
    x +
    1
}""")
print(f"""{
# comment inside the field
x + 1
}""")
print(f'{x +
1}')
print(f"""{
    (lambda v: v * 2)(4)
}""")
