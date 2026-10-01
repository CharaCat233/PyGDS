# 职责: for...else 正常结束与 break 的执行
# 比对: same_output


# else 在正常完成时执行
found = False
for i in range(3):
    if i == 10:
        found = True
        break
else:
    print("not found")        # not found

# else 在 break 时不执行
found = False
for i in range(5):
    if i == 2:
        print("found at", i)  # found at 2
        break
else:
    print("not found")

# for...else with empty iterable
for i in []:
    print("loop")
else:
    print("empty else")       # empty else

print("done")
