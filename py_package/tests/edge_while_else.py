# Edge: while...else

# else 在正常退出时执行
x = 0
while x < 3:
    print(x)
    x = x + 1
else:
    print("else")             # else

# else 在 break 时不执行
y = 0
while True:
    if y == 2:
        break
    print(y)
    y = y + 1
else:
    print("not reached")

print("done")
