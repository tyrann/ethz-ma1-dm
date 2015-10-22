#!/local/anaconda/bin/python
# IMPORTANT: leave the above line as is.

import logging
import sys
import numpy as np

lines = 0
avgs  = np.zeros()

for line in sys.stdin:
    line = line.strip()
    
    k, v = line.split(', ')
    coef = np.fromstring(v, dtype=double)

    lines += 1
    for i in xrange(0, len(coef)):
      avgs[i] += coef[i]

for i in xrange(0, len(avgs)):
   avgs[i] /= lines

print(avgs)