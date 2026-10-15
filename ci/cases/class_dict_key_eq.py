# 职责: 用户类 dict/set 键的「哈希 + 相等」分桶
# 比对: same_output

# 同哈希不等对象此前静默覆盖 (dict 键只按 hash 值分桶, __eq__ 不参与)
# 改为同哈希槽位逐个 __eq__ 甄别, 不等者开新槽


class HK:
    def __init__(self, v):
        self.v = v

    def __hash__(self):
        return 1

    def __eq__(self, o):
        return isinstance(o, HK) and self.v == o.v

    def __repr__(self):
        return "HK(%d)" % self.v


d = {}
d[HK(1)] = "a"
d[HK(2)] = "b"
print(len(d))
print(d[HK(1)])
print(d[HK(2)])
print(HK(3) in d)
print(len({HK(1): 1, HK(2): 2}))

# 相等对象命中同槽 (覆盖语义)
d2 = {HK(1): 1}
d2[HK(1)] = 9
print(len(d2), d2[HK(1)])

# 集合同站点
s = {HK(1), HK(2), HK(1)}
print(len(s))
print(HK(1) in s)


# __hash__ 返回大数 (value 恒 0): 同桶对象仍由相等甄别
class HB:
    def __init__(self, v):
        self.v = v

    def __hash__(self):
        return 10**30

    def __eq__(self, o):
        return isinstance(o, HB) and self.v == o.v

    def __repr__(self):
        return "HB(%d)" % self.v


dh = {HB(1): "a", HB(2): "b"}
print(len(dh))
print(dh[HB(1)], dh[HB(2)])
sh = {HB(1), HB(2)}
print(len(sh))

# 同哈希且相等: 去重 (此前大数哈希全同导致误合并)
d3 = {}
k1 = HB(1)
k2 = HB(1)
d3[k1] = "x"
d3[k2] = "y"
print(len(d3), d3[k1])


# 不可哈希报错路径不受影响
class Unhash:
    def __eq__(self, o):
        return True


try:
    d4 = {}
    d4[Unhash()] = 1
except TypeError as e:
    print("TE", str(e))
