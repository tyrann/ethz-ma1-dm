#!/local/anaconda/bin/python
# IMPORTANT: leave the above line as is.

import sys
import numpy as np
from sklearn.linear_model import SGDClassifier

DIMENSION = 400  # Dimension of the original data.
CLASSES = (-1, +1)   # The classes that we are trying to predict.

# Emit an array of coefficient representing the model built on the current mapper
def emit(coef):
    return coef

def sgd_train(features,labels):
    X = features
    y = labels

    # creates a classifier using hinge loss

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

if __name__ == "__main__":

    train_set=[]
    train_labels=[]

    for line in sys.stdin:

        line = line.strip()
        (label, x_string) = line.split(" ", 1)
        label = int(label)
        x_original = np.fromstring(x_string, sep=' ')
        x = transform(x_original)  # Use our features.

        # create a vector of feature
        train_set.append(x)
        train_labels.append(label)
        # train our model on the features
        sgd_train(train_set, train_labels)
