# AI Uncensored — self-hosted uncensored coding models

Run the best uncensored (0-refusal) coding models on a cheap cloud GPU and wire
them into Hermes as an OpenAI-compatible provider. Zero dependencies on hosted
APIs — the model and the box are yours.

## TL;DR

- **V100 (Volta, sm_70) = llama.cpp/GGUF only.** KTransformers requires sm_80+
  (Ampere); its kt-kernel explicitly marks Volta ❌. vLLM 0.20.0+ dropped sm_70.
  The "run KTransformers on a V100" idea does not work — llama.cpp built for
  sm_70 is the only practical serving path.
- Best runnable uncensored coder on a single V100: **Qwen3.8-27B OBLITERATED**
  (~30 tok/s, 64K context).
- Best runnable uncensored coder on a big-RAM box (128GB+ RAM, 75GB+ disk):
  **DeepSeek V4 Flash abliterated** (88.8% SWE-bench, 284B MoE / 13B active).
- Best uncensored coder, period: **GLM-5.3 UNCENSORED FP8** (dealignai, 95.4%
  SWE-bench) — 753B, needs 8×H200, not self-hostable on a budget.

## Models tested

Benchmarked on a V100-32GB, llama.cpp `b1-557614e`, full GPU offload (`-ngl 99`).

| Model | Type | Gen t/s | Prompt t/s |
|---|---|---|---|
| `OBLITERATUS/Qwen3.8-27B-OBLITERATED` Q4_K_M | uncensored coder | 30.6 | 725 |
| `huihui-ai/Huihui-Qwen3.8-27B-abliterated` Q4_K | uncensored | 30.3 | 715 |
| `bartowski/DeepSeek-R1-Distill-Qwen-32B-abliterated` Q4_K_M | reasoning | 27.2 | 645 |

Uncensored verified live: the OBLITERATED model answers restricted requests
(no refusals, no safety-lecture deflections).

## Hardware reality (why llama.cpp)

| GPU | Compute capability | KTransformers | vLLM 0.20+ | llama.cpp |
|---|---|---|---|---|
| V100 | 7.0 (Volta) | ❌ | ❌ dropped | ✅ (build for sm_70) |
| A100 | 8.0 (Ampere) | ✅ | ✅ | ✅ |
| H100 | 9.0 (Hopper) | ✅ | ✅ | ✅ |

## Setup

### 1. Rent a V100-32GB on vast.ai

```bash
python3.13 -m venv /tmp/vastai-venv && /tmp/vastai-venv/bin/pip install vastai

# find a 32GB V100
/tmp/vastai-venv/bin/vastai search offers 'gpu_name=Tesla_V100 gpu_ram>=32000' -o 'dph_total'

# rent — on-demand (--disk applies reliably on on-demand, unlike interruptible bids)
/tmp/vastai-venv/bin/vastai create instance <OFFER_ID> \
  --image nvidia/cuda:12.4.0-devel-ubuntu22.04 --disk 80 --ssh --direct

# wait for 'running', then grab ssh host/port/direct_port_start
/tmp/vastai-venv/bin/vastai show instance <CONTRACT_ID>
```

### 2. Build llama.cpp for sm_70

```bash
ssh -p <PORT> -i ~/.ssh/id_ed25519 root@<HOST> 'bash -s' <<'EOF'
apt-get update -qq && apt-get install -y -qq git build-essential cmake
git clone --depth 1 https://github.com/ggml-org/llama.cpp.git
cd llama.cpp
cmake -B build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=70 -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j 8
EOF
```

### 3. Download + serve

```bash
ssh -p <PORT> -i ~/.ssh/id_ed25519 root@<HOST> 'bash -s' <<'EOF'
pip3 install -q huggingface_hub
hf download OBLITERATUS/Qwen3.8-27B-OBLITERATED \
  Qwen3.8-27B-OBLITERATED-Q4_K_M.gguf --local-dir /root/models
EOF

# serve — OpenAI-compatible on :8080
/root/llama.cpp/build/bin/llama-server \
  -m /root/models/Qwen3.8-27B-OBLITERATED-Q4_K_M.gguf \
  -ngl 99 -c 65536 --host 0.0.0.0 --port 8080 --temp 0 --repeat-penalty 1.15
```

### 4. Wire into Hermes

```bash
# tunnel (keep alive in a separate terminal)
ssh -p <PORT> -i ~/.ssh/id_ed25519 -L 8080:127.0.0.1:8080 root@<HOST> -N

# register the provider (CLI only — never hand-edit config.yaml)
hermes config set providers.v100-local '{
  "name":"V100 Uncensored (vast.ai)",
  "api":"http://127.0.0.1:8080/v1",
  "transport":"chat_completions",
  "default_model":"qwen3.8-27b-obl",
  "context_length":65536,
  "models":{
    "qwen3.8-27b-obl":{"context_length":65536},
    "huihui-qwen38-27b":{"context_length":65536},
    "deepseek-r1-32b-abl":{"context_length":65536}
  }
}'

# test
hermes chat -q "reply with exactly: OK" --provider v100-local -m qwen3.8-27b-obl -Q
```

> Hermes enforces a 64K minimum context — the server must run `-c >= 65536`.

## Swap models

`scripts/swap_model.sh` restarts llama-server with a different GGUF
(`obl` / `hui` / `r1`). Only one 27B+ model fits in 32GB VRAM at a time.

```bash
ssh -p <PORT> -i ~/.ssh/id_ed25519 root@<HOST> /root/swap_model.sh obl
```

## Uncensored maker landscape

| Maker | Technique | Capability vs base |
|---|---|---|
| huihui-ai | abliteration (SVD on refusal directions) | some loss |
| OBLITERATUS (elder-plinius) | SVD + LEACE complementary blend, iterative | −2.1pp MMLU |
| dealignai | residual-writer tensor edit ("CRACK"), FP8 experts untouched | **+1.85pp MMLU** |

dealignai's method is the most interesting: it *improves* capability while
removing refusals, and loads in stock vLLM. Watch for a ≤35B dealignai release —
that would be the best runnable uncensored coder.

## Cost reference (vast.ai, live Aug 2026)

| Card | Spot $/hr | On-demand $/hr | Notes |
|---|---|---|---|
| V100 32GB | ~0.12 | ~0.16 | sm_70, llama.cpp only |
| A100 PCIe 80GB | ~0.13 | ~0.43 | sm_80, unlocks vLLM/KTransformers |
| RTX 4090 24GB | ~0.07 | ~0.32 | cheapest fast consumer card |

Spot = interruptible (can be reclaimed mid-inference). On-demand `--disk` sizing
is reliable; interruptible bids sometimes ignore `--disk` (observed on vast.ai).

## License

MIT. Models carry their own licenses (Qwen Apache-2.0, DeepSeek MIT); abliterated
derivatives inherit the base license. You are responsible for how you use them.
