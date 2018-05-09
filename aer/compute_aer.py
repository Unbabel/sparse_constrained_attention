import cPickle as pickle
import numpy as np
import pdb
import sys

attention_file = sys.argv[1]
alignment_file = sys.argv[2]

d = pickle.load(open(attention_file, 'rb'))
attention = d['gold']

alignments = []
possible_alignments = []
i = 0
f = open(alignment_file)
for line in f:
    fields = line.rstrip('\n').split()
    alignment = np.zeros_like(attention[i])
    possible_alignment = np.zeros_like(attention[i])
    for field in fields:
        if field[0] == '*':
            # Possible link, not sure link.
            field = field[1:]
            sure = False
        else:
            sure = True
        pair = field.split('-')
        assert len(pair) == 2, pdb.set_trace()
        s = int(pair[0])
        t = int(pair[1])
        possible_alignment[t, s] = 1.
        if sure:
            alignment[t, s] = 1.
    alignments.append(alignment)
    possible_alignments.append(possible_alignment)
    i += 1

assert len(attention) == len(alignments)
num_match = num_pred = num_match_hard = num_pred_hard = num_gold = 0.
num_match_possible = num_match_possible_hard = 0.
for pred, gold, gold_possible in zip(attention, alignments, possible_alignments):
    pred_hard = np.zeros_like(pred)
    pred_hard[range(pred.shape[0]), pred.argmax(1)] = 1.
    num_match_hard += (pred_hard*gold).sum()
    num_match_possible_hard += (pred_hard*gold_possible).sum()
    num_pred_hard += pred_hard.sum()
    num_match += (pred*gold).sum()
    num_match_possible += (pred*gold_possible).sum()
    num_pred += pred.sum()
    num_gold += gold.sum()

print 'SAER:', 1. -  (num_match + num_match_possible) / (num_pred + num_gold)
print 'AER:', 1. -  (num_match_hard + num_match_possible_hard) / (num_pred_hard + num_gold)
