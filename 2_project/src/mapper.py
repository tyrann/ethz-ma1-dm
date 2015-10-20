#!/local/anaconda/bin/python
# IMPORTANT: leave the above line as is.

import sys
import numpy as np
from sklearn.linear_model import SGDClassifier

DIMENSION = 400  # Dimension of the original data.
CLASSES = (-1, +1)   # The classes that we are trying to predict.

#emit an array of coefficient representing the model built on the current mapper
def emit(coef):
    return coef

def sgd_iterate(x_new):
    X = x_new
    y = CLASSES
    clf = SGDClassifier(loss="hinge", penalty="l2")
    clf.fit(X, y)
    SGDClassifier(alpha=0.0001, average=False, class_weight=None, epsilon=0.1,
       eta0=0.0, fit_intercept=True, l1_ratio=0.15,
       learning_rate='optimal', loss='hinge', n_iter=5, n_jobs=1,
       penalty='l2', power_t=0.5, random_state=None, shuffle=True,
       verbose=0, warm_start=False)
    emit(clf.coef)

def transform(x_original):
    return x_original

for line in sys.stdin:
    line = line.strip()
    (label, x_string) = line.split(" ", 1)
    label = int(label)
    x_original = np.fromstring(x_string, sep=' ')
    x = transform(x_original)  # Use our features.
    sgd_iterate(x)
