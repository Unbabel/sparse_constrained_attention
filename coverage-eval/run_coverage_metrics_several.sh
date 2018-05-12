ALIGNER=/home/ubuntu/fast_align/build

SRC=$1
TGT=$2
TEST_SRC=$3
TEST_TGT=$4
ALIGNER_DATA=$5
MT_DATA=$6
LP=${SRC}-${TGT}

if [ "$#" != "6" ]
then
    echo "Illegal number of parameters"
    echo "Usage:"
    echo "./run_all_coverage_metrics_several.sh source_language target_language test_source test_target aligner_data_path mt_predictions_path"
    echo "Example:"
    echo "./run_all_coverage_metrics_several.sh ro en <PATH>/newstest.ro <PATH>/newstest.en <AlignerDataPath> <MtPredictionsPath>"
    exit
fi

for file in ${MT_DATA}/*
do
   
    echo $(basename $file)

    python3 rep_score.py \
            -r ${TEST_TGT} \
            -p ${file} \
            --normalize

    paste -d '\t' \
          ${TEST_SRC} \
          ${file} \
          > ${ALIGNER_DATA}/src_mt.${LP}

    sed -i 's/\t/ ||| /g' ${ALIGNER_DATA}/src_mt.${LP}

    python ${ALIGNER}/force_align.py \
           ${ALIGNER_DATA}/a.s2t.params ${ALIGNER_DATA}/a.s2t.err \
           ${ALIGNER_DATA}/a.t2s.params ${ALIGNER_DATA}/a.t2s.err \
           < ${ALIGNER_DATA}/src_mt.${LP} \
           > ${ALIGNER_DATA}/src_mt.align

    python3 drop_score.py \
            --src_ref_align ${ALIGNER_DATA}/src_ref.align \
            --src_mt_align ${ALIGNER_DATA}/src_mt.align
                           
    echo
 
done
