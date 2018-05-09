# Sparse and Constrained Attention for Neural Machine Translation
----------------
by Chaitanya Malaviya, Pedro Ferreira, André Martins

## Preparing the data for a language pair

For the sake of example, let's assume we're handling the `ro-en` language pair.
The procedure below works for other language pairs, provided the file names
are consistent.

1. Store your data (tokenized and BPE'ed) in a data folder `<DATA PATH>/ro-en`.
This must contain the following files:
- `corpus.bpe.ro`
- `corpus.bpe.en`
- `newsdev2016.bpe.ro`
- `newsdev2016.bpe.en`
- `newstest2016.bpe.ro`
- `newstest2016.bpe.en`
- `newstest2016.tc.en`

Note 1: don't forget to include the non-BPE's test target file.

Note 2: these files should *not* include the `sink` symbol.

2. Run the following script:

```
>> prepare_experiment.sh ro en
```

This will add the `sink` symbol on the source files, train the aligner,
force alignments on the dev and test data, and run scripts which
create the gold and guided fertility files.
It will also run the `preprocess.py` OpenNMT-py script to create
the train and validation data files.

Note 1: you need to adjust the DATA and ALIGNER paths in this script.

Note 2: you also need to adjust the PATH_FAST_ALIGN in the script `force_align.py`.

3. For training new models with different configurations, run the
following scripts:

```
>> run_experiment.sh <gpuid> ro en softmax 0 &
>> run_experiment.sh <gpuid> ro en sparsemax 0 &
>> run_experiment.sh <gpuid> ro en csoftmax 0 fixed 2 &
>> run_experiment.sh <gpuid> ro en csparsemax 0 fixed 2 &
>> run_experiment.sh <gpuid> ro en csoftmax 0 fixed 3 &
>> run_experiment.sh <gpuid> ro en csparsemax 0 fixed 3 &
>> run_experiment.sh <gpuid> ro en csoftmax 0.2 fixed 3 &
>> run_experiment.sh <gpuid> ro en csparsemax 0.2 fixed 3 &
>> run_experiment.sh <gpuid> ro en csoftmax 0 guided &
>> run_experiment.sh <gpuid> ro en csparsemax 0 guided &
>> run_experiment.sh <gpuid> ro en csoftmax 0.2 guided &
>> run_experiment.sh <gpuid> ro en csparsemax 0.2 guided &
```

This will generate log files in the folder `../logs`.

Note: you need to adjust the DATA and ALIGNER paths in this script.

4. To measure the BLEU and METEOR model performance on the test files,
pick the <model> with best dev performance and use this script:

```
>> ./evaluate.sh <model> <DATA>/ro-en/newstest.bpe.sink.ro <DATA>/ro-en/newstest.tc.en
```

To dump the attention matrices, use the -dump_attn argument with translate.py. You can load the outputted file with pickle as:
```
>> attn_matrices = pickle.load( open(<filename>, 'rb') )
```


## Reference

TBA
