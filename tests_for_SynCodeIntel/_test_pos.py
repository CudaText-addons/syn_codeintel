import io

def file_pos(fn, row, col):
    n = 0
    with io.open(fn, 'rt', newline='') as f:
        lines = f.readlines()
    for i in range(row - 1):
        n += len(lines[i])
    n += col
    return n

print (file_pos(r'g:\_CodeIntel\_pytest1nix.py', 16, 16))
print (file_pos(r'g:\_CodeIntel\_pytest1win.py', 16, 16))
