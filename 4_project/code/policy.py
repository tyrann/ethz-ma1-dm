import numpy as np
import math

NUM_FEATURES    = 6         # The number of features per article.
ALPHA           = 0.2;      # The alpha value used in linucb.
CURRENT_ID      = None;     # The id of the last selected article.


def feature_vector(): 
    """
    Creates a new feature vector initialized to all zeroes.
    The size of the feature vector depends on the NUM_FEATURES constant.

    Returns
    -------------

    A new vector initialized to zero.
    """
    return np.zeros(NUM_FEATURES, dtype=float)

def feature_matrix(): 
    """
    Creates a new feature matrix initialized to the identity.
    The size of the feature matrix depends on the NUM_FEATURES constant.

    Returns
    -------------

    A new matrix initialized to the identity matrix.
    """
    return np.identity(NUM_FEATURES, dtype=float)

def tracking_matrix():
    """
    Creates a new tracking matrix initialized to all zeroes.
    The size of the tracking matrix depends on the NUM_FEATURES constant.

    Returns
    -------------

    A new matrix initialized to zero.
    """
    return np.zeros((NUM_FEATURES, NUM_FEATURES), dtype=float)

A0 = feature_matrix();  # Hybrid linucb learned variable.
B0 = feature_vector();  # Hybrid linucb learned variable.
F  = feature_vector();  # The last user feature vector.
M  = None               # The index of the maximum article.

# We use a lookup table that stores key-value pairs where the key is the id of
# an article and the value is a tuple (A, B, b) which keeps track of the article
# related A and B matrices as well as the article related feature vector.
Lookup    = {}
Articles  = []

def set_articles(articles):
    """
    Sets the global articles storage to the newly provided articles.
    The old articles get dropped when new articles are written.

    Parameters
    --------------

    articles : [[float]]
        A list of feature vectors for all articles.
    """
    global A
    A = articles


def update(reward):
    global Lookup
    global A0
    global B0

    # Get the current data for the article.
    data = select(M)
    A = data[0]
    I = data[1]
    B = data[2]
    b = data[3]

    # Get the feature vector for the article.
    x = Articles[M]

    # Do initial update step for our global A0 and B0.
    A0 = A0 + np.dot(B, np.dot(I, B))
    B0 = B0 + np.dot(B, np.dot(I, b))

    # Compute new data for the article.
    newA = A + np.dot(x, x.T)
    newI = np.linalg.inv(newA)
    newB = B + np.dot(x, F.T)
    newb = b + reward*x

    # Do final update step for the article.
    A0 = A0 + np.dot(F, F.T) - np.dot(newB.T, np.dot(newI, newB))
    B0 = B0 + reward*F  np.dot(newB, np.dot(newI, newb))

    # Update the data for the article.
    Lookup[M][0] = newA
    Lookup[M][1] = newI
    Lookup[M][2] = newB
    Lookup[M][3] = newb


def reccomend(t, f, articles):
    """
    This terribly named function creates a new recommendation for the specified user
    based, selected from the specified articles using a hybrid linucb approach.

    Parameters
    --------------

    t : int
        The time at which the recommendation is computed.

    f : [float]
        The user feature vector describing the preferences of the specified user.

    articles : [int]
        The vector of article identites which are kept track of in the lookup table.

    Returns
    --------------

    An integer describing the article selected from the provided articles.
    """

    global M    # Need to keep track of the selected article.
    global F    # Need to keep track of the user feature vector.
    F = f       # Update the user feature vector.
    
    # Initialize Beta and A0
    A0inv = np.lianlg.inv(A0)
    beta  = np.dot(A0inv, B0)

    # Initialize local tracking values.
    maxV = None # Maximum hybrid UCB value of article.
    maxI = None # Id of article with maximum UCB value.

    for article in articles:
        
        data = select(article)
        A = data[0] 
        I = data[1] 
        B = data[2] 
        b = data[3]

        # Get article feature vector and initialize theta.
        x = Articles[article]
        t = b - np.dot(B, beta)
        t = np.dot(I, t)

        # Compute hybrid UCB value.
        s1  = np.dot(f.T, np.dot(A0inv, f))
        s21 = np.dot(B, np.dot(I, x))
        s2  = 2*np.dot(f, np.dot(A0inv, s21))
        s3  = np.dot(x, np.dot(I, x))
        s41 = np.dot(B, np.dot(I, x))
        s42 = np.dot(B, np.dot(A0inv, s41))
        s4  = np.dot(x, np.dot(I, s42))
        s   = s1 - s2 + s3 + s4

        p = np.dot(f, beta) + np.dot(x, t) + alpha*np.sqrt(s)

        if p > maxV:
            maxV = p
            maxI = article

    M = maxI
    return maxI


def select(article):
    """
    Selects the A, B, b tuple for an article or initializes a new set of
    variables for the article.

    Parameters
    --------------

    article : int
        The article to be selected.

    Returns
    --------------

    A list containing the A, B and b values in that order.
    """
    return Lookup.setdefault(article, [
            feature_matrix(),
            feature_matrix(), 
            tracking_matrix(),
            feature_vector()
        ])