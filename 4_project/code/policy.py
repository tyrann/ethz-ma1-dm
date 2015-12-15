import numpy as np

NUM_FEATURES = 6
ID_START     = None

def feature_vector(): return np.zeros(NUM_FEATURES)
def feature_matrix(): return np.identity(NUM_FEATURES)

lookup   = {}
features = feature_vector()
alpha    = 1 + np.sqrt(np.log(2/0.1)/2)
maxID    = ID_START

def set_articles(articles):
    pass;

def update(reward):
    # Index 0: Mx
    # Index 1: bx
    lookup[maxID][0] += np.outer(features, features)
    lookup[maxID][1] += reward*features

def reccomend(time, z_t, articles):
    global maxID

    # z_t is 6 entry feature vector.
    # M_x is 6x6 matrix.
    maxUCB = None

    features = z_t
    for id in articles:
        # create or retrieve an entry in the dictionary
        M_x, b_x = addToDic(id)

        # M_x is 6x6, M_x_inv is 6x6 vas well.
        # w_t is 6x1.
        M_x_inv = np.linalg.inv(M_x)
        w_t = np.inner(M_x_inv, b_x)

        # Had to replace many of the multiplications with np.inner.
        # Apparently, multiplication is done element wise by default.
        estimate  = np.inner(w_t, z_t)
        inner_z_m = np.inner(z_t, M_x_inv)
        inner_t_z = np.inner(inner_z_m, z_t)
        additive  = np.sqrt(inner_t_z)
        ucbx      = estimate + alpha*additive

        if maxUCB is None or ucbx > maxUCB:
            maxUCB = ucbx
            maxID  = id

    return maxID

def addToDic(id):
    return lookup.setdefault(id, [feature_matrix(), feature_vector()])