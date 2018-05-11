ALIGNER=/home/ubuntu/fast_align/build

SRC=$1
TGT=$2
CORPUS_SRC=$3
CORPUS_TGT=$4
TEST_SRC=$5
TEST_TGT=$6
LP=${SRC}-${TGT}

if [ "$#" != "6" ]
then
    echo "Illegal number of parameters"
    echo "Usage:"
    echo "./train_aligner source_language target_language train_source train_target test_source test_target"
    echo "Example:"
    echo "./train_aligner ro en <PATH>/corpus.ro <PATH>/corpus.en <PATH>/newstest.ro <PATH>/newstest.en"
    exit
fi

echo "Training aligner..."
    
paste -d '\t' \
      ${CORPUS_SRC} \
      ${CORPUS_TGT} \
      > corpus.${LP}

sed -i 's/\t/ ||| /g' corpus.${LP}

echo "... Training forward ... "

${ALIGNER}/fast_align -i corpus.${LP} -d -o -v \
                      -p a.s2t.params \
                       > corpus.${LP}.forward.align \
                      2> a.s2t.err

echo "... Training reverse ... "

${ALIGNER}/fast_align -i corpus.${LP} -d -o -v -r \
                      -p a.t2s.params \
                       > corpus.${LP}.reverse.align \
                      2> a.t2s.err

echo "Running aligner on test data (creates src_ref.align)..."

paste -d '\t' \
      ${TEST_SRC} \
      ${TEST_TGT} \
      > src_ref.${LP}
          
sed -i 's/\t/ ||| /g' src_ref.${LP}

python ${ALIGNER}/force_align.py \
       a.s2t.params a.s2t.err \
       a.t2s.params a.t2s.err \
       < src_ref.${LP} \
       > src_ref.align

