import numpy as np
import spacy
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score
from sklearn.preprocessing import LabelEncoder

from analysis import get_attention_data

PROBE_SENTENCES = [
    "The cat sat on the mat near the window.",
    "John said that he was really tired after the long meeting.",
    "The company released its quarterly earnings report yesterday.",
    "Scientists discovered a new species of bird in the Amazon rainforest.",
    "The government announced new policies to address climate change.",
    "She quickly ran to catch the last train to the city center.",
    "The old library contains thousands of rare and valuable books.",
    "His ambitious plan to reform the education system failed completely.",
    "The young engineer designed an innovative solution to the problem.",
    "After years of research, the team finally published their findings.",
]

POS_TAGS = [
    "ADJ", "ADP", "ADV", "AUX", "CCONJ", "DET", "NOUN",
    "PART", "PRON", "PROPN", "PUNCT", "SCONJ", "VERB",
]

_nlp = None


def _get_nlp():
    global _nlp
    if _nlp is None:
        _nlp = spacy.load("en_core_web_sm")
    return _nlp


def get_bert_pos_alignment(sentence, tokens):
    doc = _get_nlp()(sentence)
    spacy_tokens = [(t.text, t.pos_) for t in doc]
    pos_labels = [None]
    spacy_idx = 0

    for bert_tok in tokens[1:-1]:
        if bert_tok.startswith("##"):
            pos_labels.append(spacy_tokens[spacy_idx - 1][1] if spacy_idx > 0 else "X")
        else:
            if spacy_idx < len(spacy_tokens):
                pos_labels.append(spacy_tokens[spacy_idx][1])
                spacy_idx += 1
            else:
                pos_labels.append("X")

    pos_labels.append(None)
    return pos_labels


def probe_all_heads(sentences):
    tokens_list = []
    attention_list = []

    for sentence in sentences:
        tokens, attention, _ = get_attention_data(sentence)
        tokens_list.append(tokens)
        attention_list.append(attention)

    max_seq_len = max(a.shape[2] for a in attention_list)
    all_features = {(layer, head): [] for layer in range(12) for head in range(12)}
    all_labels = []

    for sentence, tokens, attention in zip(sentences, tokens_list, attention_list):
        pos_labels = get_bert_pos_alignment(sentence, tokens)
        seq_len = attention.shape[2]

        for i, pos in enumerate(pos_labels):
            if pos is None:
                continue
            all_labels.append(pos)
            for layer in range(12):
                for head in range(12):
                    row = attention[layer, head, i, :]
                    padded = np.zeros(max_seq_len)
                    padded[:seq_len] = row
                    all_features[(layer, head)].append(padded)

    le = LabelEncoder()
    y = le.fit_transform(all_labels)
    grid = [[0.0 for _ in range(12)] for _ in range(12)]

    for layer in range(12):
        for head in range(12):
            x = np.array(all_features[(layer, head)])
            if len(x) < 10:
                continue
            clf = LogisticRegression(max_iter=500, random_state=42, C=1.0)
            clf.fit(x, y)
            grid[layer][head] = round(float(accuracy_score(y, clf.predict(x))), 3)

    best_layer, best_head = 0, 0
    best_acc = 0.0
    for layer in range(12):
        for head in range(12):
            if grid[layer][head] > best_acc:
                best_acc = grid[layer][head]
                best_layer, best_head = layer, head

    layer_max = [max(grid[layer]) for layer in range(12)]
    random_baseline = round(1.0 / len(le.classes_), 3)

    return {
        "grid": grid,
        "best": {"layer": best_layer + 1, "head": best_head + 1, "accuracy": best_acc},
        "layer_max": layer_max,
        "pos_classes": list(le.classes_),
        "token_count": len(all_labels),
        "random_baseline": random_baseline,
    }


def run_probing(user_sentence):
    sentences = [user_sentence] + [s for s in PROBE_SENTENCES if s != user_sentence]
    return probe_all_heads(sentences)
