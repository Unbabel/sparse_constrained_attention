from __future__ import division, print_function
import torch
from torch.autograd import Variable


def read_file(path, fert=False):
  """
   Reads source training file
   dev_or_train: read training data
  """
  with open(path) as f:
    lines = f.readlines()

  training_data = []
  for line in lines:
    if not fert:
      training_data.append(line.strip().split())
    else:
      training_data.append([int(fert) for fert in line.strip().split()])

  return training_data


def sortbylength(src, ferts=None, maxlen=10000):
  """
  :param data: List of tuples of source sentences and fertility values
  :param maxlen: Maximum sentence length permitted
  :return: Sorted data
  """
  # src = [elem[0] for elem in data]
  # tgt = [elem[1] for elem in data]
  indexed_src = [(i,src[i]) for i in range(len(src))]
  sorted_indexed_src = sorted(indexed_src, key=lambda x: -len(x[1]))
  sorted_src = [item[1] for item in sorted_indexed_src if len(item[1])<maxlen]
  sort_order = [item[0] for item in sorted_indexed_src if len(item[1])<maxlen]
  if ferts:
    sorted_tgt = [ferts[i] for i in sort_order]
  else:
    sorted_tgt = None
  # sorted_data = [(src, tgt) for src, tgt in zip(sorted_src, sorted_tgt)]

  return sorted_src, sorted_tgt


def get_train_order(training_data, batch_size):
  """
  :param data: List of tuples of source sentences and morph tags
  :return: start idxs of batches
  """

  lengths = [len(sent) for sent in training_data]
  start_idxs = []
  end_idxs = []
  prev_length=-1
  batch_counter = 0

  for i, length in enumerate(lengths, start=0):
    if length!=prev_length or batch_counter>batch_size:
      start_idxs.append(i)
      if prev_length!=-1:
        end_idxs.append(i-1)
      batch_counter = 1

    batch_counter += 1
    prev_length = length

  end_idxs.append(len(lengths)-1)

  return [(s,e) for s,e in zip(start_idxs, end_idxs)]


def prepare_sequence(seq, to_ix=None, gpu=False):
    if isinstance(to_ix, dict):
      idxs = map(lambda w: to_ix[w] if w in to_ix else 0, seq)
    elif isinstance(to_ix, list):
      # Temporary fix for unknown labels
      idxs = map(lambda w: to_ix.index(w) if w in to_ix else 0, seq)
    else:
      idxs = seq
    tensor = torch.LongTensor(idxs)
    return get_var(tensor, gpu)


def get_var(x,  gpu=False, volatile=False):
  x = Variable(x, volatile=volatile)
  return x.cuda() if gpu else x

