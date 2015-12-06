import sys
import numpy        as np
import numpy.linalg as la
import numpy.random as rng

ITERATIONS = 10
NUM_C = 100
NUM_F = 500
MAX_F = sys.float_info.max
MIN_F = sys.float_info.min

def euclidean(x, y):
    return la.norm(x - y, ord=2)

def nearest(point, centers):
    min_index       = 0
    min_distance    = MAX_F

    for i in xrange(0, centers.shape[0]):
        distance = euclidean(centers[i], point)

        if distance < min_distance:
            min_distance = distance
            min_index    = i

    return min_index

def kmeans(data, weights, invariant):
    # Sample centers in the range defined by the data.
    data_min = data.min(axis=0)
    data_max = data.max(axis=0)
    data_rng = data_max - data_min

    C = rng.rand(NUM_C, NUM_F)

    for cIndex in xrange(0, NUM_C):
        C[cIndex] *= data_rng
        C[cIndex] += data_min

    C_previous = np.zeros(C.shape)
    C_change   = C - C_previous

    # Iterate over the center until the invariant is met.
    for i in xrange(0, invariant):
        sys.stderr.write("Iteration: %d\n" % (i))
        sys.stderr.flush()

        additions = np.zeros(C.shape)
        counters  = np.zeros(C.shape[0])

        for index in xrange(0, data.shape[0]):
            point     = data[index]
            weight    = weights[index]
            center    = nearest(point, C)
            direction = point - C[center]

            additions[center] += direction*weight
            counters[center]  += weight

        for center in xrange(0, C.shape[0]):
            counter = counters[center]
            counter = max(counter, 1)
            addition = additions[center]
            C[center] += addition/counter

    emit(C)

def emit(centers):
    for center in centers:
        string  = ' '.join([str(f) for f in center])

        print string



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
        array = np.array(data)
        kmeans(array, cnts, ITERATIONS)
        reset  (data)
        reset  (cnts)

    inpt = np.fromstring(vals, sep=' ')
    data.append(inpt)
    cnts.append(int(cnt))

array = np.array(data)
kmeans(array, cnts, ITERATIONS)