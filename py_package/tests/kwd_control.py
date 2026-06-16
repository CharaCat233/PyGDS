# Keyword: if/elif/else, for/while, break/continue

for i in range(5):
    if i == 2:
        continue
    elif i == 4:
        break
    elif i == 3:
        print(i + 10)
    else:
        print(i)

x = 0
while x <= 2:
    x = x + 1
    print(x)
