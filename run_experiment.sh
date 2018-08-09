gpu=$1
SOURCE=$2 # ro
TARGET=$3 # en
SEED=$4
ATTN=$5 # softmax|sparsemax|csoftmax|csparsemax
cattn=$6 # 0|0.2
FERTTYPE=$7 # none|fixed|guided|predicted|actual
FERTILITY=$8 # none|2|3
COVERAGE=$9 # true|false
LAMBDA_COVERAGE=$10 # 1
train=true

echo "Parameters:"
echo "gpu: ${gpu}"
echo "source: ${SOURCE}"
echo "target: ${TARGET}"
echo "seed: ${SEED}"
echo "attention: ${ATTN}"
echo "constrained attention value: ${cattn}"
echo "fertility type: ${FERTTYPE}"

LANGPAIR=${SOURCE}-${TARGET}-md
DATA=/mnt/data/${LANGPAIR}
MODEL=/mnt/model/${LANGPAIR}
OPENNMT=/home/ubuntu/OpenNMT-py-un
SCRIPTS="`cd $(dirname $0);pwd`"
LOGS=${SCRIPTS}/logs

if [ "$ATTN" == "csparsemax" ]
then
    TRANSFORM=constrained_sparsemax
elif [ "$ATTN" == "csoftmax" ]
then
    TRANSFORM=constrained_softmax
else
    TRANSFORM=${ATTN}
fi

cd ${OPENNMT}
#mkdir -p ${MODEL}
#mkdir -p ${LOGS}

if [ "$COVERAGE" == "true" ]
then
    EXTRA_FLAGS="-coverage_attn -lambda_coverage ${LAMBDA_COVERAGE}"
    EXTRA_NAME="_coverage-1_lambda-${LAMBDA_COVERAGE}"
else
    EXTRA_FLAGS=""
    EXTRA_NAME=""
fi

if $train
then
    if [ "$ATTN" == "softmax" ] || [ "$ATTN" == "sparsemax" ]
    then
        # Add a `-fertility 1` flag to use the sink token (the default is not to use it).
        python -u train.py -data ${DATA}/preprocessed.sink.align \
               -save_model ${MODEL}/preprocessed_${ATTN}_cattn-${cattn}${EXTRA_NAME} \
               -layers 2 \
               -encoder_type brnn \
               -dropout 0.3 \
               -attn_transform ${TRANSFORM} \
               -c_attn ${cattn} \
                ${EXTRA_FLAGS} \
               -seed ${SEED} \
               -gpuid ${gpu} &> \
               ${LOGS}/log_${LANGPAIR}_${ATTN}_cattn-${cattn}${EXTRA_NAME}.txt
    elif [ "$FERTTYPE" == "fixed" ]
    then
        python -u train.py -data ${DATA}/preprocessed.sink.align \
               -save_model ${MODEL}/preprocessed_${ATTN}_${FERTTYPE}-${FERTILITY}_cattn-${cattn}${EXTRA_NAME} \
               -layers 2 \
               -encoder_type brnn \
               -dropout 0.3 \
               -attn_transform ${TRANSFORM} \
               -fertility ${FERTILITY} \
               -fertility_type fixed \
               -c_attn ${cattn} \
                ${EXTRA_FLAGS} \
               -seed ${SEED} \
               -gpuid ${gpu} &> \
               ${LOGS}/log_${LANGPAIR}_${ATTN}_${FERTTYPE}-${FERTILITY}_cattn-${cattn}${EXTRA_NAME}.txt
    elif [ "$FERTTYPE" == "guided" ] || [ "$FERTTYPE" == "predicted" ] || [ "$FERTTYPE" == "actual" ]
    then
        python -u train.py -data ${DATA}/preprocessed.sink.align \
               -save_model ${MODEL}/preprocessed_${ATTN}_${FERTTYPE}_cattn-${cattn}${EXTRA_NAME} \
               -layers 2 \
               -encoder_type brnn \
               -dropout 0.3 \
               -attn_transform ${TRANSFORM} \
               -fertility_type ${FERTTYPE} \
               -c_attn ${cattn} \
                ${EXTRA_FLAGS} \
               -seed ${SEED} \
               -gpuid ${gpu} &> \
               ${LOGS}/log_${LANGPAIR}_${ATTN}_${FERTTYPE}_cattn-${cattn}${EXTRA_NAME}.txt
    fi
fi
