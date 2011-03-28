#!/usr/bin/env python
#
# A test case to reproduce https://github.com/petewarden/dstk/issues/4
#
# Calls the street2coordinates API repeatedly until it fails

import dstk

dstk = dstk.DSTK()

counter = 0
while True:

  test_input = '2543 Graystone Place, Simi Valley, CA 93065'

  result = dstk.street2coordinates(test_input)
  
  counter += 1
  print str(counter)
