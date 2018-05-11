### Generate experiments

#### REP-score:

To obtain the REP-score use the rep\_score.py script.

```
>> python3 rep_score.py -r <DATA>/ro-en/newstest.en \
                        -p <DATA>/merged.prediction.en \
                        --normalize
```

Notes:

- The reference (-r) and predicted (-p) files are the **merged** (without bpe applied) files.

Optional Flags:

> --normalize, normalizes the score with regard to the number of words in the reference
> -n, to change the value of _n-grams_ (default: 2)
> -w1, to change the multiplier lambda 1 (default: 1.0)
> -w2, to change the multiplier lambda 2 (default: 2.0)

#### DROP-score:

To obtain the DROP-score use the drop\_score.py script.

```
>> python3 drop_score.py --src_ref_align <PATH>/src_ref.align
                         --src_mt_align <PATH>/src_mt.align
```

Optional Flags:

> --filter\_stopwords, to exclude counts related with provided stopwords (default: False)
> --test\_source, provide the path to the source file (merged).
> --stopwords\_path, path to the stopwords file (one stopword per line)

Notes:

- The alignments are expected to follow [fast_align](https://github.com/clab/fast_align) format.
- All the provided files should be merged (without bpe applied).

#### Auxiliary scripts:

**Train aligner and obtain source-reference alignments**:

To train the aligner and obtain the source reference alignments the script train\_aligner.sh might be used as

```
>> ./train_aligner.sh source_language target_language train_source train_target test_source test_target
```

for example,

```
>> ./train_aligner.sh ro en <PATH>/corpus.ro <PATH>/corpus.en <PATH>/newstest.ro <PATH>/newstest.en
```

Notes:

- Change the path to [fast_align](https://github.com/clab/fast_align) to your local copy of the repository.
- To replicate the paper results, make sure that the data used is merged (without bpe applied) and the source files include the <SINK> token.

**Obtain coverage metric values for a single predictions**:

To obtain the coverage metrics for a single prediction, use the script run\_coverage\_metrics.sh

```
>> ./run_coverage_metrics.sh merged_prediction test_target src_ref_align src_mt_align
```

for example,

```
>> ./run_coverage_metrics.sh <PATH>/merged.prediction.en <PATH>/newstest.en <PATH>/src_ref.align <PATH>/src_mt.align
```

Notes:

- The provided files should be merged (without bpe applied).
- The alignments are expected to follow [fast_align](https://github.com/clab/fast_align) format.

**Obtain coverage metric values for several predictions**:

To obtain the coverage metrics for a several predictions at once, use the script run\_coverage\_metrics\_several.sh.

```
>> ./run_coverage_metrics_several.sh source_language target_language test_source test_target aligner_data_path mt_predictions_path
```

for example.

```
>> ./run_coverage_metrics_several.sh ro en <PATH>/newstest.ro <PATH>/newstest.en <AlignerDataPath> <MtPredictionsPath>
```

Notes:

- The predictions files should be merged (without bpe applied).
- The aligner data file should contain the necessary files (obtained from train\_aligner.sh).

