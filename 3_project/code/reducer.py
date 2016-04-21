#!/local/anaconda/bin/python
# IMPORTANT: leave the above line as is.

import sys
import numpy as np

# SEEDS
#----------------------------------------------------------
np.random.seed(42) # Should be the right answer.


# CONSTANTS
#----------------------------------------------------------
FEATURES        = 500
CENTER_COUNT    = 100
CENTER_SCALE    = 1.0
CENTER_BIAS     = 0.5
CENTERS         = np.random.rand(CENTER_COUNT, FEATURES) * CENTER_SCALE - CENTER_BIAS;


# PROCESSING
#-------------------------------------------------------

def process(key, cnts, data):
    data_count = len(data)
    data_cunts = float(np.sum(cnts))

    if data_count > 0:
        data_sum = np.zeros(500)

        for line in xrange(0, data_count):
            mean_fact = cnts[line]/data_cunts
            full_line = data[line]
            mean_line = full_line*mean_fact
            data_sum += mean_line

        CENTERS[key] = data_sum

def reset(target):
    del target[:]


# DATA HANDLING
#-------------------------------------------------------

curr_key = None
last_key = None
data     = []
cnts     = []

for line in sys.stdin:
    line        = line.strip()
    line        = line.lstrip('(')
    line        = line.rstrip(')')
    key, vals   = line.split(', ')
    cnt, vals   = vals.split('|')

    last_key = curr_key
    curr_key = int(key)

    if curr_key != last_key and last_key != None:
        process(last_key, cnts, data)
        reset  (data)
        reset  (cnts)

    inpt = np.fromstring(vals, sep=' ')
    data.append(inpt)
    cnts.append(int(cnt))

process(curr_key, cnts, data)

for center in CENTERS:
    print(' '.join([str(f) for f in center]))


    
