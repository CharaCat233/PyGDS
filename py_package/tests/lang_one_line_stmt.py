# Feature: 单行复合语句支持全部语句类型

if True: pass
print('p1')
while False: pass
print('p2')
def f(): return 1
print(f())
class C: pass
print(C.__name__)
try: pass
except ValueError: print('no')
print('p3')
if True: x = 1
print(x)
if False: pass
else: print('else-after-pass')
for i in range(2): print(i)
def g():
    if True: return 'inner'
print(g())
print('done')
