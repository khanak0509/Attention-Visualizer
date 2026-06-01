import numpy as np
import torch

from models import device, model, tokenizer


def get_attention_data(sentence: str):
    encoded = tokenizer(sentence, return_tensors="pt", add_special_tokens=True)
    input_ids = encoded["input_ids"].to(device)
    attention_mask = encoded["attention_mask"].to(device)
    tokens = tokenizer.convert_ids_to_tokens(input_ids[0].tolist())

    with torch.no_grad():
        outputs = model(
            input_ids=input_ids,
            attention_mask=attention_mask,
            output_attentions=True,
            output_hidden_states=True,
        )

    attention = torch.stack(outputs.attentions, dim=0).squeeze(1).cpu().numpy()
    hidden_states = torch.stack(outputs.hidden_states, dim=0).squeeze(1).cpu().numpy()
    return tokens, attention, hidden_states


def compute_head_entropy(attn_matrix):
    eps = 1e-9
    entropy_per_row = -np.sum(attn_matrix * np.log(attn_matrix + eps), axis=-1)
    max_entropy = np.log(attn_matrix.shape[-1])
    return float(np.mean(entropy_per_row / max_entropy))


def compute_vertical_score(attn_matrix):
    cls_col = float(np.mean(attn_matrix[:, 0]))
    sep_col = float(np.mean(attn_matrix[:, -1]))
    return max(cls_col, sep_col)


def compute_diagonal_score(attn_matrix):
    scores = []
    for offset in (-1, 0, 1):
        diag = np.diagonal(attn_matrix, offset=offset)
        scores.append(float(np.mean(diag)))
    return max(scores)


def classify_head(attn_matrix, entropy_threshold=0.75, vertical_threshold=0.4, diagonal_threshold=0.4):
    entropy = compute_head_entropy(attn_matrix)
    vertical = compute_vertical_score(attn_matrix)
    diagonal = compute_diagonal_score(attn_matrix)

    if entropy > entropy_threshold:
        label = "broad"
    elif vertical > vertical_threshold:
        label = "vertical"
    elif diagonal > diagonal_threshold:
        label = "positional"
    else:
        label = "focused"

    return label, entropy, vertical, diagonal


def analyze_all_heads(attention):
    records = []
    for layer in range(attention.shape[0]):
        for head in range(attention.shape[1]):
            label, entropy, vertical, diagonal = classify_head(attention[layer, head])
            records.append(
                {
                    "layer": layer + 1,
                    "head": head + 1,
                    "type": label,
                    "entropy": round(entropy, 3),
                    "vertical_score": round(vertical, 3),
                    "diagonal_score": round(diagonal, 3),
                }
            )
    return records


def compute_attention_rollout(attention, head_fusion="mean"):
    n_layers, _, seq_len, _ = attention.shape
    identity = np.eye(seq_len)
    rollout = identity.copy()

    for layer in range(n_layers):
        if head_fusion == "mean":
            fused = np.mean(attention[layer], axis=0)
        elif head_fusion == "max":
            fused = np.max(attention[layer], axis=0)
        else:
            raise ValueError("head_fusion must be 'mean' or 'max'")

        fused = fused + identity
        fused = fused / fused.sum(axis=-1, keepdims=True)
        rollout = fused @ rollout

    return rollout


def taxonomy_summary(records):
    counts = {"broad": 0, "vertical": 0, "positional": 0, "focused": 0}
    for row in records:
        counts[row["type"]] += 1

    most_focused = min(records, key=lambda r: r["entropy"])
    most_diffuse = max(records, key=lambda r: r["entropy"])
    return counts, most_focused, most_diffuse


def rollout_summary(tokens, rollout):
    cls_row = rollout[0] / rollout[0].sum()
    if len(tokens) <= 2:
        top_idx = 0
    else:
        inner = cls_row[1:-1]
        top_idx = int(inner.argmax()) + 1
    return cls_row.tolist(), top_idx
