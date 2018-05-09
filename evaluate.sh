model=$1
source=$2
target=$3

gpu=0
dump_attention=true #false

# Set use_fertility_type=true to try out the predicted fertilities
# on a model trained with actual fertilities.
use_fertility_type=false #true
fertility_type=predicted

use_attn_transform=false
attn_transform=constrained_softmax
c_attn=0.2

beam=10
srclang=tr
tgtlang=en

langpair=${srclang}-${tgtlang}
align=data/${langpair}/corpus.bpe.${langpair}.forward.align
train_src=data/${langpair}/corpus.bpe.${srclang}

cd ..

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
	python -u translate.py -model $model -src $source -output $target.pred -beam_size $beam -batch_size 1 -alpha ${alpha} -beta ${beta} -min_attention 0.1 ${extra_flags} -replace_unk -verbose -gpu $gpu
	sed -r 's/(@@ )|(@@ ?$)//g' $target.pred > $target.pred.merged
	sed -r 's/(@@ )|(@@ ?$)//g' $target > $target.merged
	echo ""
	echo "alpha = $alpha, beta = $beta"
	perl multi-bleu.perl -lc $target.merged < $target.pred.merged
	java -Xmx2G -jar meteor-1.5/meteor-1.5.jar $target.pred.merged $target.merged -l $tgtlang | tail -1
    done
done
