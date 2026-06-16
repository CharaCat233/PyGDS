# Error: 裸 except

try:
    raise TypeError("type error")
except:
    print("caught all")
