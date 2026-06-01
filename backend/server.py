import threading

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from ablation import load_eval_data, predict_single, run_ablation_study
from analysis import (
    analyze_all_heads,
    compute_attention_rollout,
    get_attention_data,
    rollout_summary,
    taxonomy_summary,
)
from probing import POS_TAGS, run_probing

app = FastAPI(title="LLM Attention Visualizer API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

_ablation_cache = {
    "ready": False,
    "data": None,
    "loading": False,
    "progress": 0,
    "eval_size": 200,
    "error": None,
}

# 872 = full SST-2 val (hours on CPU). 200 = fast local default.
ABLATION_EVAL_LIMIT = 872


class AnalyzeRequest(BaseModel):
    sentence: str = Field(min_length=1)


class AblationPredictRequest(BaseModel):
    sentence: str = Field(min_length=1)
    layer: int | None = Field(default=None, ge=0, le=11)
    head: int | None = Field(default=None, ge=0, le=11)


def _ensure_ablation():
    if _ablation_cache["ready"] or _ablation_cache["loading"]:
        return

    _ablation_cache["loading"] = True

    def _load():
        _ablation_cache["error"] = None
        _ablation_cache["progress"] = 0
        try:
            eval_data = load_eval_data(limit=ABLATION_EVAL_LIMIT)
            _ablation_cache["eval_size"] = len(eval_data)

            def on_layer_done(layer_idx):
                _ablation_cache["progress"] = layer_idx + 1

            _ablation_cache["data"] = run_ablation_study(
                eval_data, on_layer_done=on_layer_done
            )
            _ablation_cache["ready"] = True
        except Exception as exc:
            _ablation_cache["error"] = str(exc)
        finally:
            _ablation_cache["loading"] = False

    threading.Thread(target=_load, daemon=True).start()


@app.on_event("startup")
def startup():
    _ensure_ablation()


@app.get("/health")
def health():
    return {
        "status": "ok",
        "ablation_ready": _ablation_cache["ready"],
        "ablation_loading": _ablation_cache["loading"],
        "ablation_progress": _ablation_cache["progress"],
        "ablation_eval_size": _ablation_cache["eval_size"],
        "ablation_error": _ablation_cache["error"],
    }


@app.post("/analyze")
def analyze(req: AnalyzeRequest):
    sentence = req.sentence.strip()
    tokens, attention, _ = get_attention_data(sentence)
    taxonomy = analyze_all_heads(attention)
    counts, most_focused, most_diffuse = taxonomy_summary(taxonomy)
    rollout = compute_attention_rollout(attention)
    cls_influence, top_token_idx = rollout_summary(tokens, rollout)
    probing = run_probing(sentence)

    ablation = _ablation_cache["data"] if _ablation_cache["ready"] else None
    if ablation is None:
        _ensure_ablation()

    return {
        "sentence": sentence,
        "tokens": tokens,
        "attention": attention.tolist(),
        "taxonomy": taxonomy,
        "taxonomy_counts": counts,
        "most_focused": most_focused,
        "most_diffuse": most_diffuse,
        "rollout": rollout.tolist(),
        "rollout_cls": cls_influence,
        "top_cls_token": tokens[top_token_idx] if tokens else "",
        "top_cls_index": top_token_idx,
        "probing_grid": probing["grid"],
        "probing_best": probing["best"],
        "probing_layer_max": probing["layer_max"],
        "probing_pos_classes": probing["pos_classes"],
        "probing_token_count": probing["token_count"],
        "probing_random_baseline": probing["random_baseline"],
        "pos_tags": POS_TAGS,
        "ablation": ablation,
        "ablation_loading": _ablation_cache["loading"] and not _ablation_cache["ready"],
        "ablation_progress": _ablation_cache["progress"],
        "ablation_eval_size": _ablation_cache["eval_size"],
        "ablation_error": _ablation_cache["error"],
    }


@app.get("/ablation")
def get_ablation():
    if not _ablation_cache["ready"]:
        _ensure_ablation()
        return {
            "ready": False,
            "loading": _ablation_cache["loading"],
            "progress": _ablation_cache["progress"],
            "eval_size": _ablation_cache["eval_size"],
            "error": _ablation_cache["error"],
        }
    return {"ready": True, **_ablation_cache["data"]}


@app.post("/ablation/predict")
def ablation_predict(req: AblationPredictRequest):
    from models import clf_model

    baseline = predict_single(clf_model, req.sentence)
    ablated = None
    if req.layer is not None and req.head is not None:
        ablated = predict_single(clf_model, req.sentence, req.layer, req.head)

    return {
        "sentence": req.sentence,
        "baseline": baseline,
        "ablated": ablated,
        "ablated_layer": req.layer,
        "ablated_head": req.head,
    }
