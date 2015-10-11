#!/local/anaconda/bin/python
# IMPORTANT: leave the above line as is.

import numpy as np
import sys


def print_duplicates(videos):
    unique = np.unique(videos)
    for i in xrange(len(unique)):
        for j in xrange(i + 1, len(unique)):
            videoi, sigi = unique[i].split('>')
            videoj, sigj = unique[j].split('>')
            sigvi = [int(v) for v in sigi.split('|')]
            sigvj = [int(v) for v in sigj.split('|')]

            hashes = max(len(sigvi), len(sigvj))
            if np.equal(sigvi, sigvj).sum() / hashes > 0.9:
                print "%d\t%d" % (min(unique[i], unique[j]),
                                  max(unique[i], unique[j]))

last_key = None
key_count = 0
duplicates = []

for line in sys.stdin:
    line = line.strip()
    key, value = line.split(", ")

    if last_key is None:
        last_key = key

    if key == last_key:
        duplicates.append(value)
    else:
        # Key changed (previous line was k=x, this line is k=y)
        print_duplicates(duplicates)
        duplicates = [value]
        last_key = key

if len(duplicates) > 0:
    print_duplicates(duplicates)
