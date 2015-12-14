import numpy as np
import sys

with open(sys.argv[1], "r") as weights:
   weights = np.genfromtxt(weights).flatten()
   print weights.shape
   print weights.tolist()