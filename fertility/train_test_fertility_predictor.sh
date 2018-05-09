SOURCE=$1 # ro
TARGET=$2 # en
MODEL_TYPE=$3 # classification|regression
LANGPAIR=${SOURCE}-${TARGET}
DATA=/mnt/disk/afm/data/${LANGPAIR}
#DATA=/mnt/data/home/afm/mt_data/data/${LANGPAIR}

train=true
gpu=0

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
        >& ../logs/log_${LANGPAIR}_fertility_${MODEL_TYPE}_train.txt
fi

CUDA_VISIBLE_DEVICES=${gpu} \
    python -u fertility_predictor.py --gpu \
    --epochs 10 \
    --model_type ${MODEL_TYPE} \
    --train_source_path ${DATA}/preprocessed.sink.align.train.1.pt.txt.src \
    --train_alignments_path ${DATA}/preprocessed.sink.align.train.1.pt.txt.src-tgt.forward.align \
    --dev_source_path ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src \
    --dev_alignments_path ${DATA}/preprocessed.sink.align.valid.1.pt.txt.src-tgt.forward.align \
    --test --test_source_path ${DATA}/newstest2016.bpe.sink.${SOURCE}


