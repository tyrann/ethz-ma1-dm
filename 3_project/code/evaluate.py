import logging
import sys
import numpy as np
from sklearn.metrics.pairwise import pairwise_distances

if __name__ == "__main__":
    if not len(sys.argv) == 3:
        logging.error("Usage: evaluate.py centers test_data")
        sys.exit(1)

    with open(sys.argv[1], "r") as fp_centers:
        centers = np.genfromtxt(fp_centers)

    with open(sys.argv[2], "r") as fp_test_data:
        points = np.genfromtxt(fp_test_data)
                  
    if centers.shape[0] != 100:
        logging.error("Didn't return 100 centers.")
        sys.exit(1);

    distances = pairwise_distances(points, centers, metric='sqeuclidean')
    quant_error = distances.min(axis=1).sum()
    quant_error /= points.shape[0]
    
    print "%.5f" % quant_error
