model=$1
source=$2 #bpe.sink
target=$3 #bpe

# Extra parameters
OPENNMT=/home/ubuntu/OpenNMT-py-un
SCRIPTS="`cd $(dirname $0);pwd`"
echo ${SCRIPTS}
gpu=0
beam=10
srclang=de
tgtlang=en
langpair=${srclang}-${tgtlang}-md
#align=data/${langpair}/corpus.bpe.${langpair}.forward.align
#train_src=data/${langpair}/corpus.bpe.${srclang}

# Dump attention flag
dump_attention=false

# Set use_fertility_type=true to try out the predicted fertilities
# on a model trained with actual fertilities.
use_fertility_type=false
fertility_type=predicted

# Attention transformation
use_attn_transform=false
attn_transform=softmax
c_attn=0

extra_flags=""
if ${dump_attention}
then
    extra_flags="${extra_flags} -tgt ${target} -dump_attn"
fi
if ${use_fertility_type}
then
    extra_flags="${extra_flags} -fertility_type ${fertility_type}"
fi
if ${use_attn_transform}
then
    extra_flags="${extra_flags} -attn_transform ${attn_transform} -c_attn ${c_attn}"
fi

for alpha in 0 #0 0.2 0.4 0.6 0.8 1
do
    for beta in 0 #0 0.2 0.4 0.6 0.8 1
    do
	    cd ${OPENNMT}
	    python -u translate.py -model ${model} \
                               -src ${source} \
                               -output ${target}.pred \
                               -beam_size ${beam} \
                               -batch_size 30 \
                               -min_length 2 \
                               -coverage_penalty wu \
                               -length_penalty wu \
                               -alpha ${alpha} \
                               -beta ${beta} \
                               -min_attention 0.1 \
                                ${extra_flags} \
                               -replace_unk \
                               -gpu ${gpu}
	
        sed -r 's/(@@ )|(@@ ?$)//g' ${target}.pred > ${target}.pred.merged
	    sed -r 's/(@@ )|(@@ ?$)//g' ${target} > ${target}.merged
	    echo ""
	    echo "alpha = ${alpha}, beta = ${beta}"
	
	    cd ${SCRIPTS}
	    perl multi-bleu.perl -lc ${target}.merged < ${target}.pred.merged
	    java -Xmx2G -jar meteor-1.5/meteor-1.5.jar ${target}.pred.merged ${target}.merged -l ${tgtlang} | tail -1
    done
done

#MT_PREDICTIONS_PATH=/home/ubuntu/NMT-Code/attention_comparison/thesis/generate_results_${srclang}_${tgtlang}
#MT_PREDICTIONS_PATH=/home/ubuntu/NMT-Code/attention_comparison/thesis/guided_nmt/generate_results_${srclang}_${tgtlang}_domain
#POS=base-csp-true
#cp ${target}.pred ${MT_PREDICTIONS_PATH}/preds/test.${srclang}.pred.${POS}
#cp ${target}.pred.merged ${MT_PREDICTIONS_PATH}/mt_predictions/test.${srclang}.pred.${POS}.merged
