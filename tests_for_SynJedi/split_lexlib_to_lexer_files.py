# Script splits LXL lexer library file to separate LCF files
# Author: Alex (SynWrite)
#
# Python 2.7
# Usage: python.exe "this_script.py" "path_to_library.lxl"

import sys
import os
import re

if len(sys.argv) < 2:
    print 'command-line parameter needed: <filename_LXL>'
    exit(0)
                              
fn_lxl = sys.argv[1]    
if not os.path.isfile(fn_lxl):
    print 'file not found: ', fn_lxl
    exit(0)
print 'processing library: ', fn_lxl     

dir_out = os.path.join(os.path.dirname(fn_lxl), 'out')
if not os.path.isdir(dir_out):
    os.mkdir(dir_out)

def lexer_name(l):
    for s in l:
        m = re.search(r"LexerName = '(.+?)'", s)
        if m:
            res = m.group(1)
            res = res.replace(':', '_')
            res = res.replace('/', '_')
            return res
    return None

def save_list_to_file(l, fn):
    print 'saving lexer: ', fn
    with open(fn, 'w') as f:
        f.writelines(l)

islex = False
with open(fn_lxl, 'r') as f:
    for s in f:
        if s.startswith('  object'):
            #print 'start ', s
            islex = True
            l = []
        elif s.startswith('  end'):
            #print 'end'
            islex = False
            l.append(s)
            fn_lex = os.path.join(dir_out, lexer_name(l) + '.lcf')
            save_list_to_file(l, fn_lex)
        if islex:
            l.append(s)
