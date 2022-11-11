# Required environment variables:
# TAG: tag for the trail
# TYPE: finetune / prompt / prompt-demo  
# TASK: SST-2 / sst-5 / mr / cr / mpqa / subj / trec / CoLA / MNLI / SNLI / QNLI / RTE / MRPC / QQP / STS-B
# BS: batch size (recommendation: 4)
# LR: learning rate (recommendation: 5e-6)
# SEED: random seed (1/2/3/4/5)
# MODEL: pre-trained model name (roberta-*, bert-*), see Transformers model list

# Number of training instances per label
K=10 # 10 / 20 / 30
GPU=0
TYPE=prompt
TASK=SST-2
BS=4

MODEL=bert-base-uncased # bert-base-uncased / roberta-base

# Training steps
LR=5e-6
EVAL_STEP=1000
# Task specific parameters
# The default length is 128 and the default number of samples is 16.
# For some tasks, we use longer length or double demo (when using demonstrations, double the maximum length).
# For some tasks, we use smaller number of samples to save time (because of the large size of the test sets).
# All those parameters are set arbitrarily by observing the data distributions.
TASK_EXTRA=""
case $TASK in
    CoLA)
        TEMPLATE=*cls**sent_0*_This_is*mask*.*sep+*
        MAPPING="{'0':'incorrect','1':'correct'}"
        ;;
    SST-2)
        TEMPLATE=*cls**sent_0*_It_was*mask*.*sep+*
        MAPPING="{'0':'terrible','1':'great'}"
        ;;
    MRPC)
        TEMPLATE=*cls**sent_0**mask*,*+sentl_1**sep+*
        MAPPING="{'0':'No','1':'Yes'}"
        ;;
    QQP)
        TEMPLATE=*cls**sent_0**mask*,*+sentl_1**sep+*
        MAPPING="{'0':'No','1':'Yes'}"
        TASK_EXTRA="--num_sample 4"
        ;;
    STS-B)
        TEMPLATE=*cls**sent_0**mask*,*+sentl_1**sep+*
        MAPPING="{'0':'No','1':'Yes'}"
        ;;
    MNLI)
        TEMPLATE=*cls**sent-_0*?*mask*,*+sentl_1**sep+*
        MAPPING="{'contradiction':'No','entailment':'Yes','neutral':'Maybe'}"
        TASK_EXTRA="--max_seq_len 256 --num_sample 1"
        ;;
    SNLI)
        TEMPLATE=*cls**sent-_0*?*mask*,*+sentl_1**sep+*
        MAPPING="{'contradiction':'No','entailment':'Yes','neutral':'Maybe'}"
        TASK_EXTRA="--max_seq_len 256 --num_sample 4"
        ;;
    QNLI)
        TEMPLATE=*cls**sent-_0*?*mask*,*+sentl_1**sep+*
        MAPPING="{'not_entailment':'No','entailment':'Yes'}"
        ;;
    RTE)
        TEMPLATE=*cls**sent-_0*?*mask*,*+sentl_1**sep+*
        MAPPING="{'not_entailment':'No','entailment':'Yes'}"
        TASK_EXTRA="--max_seq_len 256 --first_sent_limit 240"
        ;;
    mr)
        TEMPLATE=*cls**sent_0*_It_was*mask*.*sep+*
        MAPPING="{0:'terrible',1:'great'}"
        TASK_EXTRA="--first_sent_limit 110 --second_sent_limit 50 --double_demo"
        ;;
    sst-5)
        TEMPLATE=*cls**sent_0*_It_was*mask*.*sep+*
        MAPPING="{0:'terrible',1:'bad',2:'okay',3:'good',4:'great'}"
        TASK_EXTRA="--first_sent_limit 110 --second_sent_limit 20 --double_demo"
        ;;
    subj)
        TEMPLATE=*cls**sent_0*_This_is*mask*.*sep+*
        MAPPING="{0:'subjective',1:'objective'}"
        TASK_EXTRA="--first_sent_limit 110 --second_sent_limit 50 --double_demo"
        ;;
    trec)
        TEMPLATE="*cls**mask*:*+sent_0**sep+*"
        MAPPING="{0:'Description',1:'Entity',2:'Expression',3:'Human',4:'Location',5:'Number'}"
        TASK_EXTRA="--first_sent_limit 110 --double_demo"
        ;;
    cr)
        TEMPLATE=*cls**sent_0*_It_was*mask*.*sep+*
        MAPPING="{0:'terrible',1:'great'}"
        TASK_EXTRA="--first_sent_limit 110 --second_sent_limit 50 --double_demo"
        ;;
    mpqa)
        TEMPLATE=*cls**sent_0*_It_was*mask*.*sep+*
        MAPPING="{0:'terrible',1:'great'}"
        TASK_EXTRA="--first_sent_limit 110  --double_demo"
        ;;

esac

# Gradient accumulation steps
# For medium-sized GPUs (e.g., 2080ti with 10GB memory), they can only take
# a maximum batch size of 2 when using large-size models. So we use gradient
# accumulation steps to achieve the same effect of larger batch sizes.
REAL_BS=4

# Use a random number to distinguish different trails (avoid accidental overwriting)
TRIAL_IDTF=$RANDOM

SEED=1 # 1 / 2 / 3 / 4 / 5

export CUDA_VISIBLE_DEVICES=${GPU}
echo "${GPU}"

echo "$SEED $MODEL $mode"
DATA_DIR=./data/glue/$TASK/$K-$SEED

python src/run.py \
    --task_name $TASK \
    --data_dir $DATA_DIR \
    --overwrite_output_dir \
    --do_train \
    --output_dir result/glue-$TASK-$TYPE-$K-$SEED-$MODEL-$TRIAL_IDTF \
    --overwrite_cache \
    --do_eval 1 \
    --do_predict \
    --model_name_or_path $MODEL \
    --few_shot_type ${TYPE} \
    --num_k $K \
    --max_seq_length 64 \
    --per_device_train_batch_size $BS \
    --per_device_eval_batch_size 16 \
    --learning_rate $LR \
    --logging_steps $EVAL_STEP \
    --eval_steps $EVAL_STEP \
    --num_train_epochs  10000 \
    --seed $SEED \
    --soft_label 1 \
    --is_semi 1 \
    --un_train_batch_size 16 \
    --self_training_start_iter 400 \
    --meta_train_batch_size 4 \
    --update_teacher_steps 1000 \
    --finetune_teacher_epoch 50 \
    --self_training_session 6 \
    --adapter_dim 128 \
    --semi_finetune \
    --re_init \
    --use_last_epoch \
    --use_clue


# Delete the checkpoint 
# Since we need to run multiple trials, saving all the checkpoints takes 
# a lot of storage space. You can find all evaluation results in `log` file anyway.
#rm -r result/$TASK-$TYPE-$K-$SEED-$MODEL-$TRIAL_IDTF \

