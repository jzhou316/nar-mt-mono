# nar-mt-mono
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Non-autoregressive neural machine translation with monolingual data

Paper link:\
[Improving Non-autoregressive Neural Machine Translation with Monolingual Data](https://arxiv.org/abs/2005.00932) (ACL 2020)\
Jiawei Zhou, Phillip Keung

<img src=chart_nar_mono_final.png>
<!---<img src=chart_nar_mono_final.png width="500" height="500">--->

## Data

### Paired Data

From the [github repo](https://github.com/nyu-dl/dl4mt-nonauto/tree/multigpu).

- [WMT16 Ro-En](https://drive.google.com/file/d/1YrAwCEuktG-iDVxtEW-FE72uFTLc5QMl/view)
- [WMT14 De-En](https://drive.google.com/file/d/1t7w0dmURRkXIbmzzlIUhrffw8eYctsIT/view)

Download the datasets and extract at the current directory. All the corpus are tokenized and BLEU is evaluated on the tokenized corpus.

### Monolingual Data



## Citing

```
@article{zhou2020improving,
  title={Improving Non-autoregressive Neural Machine Translation with Monolingual Data},
  author={Zhou, Jiawei and Keung, Phillip},
  journal={arXiv preprint arXiv:2005.00932},
  year={2020}
}
```
