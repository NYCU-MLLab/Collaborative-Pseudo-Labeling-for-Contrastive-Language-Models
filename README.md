# Collaborative Pseudo Labeling for Contrastive Language Models

## Environment setup
### Install via pip:
* Create a virtual environment running Python 3.7:
```
virtualenv .venv --python=3.7
pip install --upgrade pip
```
* To run our code, please install all the dependency packages by using the following command:
```
pip install -r requirements.txt
```

## Dataset download and preprocessing
* Download dataset
```
cd ./data
bash ./download_dataset.sh
cd ..
```

## Training and Evaluation

### Run single experiment on GLUE
**Supported datasets** : MNLI, RTE, QQP, SST-2, subj and MPQA with shots of 10, 20, 30.

Build the glue dataset:
```
cd ./data
python generate_glue_data.py
cd ..
```
Modify the ```K```, ```TASK```, and ```SEED``` in ```run_glue.sh``` and run it:
```
bash ./run_glue.sh
```
* ```MODEL```: choosing ```bert-base-uncased``` or  ```roberta-base```

### Run single experiment on Few-shot
**Supported datasets** : SST-2, SST-5, MR, CR, Subj, MNLI, SNLI, and QNLI with shots of $k$ and ratio $\mu$.

Build the few-shot dataset:
```
cd ./data
python generate_fewshot_data.py
cd ..
```
Most arguments are the same as LM-BFF, and the same manual prompts are used in our experiments.
* ```k (default=16)```: The number of few-shot labeled data
* ```mu (default=4)```: The radio between of few-shot labeled data and unlabeled data

Modify the ```K```, ```MU```, ```TASK```, and ```SEED``` in ```run_fewshot.sh``` and run it:
```
bash ./run_fewshot.sh
```
* ```MODEL```: choosing ```bert-base-uncased``` or  ```roberta-base```

### Run all experiments on GLUE
```
bash ./run.sh
```
* ```MODEL```: choosing ```bert-base-uncased``` or  ```roberta-base```

### Notes and Acknowledgments
The implementation is based on [HuggingFace](https://github.com/huggingface/transformers).
We also used some code from: [LM-BFF](https://github.com/princeton-nlp/LM-BFF) and [SFLM](https://github.com/MatthewCYM/SFLM). 