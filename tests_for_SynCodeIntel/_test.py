import sys
import socket
import logging
import urllib
import urlparse

# Use level = logging.DEBUG to debug socket communication
logging.basicConfig(level = logging.DEBUG)

HOST = 'localhost'
PORT = 11113
BUFSIZE = 4096
s = socket.socket()
try:
    s.connect((HOST, PORT))
except:
    print "Cannot connect"
    sys.exit(0)

ACP = 'autocomp'
HINT = 'funchint'
FINDID = 'findid'

def test_acp(act, fn, row, col):
    logging.info('-------' + fn + ' ' + str(row) + ':' + str(col))
    fnq = urllib.quote(fn)
    s.send('?action=' + act + '&fn=' + fnq + '&line=' + str(row) + '&column=' + str(col))
    dataR = s.recv(BUFSIZE)
    logging.info('Recv %s', bytes.decode(dataR))

test_acp(ACP, r'g:\_CodeIntel\_pytest1nix.py', 16, 16)
#test_acp(ACP, r'g:\_CodeIntel\_pytest1win.py', 16, 16)
#test_acp(HINT, r'g:\_CodeIntel\_pytest1win.py', 21, 24)
#test_acp(HINT, r'g:\_CodeIntel\_pytest1win.py', 52, 31)
#test_acp(ACP, r'g:\_CodeIntel\_phptest1.php', 14, 5)
#test_acp(HINT, r'g:\_CodeIntel\_phptest1.php', 14, 10)
test_acp(FINDID, r'g:\_CodeIntel\_pytest1nix.py', 52, 20)

s.send(b'?action=noclose')
s.close()
