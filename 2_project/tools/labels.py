import sys
import numpy as np

sys.path.append(sys.argv[4])
from mapper import transform

if __name__ == "__main__":
   with open(sys.argv[1], "r") as weights_file:
      weights = np.genfromtxt(weights_file).flatten()

   with open(sys.argv[2], "r") as data_file:
      with open(sys.argv[3], "w") as pred_file:
         for x_string in data_file:
            # Apply the transformation for x and then continue.
            # Compute the label and write it to the prediction file.
            x_o = np.fromstring(x_string, sep=' ')
            x_t = transform(x_o)

            print("WEIGHTS: %s"%(weights.shape))
            print("VALUES:  %s"%(x_t.shape))

            if np.inner(weights, x_t) > 0:
               pred_file.write("-1\n")
            else:
               pred_file.write("+1\n")
