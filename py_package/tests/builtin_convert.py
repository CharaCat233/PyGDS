# Builtin: int / float / bool 转换


n1 = int(50)
n2 = 50
m1 = float(2.0)
m2 = 2.0
t1 = bool(True)
t2 = True
f1 = bool(False)
f2 = False
bd = bool()

print(n1 == 50)
print(n1 == int(50))
print(n1 == int(50.0))
print(n2 == 50)
print(n2 == int(50))
print(n2 == int(50.0))

print(m1 == 2.0)
print(m1 == float(2.0))
print(m1 == float(2))
print(m2 == 2.0)
print(m2 == float(2.0))
print(m2 == float(2))

print(t1 == True)
print(t2 == True)
print(f1 == True)
print(f2 == True)
print(bd == True)
print(t1 == bool(True))
print(t2 == bool(True))
print(f1 == bool(True))
print(f2 == bool(True))
print(bd == bool(True))
print(t1 == False)
print(t2 == False)
print(f1 == False)
print(f2 == False)
print(bd == False)
print(t1 == bool(False))
print(t2 == bool(False))
print(f1 == bool(False))
print(f2 == bool(False))
print(bd == bool(False))
print(t1 == bool())
print(t2 == bool())
print(f1 == bool())
print(f2 == bool())
print(bd == bool())

print(10 + 20)
print(10 + int(20))
print(int(10) + 20)
print(int(10) + int(20))

res = 10 + 10
print(res, type(res))  # int + int
res = 10.0 + 10.0
print(res, type(res))  # float + float
res = 10 + 10.0
print(res, type(res))  # int + float
res = 10.0 + 10
print(res, type(res))  # float + int

res = 10 - 10
print(res, type(res))  # int - int
res = 10.0 - 10.0
print(res, type(res))  # float - float
res = 10 - 10.0
print(res, type(res))  # int - float
res = 10.0 - 10
print(res, type(res))  # float - int

res = 10 * 10
print(res, type(res))  # int * int
res = 10.0 * 10.0
print(res, type(res))  # float * float
res = 10 * 10.0
print(res, type(res))  # int * float
res = 10.0 * 10
print(res, type(res))  # float * int

res = 10 / 10
print(res, type(res))  # int / int
res = 10.0 / 10.0
print(res, type(res))  # float / float
res = 10 / 10.0
print(res, type(res))  # int / float
res = 10.0 / 10
print(res, type(res))  # float / int

res = 10 // 10
print(res, type(res))  # int // int
res = 10.0 // 10.0
print(res, type(res))  # float // float
res = 10 // 10.0
print(res, type(res))  # int // float
res = 10.0 // 10
print(res, type(res))  # float // int

res = 10 % 10
print(res, type(res))  # int % int
res = 10.0 % 10.0
print(res, type(res))  # float % float
res = 10 % 10.0
print(res, type(res))  # int % float
res = 10.0 % 10
print(res, type(res))  # float % int

res = 10 ** 10
print(res, type(res))  # int ** int
res = 10.0 ** 10.0
print(res, type(res))  # float ** float
res = 10 ** 10.0
print(res, type(res))  # int ** float
res = 10.0 ** 10
print(res, type(res))  # float ** int
