from transformers import BertForSequenceClassification, BertModel, BertTokenizer

from device_utils import get_device

MODEL_NAME = "bert-base-uncased"
CLF_MODEL_NAME = "textattack/bert-base-uncased-SST-2"

device = get_device()
tokenizer = BertTokenizer.from_pretrained(MODEL_NAME)
model = BertModel.from_pretrained(MODEL_NAME, output_attentions=True)
model.eval()
model.to(device)

clf_model = BertForSequenceClassification.from_pretrained(CLF_MODEL_NAME)
clf_model.eval()
clf_model.to(device)
