SOURCE=$1 # eg. ro
TARGET=$2 # eg. en
LANGPAIR=${SOURCE}-${TARGET}
DATA=/mnt/data/${LANGPAIR}-md
ALIGNER=/home/ubuntu/fast_align/build
OPENNMT=/home/ubuntu/OpenNMT-py-un
SCRIPTS="`cd $(dirname $0);pwd`"

preprocess=false
align=false
fertilize=true

cd ${OPENNMT}

if $preprocess
then
    #for prefix in corpus newsdev2016 newstest2016
#    for prefix in train dev test
#    do
#        sed 's/$/ <sink>/' ${DATA}/$prefix.bpe.${SOURCE} > ${DATA}/$prefix.bpe.sink.${SOURCE}
#    done

    rm -rf ${DATA}/preprocessed.sink.align*.pt

    python -u preprocess.py \
           -train_src ${DATA}/train.bpe.sink.${SOURCE} \
           -train_tgt ${DATA}/train.bpe.${TARGET} \
           -valid_src ${DATA}/dev.bpe.sink.${SOURCE} \
           -valid_tgt ${DATA}/dev.bpe.${TARGET} \
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
    python ${SCRIPTS}/force_align.py \
           ${DATA}/a.s2t.params ${DATA}/a.s2t.err \
           ${DATA}/a.t2s.params ${DATA}/a.t2s.err \
           fwd \
           < ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src-tgt \
           > ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src-tgt.forward.align

    echo "Running aligner on test data..."
    paste -d '\t' \
          ${DATA}/test.bpe.sink.${SOURCE} \
          ${DATA}/test.bpe.${TARGET} \
          > ${DATA}/test.bpe.${SOURCE}-${TARGET}
    sed -i 's/\t/ ||| /g' ${DATA}/test.bpe.${SOURCE}-${TARGET}
    python ${SCRIPTS}/force_align.py \
           ${DATA}/a.s2t.params ${DATA}/a.s2t.err \
           ${DATA}/a.t2s.params ${DATA}/a.t2s.err \
           fwd \
           < ${DATA}/test.bpe.${SOURCE}-${TARGET} \
           > ${DATA}/test.bpe.${SOURCE}-${TARGET}.forward.align
fi

if $fertilize
then
    for method in guided actual
    do
        python -u ${SCRIPTS}/generate_fertilities.py \
               -method ${method} \
               -train_source ${DATA}/preprocessed.sink.align.train.1.pt.txt.src \
               -train_align ${DATA}/preprocessed.sink.align.train.1.pt.txt.src-tgt.forward.align \
               -dev_source ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src \
               -dev_align ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src-tgt.forward.align \
               -test_source ${DATA}/test.bpe.sink.${SOURCE} \
               -test_align ${DATA}/test.bpe.${SOURCE}-${TARGET}.forward.align
    done

    echo "Training and testing the fertility predictor..."
    ${SCRIPTS}/fertility/train_test_fertility_predictor.sh ${SOURCE} ${TARGET} classification
fi
