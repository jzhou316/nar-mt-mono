#!/bin/bash

set -e


dir=../iwslt16/en-de

if [ ! -d "$dir" ]; then
    mkdir $dir
fi

cd $dir


### download the WMT16 En-De monolingual dataset
if [ ! -d "./raw" ]; then
   mkdir ./raw
fi

cd ./raw

# download datasets here
# de 107MB (333MB unzipped), 2176537 lines
wget https://www.statmt.org/wmt14/training-monolingual-europarl-v7/europarl-v7.de.gz
gunzip europarl-v7.de.gz

# en 99MB (310MB unzipped), 2218201 lines
wget http://www.statmt.org/wmt14/training-monolingual-europarl-v7/europarl-v7.en.gz
gunzip europarl-v7.en.gz

cd ..



### data processing: tokenization, cleaning long sentences, truecasing, subword segmentation
mkdir -p ./mono

src=en
tgt=de

mosespath=../../wmt16/en-ro_new/moses-scripts/scripts
subwordpath=../../wmt16/en-ro_new/subword-nmt

# tokenize
echo "tokenizing..."
for data in mono/mono
do
    for l in $src $tgt
    do
    cat raw/europarl-v7.$l \
        | $mosespath/tokenizer/normalize-punctuation.perl -l $l \
        | $mosespath/tokenizer/tokenizer.perl -threads 4 -a -l $l > $data.tok.$l
    done
done

# clean empty and long sentences, and sentences with high source-target ratio (training corpus only)
echo "cleaning corpus..."
$mosespath/training/clean-corpus-n.perl mono/mono.tok $src $src mono/mono.tok.clean 1 80
$mosespath/training/clean-corpus-n.perl mono/mono.tok $tgt $tgt mono/mono.tok.clean 1 80

# train truecaser
# echo "training true caser..."
# for l in $src $tgt
# do
#     $mosespath/recaser/train-truecaser.perl -corpus train/train.tok.clean.$l -model train/truecase-model.$l
# done

# apply truecaser (cleaned training corpus, dev, and test sets)
echo "applying true caser..."
for l in $src $tgt
do
    $mosespath/recaser/truecase.perl -model train/truecase-model.$l < mono/mono.tok.clean.$l > mono/mono.tc.$l
done


# train BPE
# echo "BPE encoding..."
# cat train/train.tc.$src train/train.tc.$tgt | $subwordpath/learn_bpe.py -s 40000 > train/$src$tgt.bpe

# apply BPE
for prefix in mono/mono
do
    for l in $src $tgt
    do
        $subwordpath/apply_bpe.py -c train/$src$tgt.bpe < $prefix.tc.$l > $prefix.bpe.$l
    done
done

echo "All finished!"

# final mono corpus: 2197792 for en, 2162228 for de
