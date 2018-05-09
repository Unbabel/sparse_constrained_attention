from __future__ import division, print_function
import torch
from torch.autograd import Variable
import torch.nn as nn
import torch.nn.functional as F
import generate_fertilities as gen
import torch.optim as optim
import argparse
import pdb
import numpy as np
import os
import random
import utils, models

torch.manual_seed(1)
random.seed(42)

parser = argparse.ArgumentParser()
parser.add_argument("--emb_dim", type=int, default=256) #128)
parser.add_argument("--hidden_dim", type=int, default=256) #256)
parser.add_argument("--mlp_dim", type=int, default=-1) # -1 means no MLP.
parser.add_argument("--n_layers", type=int, default=2)
parser.add_argument("--dropout", type=float, default=0.2) #0.2)
parser.add_argument("--epochs", type=int, default=5)
parser.add_argument("--batch_size", type=int, default=64)
parser.add_argument("--model_name", type=str, default="fertility_model")
parser.add_argument("--train_source_path", type=str, default="/projects/tir1/users/cmalaviy/OpenNMT-py-old/ja-en/bpe.kyoto-train.cln.low.sink.ja.preprocessed")
parser.add_argument("--dev_source_path", type=str, default="/projects/tir1/users/cmalaviy/OpenNMT-py-old/ja-en/bpe.kyoto-dev.low.sink.ja.preprocessed")
parser.add_argument("--test_source_path", type=str, default="/projects/tir1/users/cmalaviy/OpenNMT-py-old/ja-en/bpe.kyoto-test.low.sink.ja")
parser.add_argument("--train_alignments_path", type=str, default="/projects/tir1/users/cmalaviy/OpenNMT-py-old/ja-en/ja-en-preprocessed.align")
parser.add_argument("--dev_alignments_path", type=str, default="/projects/tir1/users/cmalaviy/OpenNMT-py-old/ja-en/dev-ja-en-preprocessed.align")
parser.add_argument("--patience", type=int, default=100) #3)
parser.add_argument("--max_fert", type=int, default=10)
parser.add_argument("--model_type", type=str, default="classification")
parser.add_argument("--test", action='store_true')
parser.add_argument("--write_fertilities", type=str)
parser.add_argument("--gpu", action='store_true')
args = parser.parse_args()
print(args)

args.model_name += "_" + args.model_type

print("Reading training data...")
training_data = utils.read_file(args.train_source_path)
#gen.generate_actual_fertilities(args.train_source_path, args.train_alignments_path, args.train_source_path + ".fert.actual")
training_ferts = utils.read_file(args.train_source_path + ".fert.actual", fert=True)
training_data, training_ferts = utils.sortbylength(training_data, training_ferts)

word_to_ix = {}
for sent in training_data:
    for word in sent:
        if word not in word_to_ix:
            word_to_ix[word] = len(word_to_ix)

# Set no. of classes as max(max_fert, highest fertility of any word in training set)

for ferts in training_ferts:
    for fert in ferts:
        if fert>args.max_fert:
            args.max_fert = fert

print("Maximum fertility set to %d" %args.max_fert)


# Read dev and test data

dev_data = utils.read_file(args.dev_source_path)
#gen.generate_actual_fertilities(args.dev_source_path, args.dev_alignments_path, args.dev_source_path + ".fert.actual")
dev_ferts = utils.read_file(args.dev_source_path + ".fert.actual", fert=True)
dev_data, dev_ferts = utils.sortbylength(dev_data, dev_ferts)

if args.test:
    test_data = utils.read_file(args.test_source_path)
    #test_data, _ = utils.sortbylength(test_data)


# Store starting index of each minibatch
if args.batch_size != 1:
    train_order = utils.get_train_order(training_data, args.batch_size)
    dev_order = utils.get_train_order(dev_data, args.batch_size)
    #if args.test:
    #    test_order = utils.get_train_order(test_data, args.batch_size)

else:
    train_order = range(len(train_data))
    dev_order = range(len(dev_data))
    #if args.test:
    #    test_order = range(len(test_data))


