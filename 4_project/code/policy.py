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

# We use a lookup table that stores key-value pairs where the key is the id of
# an article and the value is a tuple (A, B, b) which keeps track of the article
# related A and B matrices as well as the article related feature vector.
H  = {}
A  = []

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
    # Index 0: Mx
    # Index 1: bx

    lookup[maxID][0] += np.outer(features, features)
    lookup[maxID][1] += np.multiply(reward,features)


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

    max_ucb = None
    for article in articles:

        # create or retrieve an entry in the dictionary
        Ainv, B, b = select(article)
        
    return maxID

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
    return H.setdefault(article, [
            feature_matrix(), 
            tracking_matrix(),
            feature_vector()
        ])