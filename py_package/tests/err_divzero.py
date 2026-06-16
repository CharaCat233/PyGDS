# Error: 除零捕获

caught_div = False
try:
    x = 1 / 0
except:
    caught_div = True
print(caught_div)
