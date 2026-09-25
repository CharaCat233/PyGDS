# repr(None) 与内建类型的 repr

print(repr(None))
print(str(None), [None], {1: None})
print(repr(repr(None)))
print('%s' % None, '{}'.format(None))
