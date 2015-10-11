#!/local/anaconda/bin/python
# IMPORTANT: leave the above line as is.

import numpy as np
import sys

H = 1024
R = 16
B = 64

#>>HASH_BEGIN
#>>HASH_END

def hash_video(video, hashes):
   signature = []
   for h in hashes:
      m = np.inf
      for s in video:
         v = (h[0]*s + h[1])%H
         m = m if m < v else v
      signature.append(int(m))
   return signature

def hash_band(band, signature, hashes):
   s = band*R
   e = band*R + R
   v = 0 
   for r in xrange(0, R):
      h = hashes[s+r]
      v = v + h[0]*signature[s+r] + h[1]
   v = v%H
   return v

if __name__ == "__main__":
   # VERY IMPORTANT:
   # Make sure that each machine is using the
   # same seed when generating random numbers for the hash functions.
   np.random.seed(seed=42)

   # Generate hash functions.
   # Problem:  Can we know the number of buckets we need?
   # Answer:   Just assume a number of buckets and hash away?
   hashes = np.random.randint(1, H-1, size=(H,2))

   for line in sys.stdin:
      line = line.strip()
      video_id = int(line[6:15])
      shingles = np.fromstring(line[16:], sep=" ") 

      # video_id is a single integer.
      # shingles is a 1 by n array of integers.
      sig = hash_video(shingles, hashes)

      # sig is a 1 by NUM_HASHES array of integers.
      for b in xrange(0, B):
         bucket = hash_band(b, sig, hashes)
         print("%s, %s"%((b, bucket), video_id))
        
