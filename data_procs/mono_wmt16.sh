#!/bin/bash

set -e

cd ../wmt16/en-ro_new

# download the monolingual data
cd ./raw
# ro 125MB, 2280642 lines
wget http://data.statmt.org/wmt16/translation-task/news.2015.ro.shuffled.gz
gunzip news.2015.ro.shuffled.gz

# en 99MB, 2218201 lines
wget http://www.statmt.org/wmt14/training-monolingual-europarl-v7/europarl-v7.en.gz
gunzip europarl-v7.en.gz


cd ..

mkdir ./mono
# process the data: tokenize
cat raw/news.2015.ro.shuffled \
    | ./moses-scripts/scripts/tokenizer/normalize-punctuation.perl -l ro \
    | ./mtm2017-tutorial/scripts/normalise-romanian.py \
    | ./mtm2017-tutorial/scripts/remove-diacritics.py \
    | ./moses-scripts/scripts/tokenizer/tokenizer.perl -threads 4 -a -l ro > mono/mono.tok.ro

cat raw/europarl-v7.en \
    | ./moses-scripts/scripts/tokenizer/normalize-punctuation.perl -l en \
    | ./moses-scripts/scripts/tokenizer/tokenizer.perl -threads 4 -a -l en > mono/mono.tok.en

# Clean empty and long sentences, and sentences with high source-target ratio (training corpus only):
./moses-scripts/scripts/training/clean-corpus-n.perl mono/mono.tok ro en mono/mono.clean.tok 1 80

# make everything lowercase
sed 's/.*/\L&/g' < mono/mono.clean.tok.en > mono/mono.lw.en
sed 's/.*/\L&/g' < mono/mono.clean.tok.ro > mono/mono.lw.ro

# apply bpe
prefix=mono/mono
./subword-nmt/apply_bpe.py -c train/roen.bpe < $prefix.lw.ro > $prefix.bpe.ro
./subword-nmt/apply_bpe.py -c train/roen.bpe < $prefix.lw.en > $prefix.bpe.en

# final mono corpus: 2197792 for en, 2261206 for ro

