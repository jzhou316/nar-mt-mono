#!/bin/bash

set -e

dir=../wmt14/en-de

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
# de 313MB (724MB unzipped), 6,690,332 lines
wget https://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2008.de.shuffled.gz
gunzip news.2008.de.shuffled.gz

# en 672MB (MB unzipped),  lines
# wget https://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2008.en.shuffled.gz
# gunzip news.2008.en.shuffled.gz
# en 197MB (452MB unzipped), 3,782,548 lines
wget https://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2007.en.shuffled.gz
gunzip news.2007.en.shuffled.gz

cd ..



### data processing: tokenization, cleaning long sentences, truecasing, subword segmentation
mkdir -p ./mono

src=en
tgt=de

mosespath=../../wmt16/en-ro_new/moses-scripts/scripts
subwordpath=../../wmt16/en-ro_new/subword-nmt

# take ~3m lines as each mono corpus
head -3020000 ./raw/news.2008.de.shuffled > ./mono/mono.de
head -3020000 ./raw/news.2007.en.shuffled > ./mono/mono.en

# tokenize
echo "tokenizing..."
for data in mono/mono
do
    for l in $src $tgt
    do
    cat $data.$l \
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
    $mosespath/recaser/truecase.perl -model model/truecase-model.$l < mono/mono.tok.clean.$l > mono/mono.tc.$l
done


# train BPE
# echo "BPE encoding..."
# cat train/train.tc.$src train/train.tc.$tgt | $subwordpath/learn_bpe.py -s 40000 > train/$src$tgt.bpe

# apply BPE
for prefix in mono/mono
do
    for l in $src $tgt
    do
        $subwordpath/apply_bpe.py -c model/$src$tgt.bpe < $prefix.tc.$l > $prefix.bpe.$l
        wc -l $prefix.bpe.$l
    done
done

echo "All finished!"

# final mono corpus: 3,008,621 for en, 3,015,110 for de
