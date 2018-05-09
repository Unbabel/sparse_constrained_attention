SOURCE=$1 # ro
TARGET=$2 # en
LANGPAIR=${SOURCE}-${TARGET}
#DATA=/mnt/data/home/afm/mt_data/data/${LANGPAIR}
#ALIGNER=/home/afm/fast_align/build
DATA=/mnt/disk/afm/data/${LANGPAIR}
ALIGNER=/mnt/disk/afm/fast_align/build
preprocess=true
align=true
fertilize=true

cd ..

if $preprocess
then
    for prefix in corpus newsdev2016 newstest2016
    do
        sed 's/$/ <sink>/' ${DATA}/$prefix.bpe.${SOURCE} > ${DATA}/$prefix.bpe.sink.${SOURCE}
    done

    rm -rf ${DATA}/preprocessed.sink.align*.pt

    python -u preprocess.py \
           -train_src ${DATA}/corpus.bpe.sink.${SOURCE} \
           -train_tgt ${DATA}/corpus.bpe.${TARGET} \
           -valid_src ${DATA}/newsdev2016.bpe.sink.${SOURCE} \
           -valid_tgt ${DATA}/newsdev2016.bpe.${TARGET} \
           -save_data ${DATA}/preprocessed.sink.align \
           -write_txt
fi

if $align
then
    echo "Training aligner..."
    paste -d '\t' \
          ${DATA}/preprocessed.sink.align.train.1.pt.txt.src \
          ${DATA}/preprocessed.sink.align.train.1.pt.txt.tgt \
          > ${DATA}/preprocessed.sink.align.train.1.pt.txt.src-tgt
    sed -i 's/\t/ ||| /g' ${DATA}/preprocessed.sink.align.train.1.pt.txt.src-tgt
    ${ALIGNER}/fast_align -i ${DATA}/preprocessed.sink.align.train.1.pt.txt.src-tgt -d -o -v \
              -p ${DATA}/a.s2t.params \
              > ${DATA}/preprocessed.sink.align.train.1.pt.txt.src-tgt.forward.align \
              2> ${DATA}/a.s2t.err
    ${ALIGNER}/fast_align -i ${DATA}/preprocessed.sink.align.train.1.pt.txt.src-tgt -d -o -v -r \
              -p ${DATA}/a.t2s.params \
              > ${DATA}/preprocessed.sink.align.train.1.pt.txt.src-tgt.reverse.align \
              2> ${DATA}/a.t2s.err

    echo "Running aligner on validation data..."
    paste -d '\t' \
          ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src \
          ${DATA}/preprocessed.sink.align.valid.1.pt.txt.tgt \
          > ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src-tgt
    sed -i 's/\t/ ||| /g' ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src-tgt
    python scripts/force_align.py \
           ${DATA}/a.s2t.params ${DATA}/a.s2t.err \
           ${DATA}/a.t2s.params ${DATA}/a.t2s.err \
           fwd \
           < ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src-tgt \
           > ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src-tgt.forward.align

    echo "Running aligner on test data..."
    paste -d '\t' \
          ${DATA}/newstest2016.bpe.sink.${SOURCE} \
          ${DATA}/newstest2016.bpe.${TARGET} \
          > ${DATA}/newstest2016.bpe.${SOURCE}-${TARGET}
    sed -i 's/\t/ ||| /g' ${DATA}/newstest2016.bpe.${SOURCE}-${TARGET}
    python scripts/force_align.py \
           ${DATA}/a.s2t.params ${DATA}/a.s2t.err \
           ${DATA}/a.t2s.params ${DATA}/a.t2s.err \
           fwd \
           < ${DATA}/newstest2016.bpe.${SOURCE}-${TARGET} \
           > ${DATA}/newstest2016.bpe.${SOURCE}-${TARGET}.forward.align
fi

if $fertilize
then
    for method in guided actual
    do
        python -u scripts/generate_fertilities.py \
               -method ${method} \
               -train_source ${DATA}/preprocessed.sink.align.train.1.pt.txt.src \
               -train_align ${DATA}/preprocessed.sink.align.train.1.pt.txt.src-tgt.forward.align \
               -dev_source ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src \
               -dev_align ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src-tgt.forward.align \
               -test_source ${DATA}/newstest2016.bpe.sink.${SOURCE} \
               -test_align ${DATA}/newstest2016.bpe.${SOURCE}-${TARGET}.forward.align
    done
fi
