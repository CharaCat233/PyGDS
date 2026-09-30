# 相邻字符串字面量连接 (alpha.4, P1-63)
print("ab" "cd", "a" "b" "c")
print(("p"
       "q"))
print("a" \
      "b")
print(b"p" b"q")
print(f"a{1}" "b", "x" f"{2}y", f"{1}" f"{2}")
print("ab" "cd".upper())
d = {"a" "b": 1}
print(d["ab"])
print(r"a\n" "b")
print(u"a" "b")
print("long" "tail" == "longtail", "%s %d" "%x" == "%s %d %x")
