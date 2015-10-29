#!/local/anaconda/bin/python
# IMPORTANT: leave the above line as is.

import logging
import sys
import numpy as np

lines = 0
avgs = None

for line in sys.stdin:
    line = line.strip()
    k, v = line.split(', ')
    print(v)
    coef = np.fromstring(v, sep=" ",dtype='double')
    if avgs is None:
        avgs = np.zeros(coef.size)

    lines += 1
    for i in xrange(0, coef.size):
      avgs[i] += coef[i]

avgs=np.array(avgs)
for i in xrange(0, avgs.size):
   avgs[i] /= lines

list = avgs.toList()
' '.join(list)