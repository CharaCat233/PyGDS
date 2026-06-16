# Error: finally 始终执行

finally_ran = False
try:
    x = 1
finally:
    finally_ran = True
print(finally_ran)
