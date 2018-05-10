### Generate experiments

The folder must contain:

    - generate_experiments.sh
    - clear_data.sh
    - corpus.SRC
    - corpus.TGT
    - test.SRC
    - test.TGT
    - mt_predictions folder (with the merged mt predictions)
    - aligner_data folder (empty)
    - scripts folder(with the bleu, rep_score and drop_score script)
    - stopwords folder (with stopwords if necessary)

#### Notes:
- The stopwords files should be written as _stopwords.SRC_.
- Make the ALIGNER path in generate\_results.sh point to your local [fast\_align](https://github.com/clab/fast_align) build.
