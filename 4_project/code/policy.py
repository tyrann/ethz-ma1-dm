import numpy as np
import math

NUM_FEATURES = 6
ID_START     = None

def feature_vector(): return np.zeros(NUM_FEATURES).astype(float)
def feature_matrix(): return np.identity(NUM_FEATURES)

lookup   = {}
features = feature_vector()
alpha    = 0.2
maxID    = ID_START

def set_articles(articles):
    pass;

def update(reward):
    # Index 0: Mx
    # Index 1: bx

    lookup[maxID][0] += np.outer(features, features)
    lookup[maxID][1] += np.multiply(reward,features)


def reccomend(time, z_t, articles):

    global maxID

    # z_t is 6 entry feature vector.
    # M_x is 6x6 matrix.
    maxUCB = None

    global features
    features = z_t
    for id in articles:

        # create or retrieve an entry in the dictionary
        M_x, b_x = addToDic(id)

        # M_x is 6x6, M_x_inv is 6x6 vas well.
        # w_t is 6x1.
        M_x_inv = np.linalg.inv(M_x)
        w_t = np.dot(M_x_inv, b_x)

        # Had to replace many of the multiplications with np.inner.
        # Apparently, multiplication is done element wise by default.

        # Should we use the articles features in the estimate?
        estimate  = np.dot(w_t, z_t)
        step = alpha * math.sqrt(np.dot(np.dot(w_t,np.linalg.inv(M_x)),w_t))
        ucbx      = estimate + step

        if maxUCB is None or ucbx > maxUCB:
            maxUCB = ucbx
            maxID  = id

    return maxID

def addToDic(id):
    return lookup.setdefault(id, [feature_matrix(), feature_vector()])