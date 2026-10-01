# 职责: pass 在类/函数/分支/循环/try 中占位
# 比对: same_output


class Empty:
    pass

def noop():
    pass

if True:
    pass
else:
    pass

for i in range(3):
    if i == 1:
        pass
    else:
        print(i)

x = 0
while x < 3:
    x = x + 1

# pass 在 try 中
try:
    pass
except:
    pass
finally:
    pass

print("done")              # done
