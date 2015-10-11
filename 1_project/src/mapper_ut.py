#!/local/anaconda/bin/python
# IMPORTANT: leave the above line as is.

import numpy as np
import sys

# VERY IMPORTANT:
# Make sure that each machine is using the
# same seed when generating random numbers for the hash functions.
np.random.seed(seed=42)

ROWS  = 32
BANDS = 32

HMAX  = int(sys.maxint/1024)

HASHST = np.random.randint(0, HMAX, size=2)
HASHES = np.random.randint(0, HMAX, size=1023)

def sig(video):
   signature = np.full(1024, 1019, dtype=int)
   # Cheap generation of good hash values:
   #
   # http://stackoverflow.com/questions/19701052/how-many-hash-functions-are-
   # required-in-a-minhash-algorithm/19711615#19711615
   for shingle in video:
      hash_value = (HASHST[0]*shingle + HASHST[1])%1024

      # Check if this is the new minimum hash.
      if hash_value < signature[0]:
         signature[0] = hash_value

      # Do the same for the other 1023 hashes.
      for hash_index in xrange(0, 1023):
         signature_index = hash_index + 1
         next_hash_value = (hash_value ^ HASHES[hash_index])%1024

         if next_hash_value < signature[signature_index]:
            signature[signature_index] = next_hash_value

   return signature

def band(video, id):
   # Get the signature column for the video first.
   # Then iterate over the signature and compute the hash for each band.
   signature = sig(video)

   for b in xrange(0, BANDS):
      hash_value = 0
      for r in xrange(0, ROWS):
         sig_index   = b*ROWS + r
         sig_value   = signature[sig_index]
         hash_index  = sig_index - 1
         next_hash   = (HASHST[0]*sig_value + HASHST[1])
         next_hash  ^= HASHES[hash_index]
         hash_value  = (next_hash + hash_value)%104729
      print("(%s,%s), %s"%(b, hash_value%104729, id))


if __name__ == "__main__":
   # Generate hash functions.
   # Problem:  Can we know the number of buckets we need?
   # Answer:   Just assume a number of buckets and hash away?

   for line in sys.stdin:
      line = line.strip()
      video_id = int(line[6:15])
      shingles = np.fromstring(line[16:], dtype=int, sep=" ") 

      band(shingles, video_id)
        
