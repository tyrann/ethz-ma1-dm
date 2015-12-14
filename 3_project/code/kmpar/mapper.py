import sys
import numpy        as np
import numpy.linalg as la
import numpy.random as rng

ITERATIONS = 5
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

def kmeans(data, invariant):
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

        for point in data:
            center    = nearest(point, C)
            direction = point - C[center]

            additions[center] += direction
            counters[center]  += 1

        for center in xrange(0, C.shape[0]):
            counter = counters[center]
            counter = max(counter, 1)
            addition = additions[center]
            C[center] += addition/counter

    return [C, counters]

def emit(centers, counters):
    for index in xrange(0, centers.shape[0]):
        center  = centers[index]
        counter = counters[index]
        string  = ' '.join([str(f) for f in center])

        print("(1, %d|%s)" % (counter, string))


# Read data from standard input.
data = []
for line in sys.stdin:
    line  = line.strip()
    point = np.fromstring(line, sep=' ')

    data.append(point)
data = np.array(data)

# Apply Kmeans clustering.
centers, counters = kmeans(data, ITERATIONS)

# Emit data for the reducer.
emit(centers, counters)
