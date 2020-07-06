#!/bin/bash

set -e


dir=../iwslt16/en-de

cd $dir


### more processing: tokenization, cleaning long sentences, truecasing, subword segmentation
src=en
tgt=de

mosespath=../../wmt16/en-ro_new/moses-scripts/scripts
subwordpath=../../wmt16/en-ro_new/subword-nmt

# tokenize
echo "tokenizing..."
for data in test/wmt14-en-de
do
    for l in $src $tgt
    do
    cat $data.$l \
        | $mosespath/tokenizer/normalize-punctuation.perl -l $l \
        | $mosespath/tokenizer/tokenizer.perl -threads 4 -a -l $l > $data.tok.$l
    done
done


# apply truecaser
echo "applying true caser..."
for prefix in test/wmt14-en-de
do
    for l in $src $tgt
    do
        $mosespath/recaser/truecase.perl -model train/truecase-model.$l < $prefix.tok.$l > $prefix.tc.$l
    done
done


# apply BPE
for prefix in test/wmt14-en-de
do
    for l in $src $tgt
    do
        $subwordpath/apply_bpe.py -c train/$src$tgt.bpe < $prefix.tc.$l > $prefix.bpe.$l
    done
done

echo "All finished!"
