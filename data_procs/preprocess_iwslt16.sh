#!/bin/bash

set -e


dir=../iwslt16/en-de

if [ ! -d "$dir" ]; then
    mkdir $dir
fi

cd $dir

src=en
tgt=de

### download the IWSLT16 En-De dataset
if [ ! -d "./raw" ]; then
   mkdir ./raw
fi

cd ./raw

# download datasets here
# the WIT data website (including all years' of data): https://wit3.fbk.eu/
# 2016 data relase: https://wit3.fbk.eu/mt.php?release=2016-01
# wrong link from clicking the website:
# wget "https://wit3.fbk.eu/download.php?release=2016-01&type=texts&slang=en&tlang=de"    
# a. the above link works when opening in a browser to download, but it is not the link for the file;
# b. note that the "" is needed, since otherwise "&" will be interpreted as bash symbols
# to find the link, you have to download using the browser and then check the actual link 
# [https://askubuntu.com/questions/1188381/how-to-get-link-of-file-to-download-with-wget]

wget https://wit3.fbk.eu/archive/2016-01//texts/en/de/en-de.tgz
tar -xzvf en-de.tgz

cd ..

### process the train data: remove tags
mkdir -p ./train

train_prefix=train.tags.en-de

echo "pre-processing traind data"
for l in $src $tgt
do
    sed '/^<.*>$/d' ./raw/en-de/${train_prefix}.$l > ./train/train.$l
    # or refer to the Python code snippet for removing the tags
    # https://pytorchnlp.readthedocs.io/en/latest/_modules/torchnlp/datasets/iwslt.html
done


### process the dev and test sets: from .xml (.sgm format)
mkdir -p ./dev
mkdir -p ./test

dev_prefix=IWSLT16.TED.tst2013.en-de
test_prefix=IWSLT16.TED.tst2014.en-de

echo "pre-processing dev data"
for l in $src $tgt
do
    grep '<seg id' ./raw/en-de/${dev_prefix}.$l.xml | \
        sed -e 's/<seg id="[0-9]*">\s*//g' | \
        sed -e 's/\s*<\/seg>\s*//g' \
    > ./dev/dev.$l

    # this uses the perl script from mosesdecoder, which yields same outputs
    ../../wmt16/en-ro_new/moses-scripts/scripts/generic/input-from-sgm.perl \
    < ./raw/en-de/${dev_prefix}.$l.xml \
    > ./dev/dev.moses_sgm.$l

done


echo "pre-processing test data"
for l in $src $tgt
do
    grep '<seg id' ./raw/en-de/${test_prefix}.$l.xml | \
        sed -e 's/<seg id="[0-9]*">\s*//g' | \
        sed -e 's/\s*<\/seg>\s*//g' \
    > ./test/test.$l
    
    # this uses the perl script from mosesdecoder, which yields same outputs
    ../../wmt16/en-ro_new/moses-scripts/scripts/generic/input-from-sgm.perl \
    < ./raw/en-de/${test_prefix}.$l.xml \
    > ./test/test.moses_sgm.$l

done


### more processing: tokenization, cleaning long sentences, truecasing, subword segmentation
src=en
tgt=de

mosespath=../../wmt16/en-ro_new/moses-scripts/scripts
subwordpath=../../wmt16/en-ro_new/subword-nmt

# tokenize
echo "tokenizing..."
for data in train/train dev/dev test/test
do
    for l in $src $tgt
    do
    cat $data.$l \
        | $mosespath/tokenizer/normalize-punctuation.perl -l $l \
        | $mosespath/tokenizer/tokenizer.perl -threads 4 -a -l $l > $data.tok.$l
    done
done

# clean empty and long sentences, and sentences with high source-target ratio (training corpus only)
echo "cleaning training corpus..."
$mosespath/training/clean-corpus-n.perl train/train.tok $src $tgt train/train.tok.clean 1 80

# train truecaser
echo "training true caser..."
for l in $src $tgt
do
    $mosespath/recaser/train-truecaser.perl -corpus train/train.tok.clean.$l -model train/truecase-model.$l
done

# apply truecaser (cleaned training corpus, dev, and test sets)
echo "applying true caser..."
for l in $src $tgt
do
    $mosespath/recaser/truecase.perl -model train/truecase-model.$l < train/train.tok.clean.$l > train/train.tc.$l
done

for prefix in dev/dev test/test
do
    for l in $src $tgt
    do
        $mosespath/recaser/truecase.perl -model train/truecase-model.$l < $prefix.tok.$l > $prefix.tc.$l
    done
done

# train BPE
echo "BPE encoding..."
cat train/train.tc.$src train/train.tc.$tgt | $subwordpath/learn_bpe.py -s 40000 > train/$src$tgt.bpe

# apply BPE
for prefix in train/train dev/dev test/test
do
    for l in $src $tgt
    do
        $subwordpath/apply_bpe.py -c train/$src$tgt.bpe < $prefix.tc.$l > $prefix.bpe.$l
    done
done

echo "All finished!"

