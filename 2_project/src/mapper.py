#!/local/anaconda/bin/python
# IMPORTANT: leave the above line as is.

import sys
import numpy as np
import 0sklearn
from sklearn import preprocessing as PP
from sklearn import linear_model  as LM

DIMENSION = 400  # Dimension of the original data.
CLASSES = (-1, +1)   # The classes that we are trying to predict.

# Emit an array of coefficient representing the model built on the current mapper
def emit(coef):
 string=' '.join(str(x) for x in coef)
 print("%s, %s" % (1, string))
    #return coef

def sgd_train(features,labels):

  X = features
  y = labels

  # creates a classifier using hinge loss
  clf = LM.SGDClassifier(loss='hinge')
  clf.fit(X, y)
  coef = clf.coef_
  coef = [val for sublist in coef for val in sublist]
  emit(coef)

def transform(x_original):
  take = [5, 20, 27, 31, 40, 41, 61, 249, 347]
  newx = [x_original[i] for i in take]
  t = PP.PolynomialFeatures(degree=2)
  x = t.fit_transform([newx])
  return x.flatten()[1:]
   
if __name__ == "__main__":

  train_set=[]
  train_labels=[]

  for line in sys.stdin:

    line = line.strip()
    (label, x_string) = line.split(" ", 1)
    label = int(label)
    x_original = np.fromstring(x_string, sep=' ')


    # create a vector of feature
    train_set.append(x_original)
    train_labels.append(label)

  # train our model on the features
  train_set_trans = transform(train_set)
  sgd_train(train_set_trans, train_labels)
