# Generic things
SRC=de
TGT=en
LANGPAIR=${SRC}-${TGT}

# Paths
DATA=/mnt/data/${LANGPAIR}-scnmt
SRC_FILE=${DATA}/dev.bpe.sink.${SRC}
ONMT_PATH=/home/ubuntu/OpenNMT-py-un

# Specific things to translation
#for path in ${DATA}/*/; do
    
#    d=$(echo ${path} | cut -d'/' -f5)

    d=csoftmax_fixed_2_0.0
    d=csoftmax_predicted_0.4

    #for MODEL in ${path}*; do

    for MODEL in ${DATA}/${d}/*;do

        echo "Translating with model: ${MODEL}"
        echo "Namefile: ${d}"

        python -u ${ONMT_PATH}/translate.py \
                 -model ${MODEL} \
                 -src ${SRC_FILE} \
                 -output ${SRC_FILE}.pred \
                 -beam_size 5 \
                 -min_length 3 \
                 -replace_unk \
                 -gpu 0

        # CHANGE THE NAME OF THE FILE

        # Copy the predictions to the right folders
        THESIS_PATH=/home/ubuntu/NMT-Code/attention_comparison/thesis
        HOME_PATH=${THESIS_PATH}/constrained_sparse_experiments/
        PRED_PATH=${HOME_PATH}/generate_results_${SRC}_${TGT}/preds
        MT_PATH=${HOME_PATH}/generate_results_${SRC}_${TGT}/mt_predictions

        FN=$(echo ${SRC_FILE} | cut -d'/' -f5)
        cp ${SRC_FILE}.pred ${PRED_PATH}/${FN}.pred.${d}
        sed -r 's/(@@ )|(@@ ?$)//g' ${PRED_PATH}/${FN}.pred.${d} > \
                                    ${MT_PATH}/${FN}.pred.${d}.merged

    done
#done