def main():

    ############################################################################################


    if not os.path.isfile(args.model_name):
        if args.model_type == 'regression':
            fert_model = models.BiLSTMRegressor(args.emb_dim, args.hidden_dim, len(word_to_ix), 
                                                args.max_fert, args.n_layers, args.dropout, args.gpu)
        else:
            fert_model = models.BiLSTMTagger(args.emb_dim, args.hidden_dim, len(word_to_ix), 
                                             args.max_fert, args.n_layers, args.mlp_dim, args.dropout, args.gpu)
        custom_weight = torch.ones(args.max_fert)
        custom_weight[0] = 0.5 #0.6 # TODO: set this as a hyperparameter?
        if args.gpu:
            fert_model = fert_model.cuda()
            custom_weight = custom_weight.cuda()
        if args.model_type == 'regression':
            loss_function = nn.MSELoss()
        else:
            loss_function = nn.NLLLoss(weight=custom_weight)

        #optimizer = optim.SGD(fert_model.parameters(), lr=0.1)
        #optimizer = optim.Adam(fert_model.parameters(), lr=0.001)
        #optimizer = optim.Adam(fert_model.parameters(), lr=0.001, weight_decay=0.001)
        optimizer = optim.Adam(fert_model.parameters(), lr=0.001)
        print("Training fertility predictor model...")
        patience_counter = 0
        prev_avg_tok_accuracy = 0
        best_avg_tok_accuracy = 0
        random.shuffle(train_order)

        for epoch in xrange(args.epochs):
            accuracies = []
            sent = 0
            tokens = 0
            cum_loss = 0
            batch_idx = 1

            num_matches = num_pred = num_gold = 0
            print("Starting epoch %d .." %epoch)
            for start_idx, end_idx in train_order:
                train_sents = training_data[start_idx : end_idx + 1]
                target_ferts = training_ferts[start_idx : end_idx + 1]
                sent += end_idx - start_idx + 1
                tokens += sum([len(sentence) for sentence in train_sents])

                metric = "MSE" if args.model_type == 'regression' else "Average Accuracy"

                if batch_idx%100==0:
                    print("[Epoch %d] \
                        Sentence %d/%d, \
                        Tokens %d \
                        Cum_Loss: %f \
                        %s: %f"
                        % (epoch, sent, len(training_data), tokens,
                            cum_loss/tokens, metric, sum(accuracies)/len(accuracies)))

                # Step 1. Remember that Pytorch accumulates gradients.  We need to clear them out
                # before each instance
                fert_model.zero_grad()

                # Also, we need to clear out the hidden state of the LSTM, detaching it from its
                # history on the last instance.
                fert_model.hidden = fert_model.init_hidden(len(train_sents))

                # Step 2. Get our inputs ready for the network, that is, turn them into Variables
                # of word indices.
                batch_sents = torch.stack([utils.prepare_sequence(sentence, word_to_ix, gpu=args.gpu) for sentence in train_sents])
                batch_ferts = torch.stack([utils.prepare_sequence(ferts, gpu=args.gpu) for ferts in target_ferts])

                # Step 3. Run our forward pass.
                fert_scores = fert_model(batch_sents)

                if args.model_type == 'regression':
                    out_ferts = fert_scores.cpu().data.numpy().flatten()

                    err = out_ferts - batch_ferts.float().cpu().data.numpy().flatten()
                    sent_acc =  sum(err**2 / out_ferts.shape[0])
                    accuracies.append(sent_acc) # This is actually MSE.

                    out_ferts = np.round(out_ferts)
                    gold_ferts = batch_ferts.cpu().data.numpy().flatten()
                    #sent_acc = np.count_nonzero(out_ferts==gold_ferts) / out_ferts.shape[0]
                    #accuracies.append(sent_acc)
                    num_matches += np.count_nonzero(np.logical_and(out_ferts==gold_ferts, gold_ferts != 1))
                    num_pred += np.count_nonzero(out_ferts != 1)
                    num_gold += np.count_nonzero(gold_ferts != 1)

                    # Step 4. Compute the loss, gradients, and update the parameters
                    loss = loss_function(fert_scores, batch_ferts.float())
                else:
                    values, indices = torch.max(fert_scores, 2)
                    out_ferts = indices.cpu().data.numpy().flatten() + 1

                    gold_ferts = batch_ferts.cpu().data.numpy().flatten()
                    sent_acc = np.count_nonzero(out_ferts==gold_ferts) / out_ferts.shape[0]
                    accuracies.append(sent_acc)
                    num_matches += np.count_nonzero(np.logical_and(out_ferts==gold_ferts, gold_ferts != 1))
                    num_pred += np.count_nonzero(out_ferts != 1)
                    num_gold += np.count_nonzero(gold_ferts != 1)

                    # Step 4. Compute the loss, gradients, and update the parameters
                    loss = loss_function(fert_scores.view(len(train_sents)*len(train_sents[0]), -1), batch_ferts.view(-1) - 1)

                cum_loss += loss.cpu().data[0]
                loss.backward()
                optimizer.step()
                batch_idx += 1

            precision = num_matches / num_pred
            recall = num_matches / num_gold
            f1 = 2. * num_matches / (num_pred + num_gold)

            print("Loss: %f" % loss.cpu().data.numpy())
            print("Accuracy: %f" % np.mean(accuracies))
            print("Precision: %f" % precision)
            print("Recall: %f" % recall)
            print("F1: %f" % f1)
            print("Evaluating on dev set...")
            avg_tok_accuracy = eval(fert_model, epoch)
            if avg_tok_accuracy > best_avg_tok_accuracy:
                best_avg_tok_accuracy = avg_tok_accuracy
                print("Saving model..")
                torch.save(fert_model, args.model_name)

            # Early Stopping
            if avg_tok_accuracy <= prev_avg_tok_accuracy:
                patience_counter += 1
                if patience_counter==args.patience:
                    print("Model hasn't improved on dev set for %d epochs. Stopping Training." % patience_counter)
                    break

            prev_avg_tok_accuracy = avg_tok_accuracy


    else:
        print("Loading tagger model from " + args.model_name + "...")
        fert_model = torch.load(args.model_name)
        if args.gpu:
            fert_model = fert_model.cuda()

    if args.test:
        out_path = args.write_fertilities if args.write_fertilities else args.test_source_path+".fert.predicted"
        test(fert_model, out_path)

