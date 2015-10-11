#!/local/anaconda/bin/python
# IMPORTANT: leave the above line as is.

import numpy as np
import sys

#--------------------------------------------------------------------------
# CONSTANTS

SIMILAIRTY_THRESHOLD = 0.89

#--------------------------------------------------------------------------
# VALUE EXTRACTION

def prepare(value):
    """
    Prepares a value string and extracts relevant information.

    @param value: The value string to process.

    @return: A tuple containing the video id and a signature.
    """ 
    value = value.lstrip('(')
    value = value.rstrip(')')
    vid, sigstr = value.split(',')
    sig = np.fromstring(sigstr, dtype=int, sep='.')

    return (int(vid), sig)

#--------------------------------------------------------------------------
# SIMILARITY

def similarity(sig1, sig2):
    """
    Computes the similarity of two videos signatures.

    @param video1: The first video signature.
    @param video2: The second video signature.

    @return: The smiliarity between the two video signatures.
    """
    l1 = len(sig1)
    l2 = len(sig2)
    h = float(max(l1, l2))

    return (sig1 == sig2).sum() / h

#--------------------------------------------------------------------------
# OUTPUT

def emit_similar(videos):
    unique = np.unique(videos)
    for i in xrange(len(unique)):
        for j in xrange(i + 1, len(unique)):
            vid1, sig1 = prepare(unique[i])
            vid2, sig2 = prepare(unique[j])

            if similarity(sig1, sig2) > SIMILAIRTY_THRESHOLD:
                print "%d\t%d" % (min(vid1, vid2),
                                  max(vid1, vid2))


#--------------------------------------------------------------------------
# MAIN

last_key    = None
key_count   = 0
candidates  = []

for line in sys.stdin:
    line = line.strip()
    key, video = line.split(", ")

    if last_key is None:
        last_key = key

    if key == last_key:
        candidates.append(video)
    else:
        # Key changed (previous line was k=x, this line is k=y)
        emit_similar(candidates)
        duplicates  = [video]
        last_key    = key

if len(candidates) > 0:
    emit_similar(candidates)
