#!/bin/bash

set -e

dir=../wmt16/en-ro_new

if [ -f "$dir" ]; then
    mkdir $dir
fi

cd $dir

if [ -f "./raw" ]; then
    mkdir ./raw
if

cd ./raw
# download training set
wget http://data.statmt.org/wmt16/translation-task/training-parallel-ep-v8.tgz
wget http://opus.nlpl.eu/download.php?f=SETIMES/v2/moses/en-ro.txt.zip -O SETIMES2.ro-en.txt.zip
# download dev and test set
wget http://data.statmt.org/wmt16/translation-task/dev.tgz
wget http://data.statmt.org/wmt16/translation-task/dev-romanian-updated.tgz
wget http://data.statmt.org/wmt16/translation-task/test.tgz

# extract training set
tar -xzvf training-parallel-ep-v8.tgz
unzip SETIMES2.ro-en.txt.zip

# download processed dev and test set using sacrebleu
# (otherwise, process the downloaded .sgm files, references:
# https://github.com/tensorflow/nmt/blob/0be864257a76c151eef20ea689755f08bc1faf4e/nmt/scripts/wmt16_en_de.sh#L77
# https://github.com/pytorch/fairseq/blob/9398a2829596393b73f5c5f1b99edf4c2d8f9316/examples/translation/prepare-wmt14en2de.sh#L106)
mkdir ../test
mkdir ../dev
cd ../
sacrebleu -t wmt16 -l en-ro --echo src > test/test.en
sacrebleu -t wmt16 -l en-ro --echo ref > test/test.ro
sacrebleu -t wmt16/dev -l en-ro --echo src > dev/dev.en
sacrebleu -t wmt16/dev -l en-ro --echo ref > dev/dev.ro

# process training set
mkdir ./train
cat raw/training-parallel-ep-v8/europarl-v8.ro-en.en raw/SETIMES.en-ro.en > train/corpus.en
cat raw/training-parallel-ep-v8/europarl-v8.ro-en.ro raw/SETIMES.en-ro.ro > train/corpus.ro

# download processing scripts
git clone https://github.com/marian-nmt/mtm2017-tutorial
git clone https://github.com/marian-nmt/moses-scripts
git clone https://github.com/rsennrich/subword-nmt

# processing: tokenization
cat train/corpus.ro \
    | ./moses-scripts/scripts/tokenizer/normalize-punctuation.perl -l ro \
    | ./mtm2017-tutorial/scripts/normalise-romanian.py \
    | ./mtm2017-tutorial/scripts/remove-diacritics.py \
    | ./moses-scripts/scripts/tokenizer/tokenizer.perl -threads 4 -a -l ro > train/corpus.tok.ro

cat train/corpus.en \
    | ./moses-scripts/scripts/tokenizer/normalize-punctuation.perl -l en \
    | ./moses-scripts/scripts/tokenizer/tokenizer.perl -threads 4 -a -l en > train/corpus.tok.en


cat dev/dev.ro \
    | ./moses-scripts/scripts/tokenizer/normalize-punctuation.perl -l ro \
    | ./mtm2017-tutorial/scripts/normalise-romanian.py \
    | ./mtm2017-tutorial/scripts/remove-diacritics.py \
    | ./moses-scripts/scripts/tokenizer/tokenizer.perl -threads 4 -a -l ro > dev/dev.tok.ro

cat dev/dev.en \
    | ./moses-scripts/scripts/tokenizer/normalize-punctuation.perl -l en \
    | ./moses-scripts/scripts/tokenizer/tokenizer.perl -threads 4 -a -l en > dev/dev.tok.en

cat test/test.ro \
    | ./moses-scripts/scripts/tokenizer/normalize-punctuation.perl -l ro \
    | ./mtm2017-tutorial/scripts/normalise-romanian.py \
    | ./mtm2017-tutorial/scripts/remove-diacritics.py \
    | ./moses-scripts/scripts/tokenizer/tokenizer.perl -threads 4 -a -l ro > test/test.tok.ro

cat test/test.en \
    | ./moses-scripts/scripts/tokenizer/normalize-punctuation.perl -l en \
    | ./moses-scripts/scripts/tokenizer/tokenizer.perl -threads 4 -a -l en > test/test.tok.en

# Clean empty and long sentences, and sentences with high source-target ratio (training corpus only):
./moses-scripts/scripts/training/clean-corpus-n.perl train/corpus.tok ro en train/corpus.clean.tok 1 80

# train truecaser
./moses-scripts/scripts/recaser/train-truecaser.perl -corpus train/corpus.clean.tok.ro -model train/truecase-model.ro
./moses-scripts/scripts/recaser/train-truecaser.perl -corpus train/corpus.clean.tok.en -model train/truecase-model.en

# Apply truecaser to cleaned training corpus
for prefix in train/corpus.clean dev/dev test/test
do
    ./moses-scripts/scripts/recaser/truecase.perl -model train/truecase-model.ro < $prefix.tok.ro > $prefix.tc.ro
    ./moses-scripts/scripts/recaser/truecase.perl -model train/truecase-model.en < $prefix.tok.en > $prefix.tc.en
done

# actually, make everything lowercase, as is consistent with the dataset used in Lee et. al
sed 's/.*/\L&/g' < train/corpus.clean.tok.en > train/corpus.lw.en
sed 's/.*/\L&/g' < train/corpus.clean.tok.ro > train/corpus.lw.ro
sed 's/.*/\L&/g' < dev/dev.tok.en > dev/dev.lw.en
sed 's/.*/\L&/g' < dev/dev.tok.ro > dev/dev.lw.ro
sed 's/.*/\L&/g' < test/test.tok.en > test/test.lw.en
sed 's/.*/\L&/g' < test/test.tok.ro > test/test.lw.ro

# train bpe
cat train/corpus.lw.ro train/corpus.lw.en | ./subword-nmt/learn_bpe.py -s 40000 > train/roen.bpe

# apply bpe
for prefix in train/corpus dev/dev test/test
do
    ./subword-nmt/apply_bpe.py -c train/roen.bpe < $prefix.lw.ro > $prefix.bpe.ro
    ./subword-nmt/apply_bpe.py -c train/roen.bpe < $prefix.lw.en > $prefix.bpe.en
done