def eval(fert_model, curEpoch=None):

    correct = 0
    toks = 0
    num_matches = num_pred = num_gold = 0
    all_out_ferts = []
    # all_targets = np.array([])

    print("Starting evaluation on dev set... (%d sentences)" %  len(dev_data))

    for start_idx, end_idx in dev_order:

        dev_sents = dev_data[start_idx : end_idx + 1]
        target_ferts = dev_ferts[start_idx : end_idx + 1]

        fert_model.zero_grad()
        fert_model.hidden = fert_model.init_hidden(len(dev_sents))

        batch_sents = torch.stack([utils.prepare_sequence(sentence, word_to_ix, gpu=args.gpu) for sentence in dev_sents])
        batch_ferts = torch.stack([utils.prepare_sequence(ferts, gpu=args.gpu) for ferts in target_ferts])

        fert_scores = fert_model(batch_sents)

        if args.model_type == 'regression':
            out_ferts = fert_scores.cpu().data.numpy().flatten()
            out_ferts = np.round(out_ferts)

            gold_ferts = batch_ferts.cpu().data.numpy().flatten()
            correct += np.count_nonzero(out_ferts==gold_ferts)
            toks += out_ferts.shape[0]
            num_matches += np.count_nonzero(np.logical_and(out_ferts==gold_ferts, gold_ferts != 1))
            num_pred += np.count_nonzero(out_ferts != 1)
            num_gold += np.count_nonzero(gold_ferts != 1)
        else:
            values, indices = torch.max(fert_scores, 2)
            out_ferts = indices.cpu().data.numpy().flatten() + 1

            gold_ferts = batch_ferts.cpu().data.numpy().flatten()
            correct += np.count_nonzero(out_ferts==gold_ferts)
            toks += out_ferts.shape[0]
            num_matches += np.count_nonzero(np.logical_and(out_ferts==gold_ferts, gold_ferts != 1))
            num_pred += np.count_nonzero(out_ferts != 1)
            num_gold += np.count_nonzero(gold_ferts != 1)

        all_out_ferts.append(out_ferts.tolist())
        # all_targets = np.append(all_targets, batch_ferts)

    precision = num_matches / num_pred
    recall = num_matches / num_gold
    f1 = 2. * num_matches / (num_pred + num_gold)
    avg_tok_accuracy = correct/toks

    print("Dev Set Accuracy: %f" %avg_tok_accuracy)
    print("Dev Set Precision: %f" % precision)
    print("Dev Set Recall: %f" % recall)
    print("Dev Set F1: %f" % f1)

    return f1 #avg_tok_accuracy


def test(fert_model, out_path):

    toks = 0
    all_out_ferts = []

    print("Starting evaluation on test set... (%d sentences)" % len(test_data))
    for sentence in test_data:
        fert_model.zero_grad()
        fert_model.hidden = fert_model.init_hidden()

        sentence_in = utils.prepare_sequence(sentence, word_to_ix, gpu=args.gpu)

        fert_scores = fert_model(sentence_in.view(1, -1))
        if args.model_type == 'regression':
            out_ferts = fert_scores.cpu().data.numpy().flatten()
        else:
            expected = True
            if expected:
                ss = fert_scores.cpu().data.numpy()
                probs = np.exp(ss) / np.tile(np.exp(ss).sum(2)[:,:,None],
                                             (1,1,ss.shape[2]))
                out_ferts = (probs[0, :, :] * np.tile(
                    (1. + np.arange(ss.shape[2])), (ss.shape[1], 1))).sum(1)
            else:
                values, indices = torch.max(fert_scores, 2)
                out_ferts = indices.cpu().data.numpy().flatten() + 1

        toks += out_ferts.shape[0]
        all_out_ferts.append(out_ferts.tolist())

    print("Writing predicted fertility values..")
    # Write fertility values to file
    with open(out_path, 'w') as f:
        for ferts in all_out_ferts:
            for fert in ferts:
                f.write("%s " %fert)
            f.write("\n")


if __name__=="__main__":
    main()
