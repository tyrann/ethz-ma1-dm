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

SHINGLES = 20000

BANDS    = 64
ROWS     = 16
HASHES   = BANDS*ROWS

SHINGLE_BUCKETS   = SHINGLES
BAND_BUCKETS      = 103549
#BAND_BUCKETS      = 15667
#BAND_BUCKETS      = 217219

# CHECKS
if HASHES > 1024:
   sys.exit("Too many hash functions: %d" % HASHES)   

#--------------------------------------------------------------------------
# PRIMES

def primesfrom3to(n):
    """ Returns a array of primes, 3 <= p < n """
    sieve = np.ones(n/2, dtype=np.bool)
    for i in xrange(3,int(n**0.5)+1,2):
        if sieve[i/2]:
            sieve[i*i/2::i] = False
    return 2*np.nonzero(sieve)[0][1::]+1

PRIMES = primesfrom3to(SHINGLES)
np.random.shuffle(PRIMES)
A_PRIMES = PRIMES[0:HASHES]
B_PRIMES = PRIMES[HASHES:2*HASHES]

#--------------------------------------------------------------------------
# HASHES

def hash_shingle(i, shingle):
   """
   Return the hash of the shingle for the i-th hash function.

   @param i:         The index of the hash function to use.
   @param shingle:   The shingle to produce a hash of.

   @return: The hash value of the shingle between 0 and SHIN_BUCKETS.
   """
   return (A_PRIMES[i]*shingle + B_PRIMES[i])%SHINGLE_BUCKETS

#--------------------------------------------------------------------------
# MINHASH

def produce_signature(shingles):
   """
   Produces a minhash signature for the specified list of shingles.

   @param shingles: A list of shingles.

   @return: The minhash signature for the list of shingles.
   """
   signature = np.full(HASHES, SHINGLE_BUCKETS, dtype=int)

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

BAND_HASHES = np.random.randint(1, BAND_BUCKETS, size=(HASHES, 2))

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
      hash_value = (hash_value + B_PRIMES[i]*signature[i]) %BAND_BUCKETS

   return (hash_value + A_PRIMES[42]) % BAND_BUCKETS

#--------------------------------------------------------------------------
# MAIN

def prepare(line):
   """
   Prepares a line for further processing. Extracts the video id and 
   the shingles from the line.

   @param line: The line to process.

   @return: The video id and the shingles of the video.
   """
   line = line.strip()
   vid  = int(line[6:15])
   shin = np.fromstring(line[16:], dtype=int, sep= " ")

   return (vid, shin)

def emit(vid, band, hashv, sig):
   """
   Emits a new mapped pair consisting of a key defined by the band
   and the hash value and a value consisting of the video id followed
   by the signature as string.

   param vid:   The id of the video.
   param band:  The band of the hash.
   param hashv: The hash value of the band.
   param sig:   The hashed signature.
   """
   sigstr = '.'.join([str(s) for s in sig])
   key = "(%s,%s)" % (band, hashv)
   val = "(%s,%s)" % (vid, sigstr)

   print("%s, %s" % (key, val))

if __name__ == "__main__":
   for line in sys.stdin:
      vid, shingles = prepare(line)
      signature     = produce_signature(shingles)
      for band in xrange(0, BANDS):
         hashv = hash_band(band, signature)
         emit(vid, band, hashv, signature)
        
