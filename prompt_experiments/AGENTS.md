## High-level intent
- This folder is dedicated to iterating on the prompt tuning layer for LastTime using Python + `apple_fm_sdk` (macOS only).
- Focus is solely on the conversational prompts, the locally stored dataset, and the evaluation harness; you do not need to wire the menubar UI or run Xcode to make Python changes.

## Prompt experimentation sources
- `prompt_experiments/generation_manager.py` mirrors the Swift `GenerationManager` heuristics (Swift sources live under `lasttime/Manager/GenerationManager.swift`); keep them aligned only if you expect to ship a prompt change into the macOS app.
- The Python manager exposes the same intent categories (`memory`, `query`, `invalid`) and can run with or without actual FoundationModel calls by toggling `use_heuristics_only` (default: heuristics only so evaluations are reproducible on non-macOS or when `apple_fm_sdk` is unavailable).

## Dataset & evaluation
- `prompt_experiments/dataset.json` is the shared dataset; every entry is `{"text": ..., "kind": ..., "canonical": ...}`. Keep the `kind` values limited to `memory`, `query`, or `invalid` so comparators stay simple.
- Regenerate the JSON via `python prompt_experiments/dataset_builder.py` after editing `build_entries()` or adding new samples because downstream scripts consume the static file.
- Run `python prompt_experiments/evaluate.py` to test the current prompts/heuristics against `dataset.json`; it reports counts, accuracy, and prints any mismatches the heuristics would have made.

## LM readiness
- Use `prompt_experiments/basic.py` to verify macOS machine has `apple_fm_sdk` available before routing experiments through the real model. The evaluation harness defaults to heuristics, so you can run `python prompt_experiments/evaluate.py --with-model` once the SDK is ready.
