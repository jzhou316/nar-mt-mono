### WMT14 En-De

1. Data from the [iterative refinement paper](https://github.com/nyu-dl/dl4mt-nonauto/tree/multigpu):
- including both original, tokenized, and bpe (40000) data
- not sure how the tokenization is done
- using sacremoses tokenizer can get similar results, but there are a few differences:
  - `p.m.` in this dataset is **not** split to 'p.m .' at the end of the sentence (and there are other similar cases as well)
  - `&quot;` is placed to be after `,` and `.`, and I'm not sure how this is done
  - the first letter of each sentence is lowercased, with the exception of special words. This should also be useful for a cleaner vocabulary, but I'm not sure how this is done ---> This is by truecaser!
- **Note** the data processing bash file is in the folder

2. Data from GluonNLP:
- [built-in dataset](https://github.com/dmlc/gluon-nlp/blob/e09281c8b1a9363375fdf4f898db78008804d1e8/src/gluonnlp/data/translation.py#L197)
  ```
  import gluonnlp as nlp
  
  ende_dataset = nlp.data.WMT2014('train', full=False)    
  ende_bpe_dataset = nlp.data.WMT2014BPE('train', full=False)    # 'newstest2013' for val, 'news2014' for test
                                                                 # full=True for full test set, otherwise filtered
  ```
- this will download the dataset from https://apache-mxnet.s3-accelerate.dualstack.amaznaws.com/gluon/dataset/..., and automatically
  save to ~/.mxnet/datasets/wmt2014/de_en/
- the bpe data is after tokenization and bpe (32000), with process modified from https://github.com/tensorflow/nmt/blob/master/nmt/scripts/wmt16_en_de.sh
- the tokenization is not the same as above, for example, no `&quot`, and no `@-@`, etc.

3. Data from [fairseq](https://github.com/pytorch/fairseq/tree/master/examples/translation#prepare-wmt14en2desh):
- run the [script](https://github.com/pytorch/fairseq/blob/master/examples/translation/prepare-wmt14en2de.sh), with instruction [here](https://github.com/pytorch/fairseq/tree/master/examples/translation#prepare-wmt14en2desh) 
- including tokenization and bpe, dataset by default include WMT2017 
- for tokenization: training set -- multiple scripts are run, test set -- only tokenization script is run
- validation set is separated from part of the training set, thus is large


### Moses Tokenizer

1. perl scripts from the [mosesdecoder repo](https://github.com/moses-smt/mosesdecoder/blob/master/scripts/tokenizer/tokenizer.perl)

```
perl mosesdecoder/scripts/tokenizer/tokenizer.perl -l en -a -threads 8 < data.en > data.tok.en
```

2. [SacreMoses](https://github.com/alvations/sacremoses)

```
sacremoses tokenize -l en -a -j 4 < data.en > data.tok.en
```

**Note**

Although the above two methods should give the same results, as of 11/15/2019, the above two lines yield different tokenization results!
In particular, one different case is that the period . at the end of some sentences is not split when using sacremoses!

For example, `a.m. --> a.m .`, `p.m. --> p.m .`, `S. --> S .` when using the perl script, but the same when using sacremoses. Splitting may be more benefitial for translation tasks in terms of a cleaner vocabulary.


### Data Preprocessing

https://jon.dehdari.org/teaching/uds/smt_intro/

https://marian-nmt.github.io/examples/mtm2017/intro/

