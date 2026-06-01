import numpy as np
import torch
from datasets import load_dataset
from models import clf_model, device, tokenizer


def predict_single(model, sentence, ablate_layer=None, ablate_head=None):
    inputs = tokenizer(sentence, return_tensors="pt", truncation=True, max_length=128)
    inputs = {k: v.to(device) for k, v in inputs.items()}
    handle = None

    if ablate_layer is not None and ablate_head is not None:
        handle = _ablate_head(model, ablate_layer, ablate_head)

    try:
        with torch.no_grad():
            logits = model(**inputs).logits
            probs = torch.softmax(logits, dim=-1).cpu().numpy()[0]
            pred = int(logits.argmax(dim=-1).item())
    finally:
        if handle is not None:
            handle.remove()

    labels = ["negative", "positive"]
    return {
        "label": pred,
        "label_name": labels[pred],
        "confidence": float(probs[pred]),
        "probabilities": {"negative": float(probs[0]), "positive": float(probs[1])},
    }


def predict_batch(model, data):
    correct = 0
    for sentence, true_label in data:
        inputs = tokenizer(sentence, return_tensors="pt", truncation=True, max_length=128)
        inputs = {k: v.to(device) for k, v in inputs.items()}
        with torch.no_grad():
            pred = model(**inputs).logits.argmax(dim=-1).item()
        correct += int(pred == true_label)
    return correct / len(data)


def _ablate_head(model, layer_idx, head_idx):
    head_size = model.config.hidden_size // model.config.num_attention_heads
    start = head_idx * head_size
    end = start + head_size
    attn_module = model.bert.encoder.layer[layer_idx].attention.self

    def hook_fn(module, input, output):
        output[0][:, :, start:end] = 0.0
        return output

    return attn_module.register_forward_hook(hook_fn)


def run_layerwise_ablation(data, baseline, n_layers=12, n_heads=12):
    """Remove all heads in one layer at a time — stronger signal than single heads."""
    layer_wise = []
    for layer in range(n_layers):
        handles = [_ablate_head(clf_model, layer, h) for h in range(n_heads)]
        ablated = predict_batch(clf_model, data)
        for handle in handles:
            handle.remove()
        layer_wise.append(round(float(baseline - ablated), 4))
    return layer_wise


def run_ablation_study(data, n_layers=12, n_heads=12, on_layer_done=None):
    baseline = predict_batch(clf_model, data)
    importance = np.zeros((n_layers, n_heads))

    for layer in range(n_layers):
        for head in range(n_heads):
            handle = _ablate_head(clf_model, layer, head)
            ablated = predict_batch(clf_model, data)
            handle.remove()
            importance[layer, head] = baseline - ablated

        if on_layer_done is not None:
            on_layer_done(layer)

    head_max_per_layer = importance.max(axis=1).tolist()
    layer_wise_drops = run_layerwise_ablation(data, baseline, n_layers, n_heads)
    best_layer, best_head = np.unravel_index(importance.argmax(), importance.shape)
    threshold = 0.01
    mean_drop = float(importance.mean())
    std_drop = float(importance.std())
    absolute_critical = int(np.sum(importance > threshold))
    relative_critical = int(np.sum(importance > mean_drop + std_drop))
    notable = int(np.sum(importance > mean_drop + 0.5 * std_drop))

    flat = importance.flatten()
    top10_idx = np.argsort(flat)[::-1][:10]
    top_heads = []
    for idx in top10_idx:
        l, h = divmod(int(idx), n_heads)
        drop = float(importance[l, h])
        sigma = (drop - mean_drop) / std_drop if std_drop > 0 else 0.0
        top_heads.append(
            {
                "layer": l + 1,
                "head": h + 1,
                "drop": round(drop, 4),
                "sigma": round(float(sigma), 1),
            }
        )

    return {
        "baseline": round(float(baseline), 4),
        "importance": importance.round(4).tolist(),
        "layer_wise_drops": layer_wise_drops,
        "head_max_per_layer": [round(v, 4) for v in head_max_per_layer],
        "layer_drops": layer_wise_drops,
        "most_critical": {
            "layer": int(best_layer + 1),
            "head": int(best_head + 1),
            "drop": round(float(importance[best_layer, best_head]), 4),
            "sigma": round(
                float(
                    (importance[best_layer, best_head] - mean_drop) / std_drop
                    if std_drop > 0
                    else 0.0
                ),
                1,
            ),
        },
        "mean_drop": round(mean_drop, 4),
        "std_drop": round(std_drop, 4),
        "absolute_critical": absolute_critical,
        "relative_critical": relative_critical,
        "notable_heads": notable,
        "relative_threshold_1sigma": round(mean_drop + std_drop, 4),
        "relative_threshold_notable": round(mean_drop + 0.5 * std_drop, 4),
        "top_heads": top_heads,
        "eval_size": len(data),
        "critical_heads": absolute_critical,
        "redundant_heads": int(importance.size - absolute_critical),
    }


def load_eval_data(limit=200):
    sst2 = load_dataset("nyu-mll/glue", "sst2", split="validation")
    return [(ex["sentence"], ex["label"]) for ex in sst2.select(range(limit))]
