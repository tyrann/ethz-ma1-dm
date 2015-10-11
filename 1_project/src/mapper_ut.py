#!/local/anaconda/bin/python
# IMPORTANT: leave the above line as is.

import numpy as np
import sys

# VERY IMPORTANT:
# Make sure that each machine is using the
# same seed when generating random numbers for the hash functions.
np.random.seed(seed=42)

#--------------------------------------------------------------------------
# CONSTANTS

HASHES   = 1000
SHINGLES = 1024
BANDS    = 20
ROWS     = 50

SHINGLE_BUCKETS   = 1033  # Slightly above shingle count.
BAND_BUCKETS      = 51503 # Slightly below maximum linear hash value.

#--------------------------------------------------------------------------
# HASHES

SHINGLE_HASHES = np.randint(1, SHINGLES, size=(HASHES, 2))

def hash_shingle(i, shingle):
   """
   Return the hash of the shingle for the i-th hash function.

   @param i:         The index of the hash function to use.
   @param shingle:   The shingle to produce a hash of.

   @return: The hash value of the shingle between 0 and SHIN_BUCKETS.
   """
   return (SHINGLE_HASHES[i][0]*shingle + SHINGLE_HASHES[i][1])%SHINGLE_BUCKETS

BAND_HASHES = np.randint(1, BAND_BUCKETS, size=(HASHES, 2))

def hash_band(i, signature):
   """
   Return the hash value of the specified band in the signature.

   @param i:         The index of the band to be hashed.
   @param signature: The signature to extract the band from.

   @return: The hash value of the band between 0 and BAND_BUCKETS.
   """
   start_index = ROWS*i
   end_index   = ROWS*(i+1)
   hash_value  = 0
   for i in xrange(start_index, end_index):
      hash_value += BAND_HASHES[i][0]*signature[i] + BAND_HASHES[i][1]

   return hash_value % BAND_BUCKETS

#--------------------------------------------------------------------------
# MINHASH

def produce_signature(shingles):
   """
   Produces a minhash signature for the specified list of shingles.

   @param shingles: A list of shingles.

   @return: The minhash signature for the list of shingles.
   """
   signature = np.full(HASHES, SHIN_BUCKETS, dtype=int)

   # For each hash function, we need to iterate over all shingles and
   # evaluate their hash value. We keep track of the minimum and update
   # it along the way.
   for hi in xrange(0, HASHES):
      for sh in shingles:
         h = hash_shingle(hi, sh)

         if h < signature[hi]:
            signature[hi] = h

   return signature

#--------------------------------------------------------------------------
# LOCALITY SENSITIVE HASHING

if __name__ == "__main__":
   for line in sys.stdin:
      line     = line.strip()
      video_id = int(line[6:15])
      shingles = np.fromstring(line[16:], dtype=int, sep=" ") 

      signature = produce_signature(shingles)
      for band in xrange(0, BANDS):
         h = hash_band(band, signature)
         print("(%s,%s), %s" % (band, h, video_id))
        
