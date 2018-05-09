import cPickle as pickle
import numpy as np
import pdb
import sys

def load_sentences(file_path):
    sentences = []
    f = open(file_path)
    for line in f:
        line = line.rstrip('\n')
        sentences.append(line)
    f.close()
    return sentences

def get_segments(sentence):
    s = 0
    segments = []
    for i, word in enumerate(sentence.split(' ')):
        segments.append(s)
        if word[-2:] != '@@':
            s += 1
    words = [[] for j in range(s)]
    for i, s in enumerate(segments):
        words[s].append(i)
    return segments, words

attention_file = sys.argv[1]
source_bpe_file = sys.argv[2]
target_bpe_file = sys.argv[3]

d = pickle.load(open(attention_file, 'rb'))
attention = d['gold']

source_sentences = load_sentences(source_bpe_file)
target_sentences = load_sentences(target_bpe_file)

for i in range(len(attention)):
    a = attention[i]

    # Sum attention coming to the source.
    sentence = source_sentences[i]
    segments, words = get_segments(sentence)
    b = np.zeros((a.shape[0], len(words)))
    for s, indices in enumerate(words):
        b[:, s] = a[:, indices].sum(1)

    # Average attention coming from the target.
    sentence = target_sentences[i]
    segments, words = get_segments(sentence)
    c = np.zeros((len(words), b.shape[1]))
    for s, indices in enumerate(words):
        c[s, :] = b[indices, :].mean(0)

    attention[i] = c
    
import cPickle as pickle
pickle.dump({'gold': attention},
            open(attention_file + '.postprocessed', 'wb'))

