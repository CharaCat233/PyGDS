# 职责: globals() 活视图四方法与删除
# 比对: same_output

# globals() 的 get/pop/setdefault/update 此前读写内部快照,
# del 触发引擎级错误且静默 no-op——改为经环境代理直写活字典

x = 5
y = 6


def f():
    g = globals()
    # get 读活字典 (此前读陈旧快照得 None)
    print(g.get("x"))
    print(g.get("nope"))
    print(g.get("nope", 99))

    # setdefault 写入活字典 (此前写入丢失)
    g.setdefault("gk", 1)
    print(gk)
    print(g.setdefault("gk", 999))
    print(gk)

    # 下标写入 + 删除 (此前 del 引擎级错误)
    g["gk2"] = 2
    print(gk2)
    del g["gk2"]
    print("gk2" in g)

    # pop 真删除 (此前 KeyError 或删除丢失)
    g.setdefault("pk", 42)
    print(g.pop("pk"))
    print("pk" in g)
    print(g.pop("nope", -1))

    # update 写入活字典
    g.update({"uk": 7})
    print(uk)
    g.update(uk2=8)
    print(uk2)
    g.update([("uk3", 9)])
    print(uk3)

    # 全部写后可见
    print(g["uk"], g["uk2"], g["uk3"])


f()

# 删除后模块级确实消失 (在函数外验证)
print("gk" in globals())
print("uk" in globals())

# 空 globals 操作
g2 = globals()
print(g2.pop("definitely_not_here", "dflt"))

# del globals()[name] 复核 (确认真实删除 + dunder 直调路径)
g3 = globals()
g3["dx"] = 1
del g3["dx"]
print("dx" in globals())
try:
    del g3["missing_dx"]
except KeyError as e:
    print("KE:", e)
g3["dy"] = 2
globals().__delitem__("dy")
print("dy" in globals())
try:
    globals().__delitem__("missing_dy")
except KeyError as e:
    print("KE2:", e)

# globals() 为真 dict, 可承载非 str 可哈希键 (CPython 同)
g = globals()
g[5] = 1
print(g[5], g.get(5), 5 in g)
del g[5]
print(5 in g)
g.setdefault(7, "seven")
print(g[7])
print(7 in g)
del g[7]
g.update({9: "nine"})
print(g[9])
print(9 in g)
del g[9]
