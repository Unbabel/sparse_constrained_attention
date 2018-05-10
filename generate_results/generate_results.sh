SOURCE=de
TARGET=en
LANGPAIR=${SOURCE}-${TARGET}
ALIGNER=/home/ubuntu/fast_align/build
ALIGNER_DATA=aligner_data
MT_DATA=mt_predictions
SCRIPTS=scripts

train_aligner=true
report_bleu=true
report_rep_score=true
report_dropped_alignments=true

if $train_aligner 
then

    echo "Training aligner..."
    
    paste -d '\t' \
          corpus.${SOURCE} \
          corpus.${TARGET} \
          > ${ALIGNER_DATA}/corpus.${LANGPAIR}

    sed -i 's/\t/ ||| /g' ${ALIGNER_DATA}/corpus.${LANGPAIR}

    ${ALIGNER}/fast_align -i ${ALIGNER_DATA}/corpus.${LANGPAIR} -d -o -v \
               -p ${ALIGNER_DATA}/a.s2t.params \
               > ${ALIGNER_DATA}/corpus.${LANGPAIR}.forward.align \
               2> ${ALIGNER_DATA}/a.s2t.err

    ${ALIGNER}/fast_align -i ${ALIGNER_DATA}/corpus.${LANGPAIR} -d -o -v -r \
               -p ${ALIGNER_DATA}/a.t2s.params \
               > ${ALIGNER_DATA}/corpus.${LANGPAIR}.reverse.align \
               2> ${ALIGNER_DATA}/a.t2s.err

    echo "Running aligner on test data (creates src_ref.align)..."

    paste -d '\t' \
          test.${SOURCE} \
          test.${TARGET} \
          > ${ALIGNER_DATA}/src_ref.${LANGPAIR}
          
    sed -i 's/\t/ ||| /g' ${ALIGNER_DATA}/src_ref.${LANGPAIR}

    python ${ALIGNER}/force_align.py \
           ${ALIGNER_DATA}/a.s2t.params ${ALIGNER_DATA}/a.s2t.err \
           ${ALIGNER_DATA}/a.t2s.params ${ALIGNER_DATA}/a.t2s.err \
           < ${ALIGNER_DATA}/src_ref.${LANGPAIR} \
           > ${ALIGNER_DATA}/src_ref.align

    echo

fi

for file in $MT_DATA/*
do
   
    echo $(basename $file)

    if $report_bleu
    then
        ${SCRIPTS}/multi-bleu.pl -lc test.${TARGET} < ${file}
    fi

    if $report_rep_score
    then
        python3 ${SCRIPTS}/rep_score.py \
                           -r test.${TARGET} \
                           -p ${file} \
                           --normalize
    fi

    if $report_dropped_alignments
    then

        paste -d '\t' \
              test.${SOURCE} \
              $file \
              > ${ALIGNER_DATA}/src_mt.${LANGPAIR}

        sed -i 's/\t/ ||| /g' ${ALIGNER_DATA}/src_mt.${LANGPAIR}

        python ${ALIGNER}/force_align.py \
               ${ALIGNER_DATA}/a.s2t.params ${ALIGNER_DATA}/a.s2t.err \
               ${ALIGNER_DATA}/a.t2s.params ${ALIGNER_DATA}/a.t2s.err \
               < ${ALIGNER_DATA}/src_mt.${LANGPAIR} \
               > ${ALIGNER_DATA}/src_mt.align

        python3 ${SCRIPTS}/drop_score.py \
                           --align_data_path ${ALIGNER_DATA}/ \
                           --test_source_path test.${SOURCE} \
                           
    fi

    echo

done
