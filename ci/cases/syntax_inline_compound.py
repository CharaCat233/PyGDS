# 职责: 行内复合语句分号归属与 else 接续
# 比对: same_output

# 行内复合语句体: 分号归属与 else/elif 接续 (alpha.5, P1-66)
if False: a = 1; b = 2
print("a" in dir(), "b" in dir())
x = 1
if x: print("t")
elif x == 2: print("e")
else: print("f")
if x: print("t2"); print("t3")
else: print("skip")
y = 0
while y: print("never")
else: print("we")
for i in range(2): print(i)
else: print("fe")
try: v = int("5")
except ValueError: v = 0
print(v)
if True: c1 = 1; c2 = 2; c3 = c1 + c2
print(c3)
