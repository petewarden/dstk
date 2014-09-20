#!/usr/bin/env python
#
# A test case to reproduce https://github.com/petewarden/dstk/issues/49
#
# Certain addresses return invalid characters from the database.

import dstk

dstk = dstk.DSTK()

test_input = '7332 CIRCULO PAPAYO, CARLSBAD,CA 92009'

result = dstk.street2coordinates(test_input)



