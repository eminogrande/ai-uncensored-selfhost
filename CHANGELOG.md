# Changelog

Newest first. Every entry names the commit SHA it describes.

## 2026-10-14 — [RELEASE] v0.1.0 — hermes-agent for emino

First tagged release. State of `main` at `c0b7b601`:

- Guide for running abliterated 0-refusal coding models on vast.ai GPUs with llama.cpp, wired into Hermes as an OpenAI-compatible provider.
- `scripts/swap_model.sh` serves one of three GGUFs (`obl`, `hui`, `r1`) on :8080 with `--jinja` and `--reasoning off`.
- `scripts/uncensored-start.sh` / `uncensored-stop.sh` start and stop the vast.ai instance and keep the disk.
- GitHub Pages dashboard in `docs/` reads `docs/status.json`. Last recorded live model: Qwen3.8-27B OBLITERATED V3 Q6_K on A100-PCIE-40GB, 262144 context.
- Docs pass (this PR): README with Logs, Status, Architecture, User flow, Components, Endpoints, Run; CHANGELOG; PROMPTLOG. No code changed.

## 2026-08-31

- `c0b7b601` Start/stop scripts now stop and start the existing instance instead of destroying and re-provisioning it. Models and llama.cpp build survive a stop.
- `3a739003` Added one-command `uncensored-start.sh` and `uncensored-stop.sh` for the box.
- `f64ee07d` Moved the box from V100-32GB to A100-PCIE-40GB. Status now shows 262144 context, 33 gen tok/s, 1106 prompt tok/s.
- `4809aa81` Context raised to 131072 in `swap_model.sh`, the max for Q6_K on a 32GB V100 (262k ran out of memory).
- `b180344e` OBLITERATUS V3 Q6_K became the live 0-refusal model (6/6 probes, no degeneration).
- `a923e4d0` Huihui set as 0-refusal security model; `--jinja` plus `--reasoning off` made required to stop the Qwen3.8 think loop.
- `c1c13c3a` Live model switched to Huihui because OBLITERATUS V3 degenerated on some prompts.
- `79ef506e` Added `--reasoning off` so streaming no longer hangs in a Qwen3.8 thinking loop; README documents why.
- `9a84d5ed` Added GitHub Pages status dashboard (`docs/index.html`, `docs/status.json`): live model, query example, access note.
- `6385a619` Initial guide: self-hosted uncensored coding models on a vast.ai V100 with llama.cpp and Hermes wiring, plus `swap_model.sh`.
