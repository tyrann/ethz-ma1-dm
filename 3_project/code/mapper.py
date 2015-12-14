#!/local/anaconda/bin/python
# IMPORTANT: leave the above line as is.

import sys
import numpy        as np
import numpy.linalg as la

# SEEDS
#----------------------------------------------------------
np.random.seed(42) # Should be the right answer.


# CONSTANTS
#----------------------------------------------------------
FEATURES        = 500
CENTER_COUNT    = 100
CENTER_SCALE    = 2.0
CENTER_BIAS     = 1.0
CENTERS         = np.random.rand(CENTER_COUNT, FEATURES) * CENTER_SCALE - CENTER_BIAS;

def smallest(data):
    connections = np.subtract(CENTERS, data)
    norms       = la.norm(connections, 2, 1)
    return np.argmin(norms)

means  = np.zeros(CENTERS.shape)
counts = np.zeros(CENTER_COUNT, dtype=int)

for line in sys.stdin:
    line = line.strip()
    data = np.fromstring(line, sep=' ')
    indx = smallest(data)

    means[indx]  += data
    counts[indx] += 1

for indx in xrange(CENTER_COUNT):
    cnt  = counts[indx]

    if cnt == 0:
        cnt = 1
        
    mean = means[indx]/cnt
    mstr = ' '.join([str(f) for f in mean])

    print("(%d, %d|%s)" % (indx, cnt, mstr))
    
