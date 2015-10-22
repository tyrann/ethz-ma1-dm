#!/local/anaconda/bin/python
# IMPORTANT: leave the above line as is.

import sys
import numpy as np
from sklearn.linear_model import SGDClassifier

DIMENSION = 400  # Dimension of the original data.
CLASSES = (-1, +1)   # The classes that we are trying to predict.

# Emit an array of coefficient representing the model built on the current mapper
def emit(coef):
   sys.stderr.write("%s\n" % (coef))
   print("%s, %s" % (1, coef))
    #return coef

def sgd_train(features,labels):
    X = features
    y = labels

    # creates a classifier using hinge loss

    clf = SGDClassifier(loss="hinge", penalty="l2")
    clf.fit(X, y)

    emit(clf.coef_)

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
