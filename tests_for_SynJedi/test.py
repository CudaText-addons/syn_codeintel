# Implementation of socket client for Jedi autocompletion
# Author: tbeu
#
# Python 3.x
# Usage: python.exe client4test.py

import socket
import logging
import urllib.parse

# Use level = logging.DEBUG to debug socket communication
logging.basicConfig(level = logging.DEBUG, format = '%(message)s')

HOST = 'localhost'
PORT = 11112
BUFSIZE = 4096
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((HOST, PORT))
fn = r'd:\Work\PyLexImport\split_lexlib_to_lexer_files.py'
fnq = urllib.parse.quote(fn)

#s.send(bytes('?foo', 'utf_8'))
#dataR =    s.recv(BUFSIZE)
#logging.debug('Rx package %s', bytes.decode(dataR))
#
#s.send(bytes('?action=error&fn=' + fnq + '&line=16&column=16', 'utf_8'))
#dataR =    s.recv(BUFSIZE)
#logging.debug('Rx package %s', bytes.decode(dataR))

s.send(bytes('?action=autocomp&fn=' + fnq + '&line=16&column=16', 'utf_8'))
dataR = s.recv(BUFSIZE)
logging.debug('Recv %s', bytes.decode(dataR))

s.send(bytes('?action=funchint&fn=' + fnq + '&line=27&column=23', 'utf_8'))
dataR = s.recv(BUFSIZE)
logging.debug('Recv %s', bytes.decode(dataR))

s.send(bytes('?action=findid&fn=' + fnq + '&line=51&column=32', 'utf_8'))
dataR = s.recv(BUFSIZE)
logging.debug('Recv %s', bytes.decode(dataR))

s.send(bytes('?action=findid&fn=' + fnq + '&line=51&column=1', 'utf_8'))
dataR = s.recv(BUFSIZE)
logging.debug('Recv %s', bytes.decode(dataR))

#s.send(b'?action=close')
s.send(b'?action=noclose')
s.close()
