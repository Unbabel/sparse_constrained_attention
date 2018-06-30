SOURCE=$1 # ro
TARGET=$2 # en
MODEL_TYPE=$3 # classification|regression
LANGPAIR=${SOURCE}-${TARGET}
DATA=/mnt/data/${LANGPAIR}
SCRIPTS="`cd $(dirname $0);cd ..;pwd`"
LOGS=${SCRIPTS}/logs

train=false

pred_test=true
pred_valid=true
pred_train=true

gpu=0

cd ${SCRIPTS}/fertility

#mkdir -p ${LOGS}

if $train
then
    echo 'Training...'

    rm -rf fertility_model_${MODEL_TYPE}

    CUDA_VISIBLE_DEVICES=${gpu} \
        python -u fertility_predictor.py --gpu \
        --epochs 10 \
        --model_type ${MODEL_TYPE} \
        --train_source_path ${DATA}/preprocessed.sink.align.train.1.pt.txt.src \
        --train_alignments_path ${DATA}/preprocessed.sink.align.train.1.pt.txt.src-tgt.forward.align \
        --dev_source_path ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src \
        --dev_alignments_path ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src-tgt.forward.align \
        >& ${LOGS}/log_${LANGPAIR}_fertility_${MODEL_TYPE}_train.txt

    echo "Finished training"
    echo

fi

if ${pred_test}
then
    CUDA_VISIBLE_DEVICES=${gpu} \
        python -u fertility_predictor.py --gpu \
        --epochs 10 \
        --model_type ${MODEL_TYPE} \
        --train_source_path ${DATA}/preprocessed.sink.align.train.1.pt.txt.src \
        --train_alignments_path ${DATA}/preprocessed.sink.align.train.1.pt.txt.src-tgt.forward.align \
        --dev_source_path ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src \
        --dev_alignments_path ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src-tgt.forward.align \
        --test --test_source_path ${DATA}/newstest2016.bpe.sink.${SOURCE}

    echo "Predicted test"
    echo
fi

if ${pred_valid}
then
    CUDA_VISIBLE_DEVICES=${gpu} \
        python -u fertility_predictor.py --gpu \
        --epochs 10 \
        --model_type ${MODEL_TYPE} \
        --train_source_path ${DATA}/preprocessed.sink.align.train.1.pt.txt.src \
        --train_alignments_path ${DATA}/preprocessed.sink.align.train.1.pt.txt.src-tgt.forward.align \
        --dev_source_path ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src \
        --dev_alignments_path ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src-tgt.forward.align \
        --test --test_source_path ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src

    echo "Predicted validation"
    echo
fi

if ${pred_train}
then
    CUDA_VISIBLE_DEVICES=${gpu} \
        python -u fertility_predictor.py --gpu \
        --epochs 10 \
        --model_type ${MODEL_TYPE} \
        --train_source_path ${DATA}/preprocessed.sink.align.train.1.pt.txt.src \
        --train_alignments_path ${DATA}/preprocessed.sink.align.train.1.pt.txt.src-tgt.forward.align \
        --dev_source_path ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src \
        --dev_alignments_path ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src-tgt.forward.align \
        --test --test_source_path ${DATA}/preprocessed.sink.align.train.1.pt.txt.src

    echo "Predicted train"
    echo

fi



