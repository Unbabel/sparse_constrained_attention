from __future__ import division, print_function
import torch
from torch.autograd import Variable
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
import argparse
import pdb
import numpy as np
import utils

class BiLSTMTagger(nn.Module):
    def __init__(self, embedding_dim, hidden_dim, vocab_size, max_fert, n_layers=2, mlp_dim=-1, dropOut=0.2, gpu=False):
        super(BiLSTMTagger, self).__init__()

        self.embedding_dim = embedding_dim
        self.hidden_dim = hidden_dim
        self.vocab_size = vocab_size
        self.max_fert = max_fert
        self.n_layers = n_layers

        self.word_embeddings = nn.Embedding(vocab_size, embedding_dim)

        # The LSTM takes word embeddings as inputs, and outputs hidden states
        # with dimensionality hidden_dim.
        self.lstm = nn.LSTM(self.embedding_dim, self.hidden_dim, num_layers=self.n_layers, dropout=dropOut, bidirectional=True)

        # Optional MLP layer.
        if mlp_dim >= 0:
            self.mlp = nn.Linear(2 * self.hidden_dim, self.mlp_dim)
            # The linear layer that maps from hidden state space to tag space
            self.hidden2tag = nn.Linear(self.mlp_dim, self.max_fert)
        else:
            self.mlp = None
            # The linear layer that maps from hidden state space to tag space
            self.hidden2tag = nn.Linear(2 * self.hidden_dim, self.max_fert)

        self.hidden = self.init_hidden()

    def init_hidden(self, batch_size=1):
        # Before we've done anything, we dont have any hidden state.
        # Refer to the Pytorch documentation to see exactly why they have this dimensionality.
        # The axes semantics are (num_layers, minibatch_size, hidden_dim)
        return (utils.get_var(torch.zeros(self.n_layers * 2, batch_size, self.hidden_dim), gpu=True),
                utils.get_var(torch.zeros(self.n_layers * 2, batch_size, self.hidden_dim), gpu=True))

    def forward(self, batch_sents):
        batch_size = batch_sents.size(0)
        sent_length = batch_sents.size(1)
        wembs = self.word_embeddings(batch_sents)
        lstm_out, self.hidden = self.lstm(wembs.view(sent_length, batch_size, -1) , self.hidden)
        if self.mlp is not None:
            states = F.tanh(self.mlp(lstm_out.view(batch_size, sent_length, -1)))
            fert_space = self.hidden2tag(states)
        else:
            fert_space = self.hidden2tag(lstm_out.view(batch_size, sent_length, -1))
        fert_scores = F.log_softmax(fert_space, dim=2)
        return fert_scores


class BiLSTMRegressor(nn.Module):
    def __init__(self, embedding_dim, hidden_dim, vocab_size, max_fert, n_layers=2, dropOut=0.2, gpu=False):
        super(BiLSTMRegressor, self).__init__()

        self.embedding_dim = embedding_dim
        self.hidden_dim = hidden_dim
        self.vocab_size = vocab_size
        self.max_fert = max_fert
        self.n_layers = n_layers

        self.word_embeddings = nn.Embedding(vocab_size, embedding_dim)

        # The LSTM takes word embeddings as inputs, and outputs hidden states
        # with dimensionality hidden_dim.
        self.lstm = nn.LSTM(self.embedding_dim, self.hidden_dim, num_layers=self.n_layers, dropout=dropOut, bidirectional=True)

        # The linear layer that maps from hidden state space to score space
        self.hidden2score = nn.Linear(2 * self.hidden_dim, 1)

        self.hidden = self.init_hidden()

    def init_hidden(self, batch_size=1):
        # Before we've done anything, we dont have any hidden state.
        # Refer to the Pytorch documentation to see exactly why they have this dimensionality.
        # The axes semantics are (num_layers, minibatch_size, hidden_dim)
        return (utils.get_var(torch.zeros(self.n_layers * 2, batch_size, self.hidden_dim), gpu=True),
                utils.get_var(torch.zeros(self.n_layers * 2, batch_size, self.hidden_dim), gpu=True))

    def forward(self, batch_sents):
        batch_size = batch_sents.size(0)
        sent_length = batch_sents.size(1)
        wembs = self.word_embeddings(batch_sents)
        lstm_out, self.hidden = self.lstm(wembs.view(sent_length, batch_size, -1) , self.hidden)
        fert_space = self.hidden2score(lstm_out.view(batch_size, sent_length, -1))
        fert_scores = self.max_fert * F.sigmoid(fert_space)
        return fert_scores.view(batch_size, sent_length)
