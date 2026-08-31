#!/bin/bash
# swap_model.sh — switch which uncensored model llama-server serves on :8080
# usage: swap_model.sh {obl|hui|r1}
set -euo pipefail

MODEL="${1:-}"
CTX=131072
case "$MODEL" in
  obl) GGUF=/root/models/Qwen3.8-27B-OBLITERATED-Q6_K.gguf ;;
  hui) GGUF=/root/models/Huihui-Qwen3.8-27B-abliterated-Q4_K.gguf ;;
  r1)  GGUF=/root/models/DeepSeek-R1-Distill-Qwen-32B-abliterated-Q4_K_M.gguf; CTX=8192 ;;
  *)   echo "usage: swap_model.sh {obl|hui|r1}" >&2; exit 1 ;;
esac

pkill -9 -f llama-server 2>/dev/null || true
sleep 2

# REQUIRED for Qwen3.8 GGUFs: --jinja (baked template) + --reasoning off (kill the think-loop).
# temp 0.7 (NOT greedy 0) avoids degeneration; Q4_K_M can still loop — prefer Q6_K.
nohup /root/llama.cpp/build/bin/llama-server \
  -m "$GGUF" --jinja -c $CTX -ngl 99 --host 0.0.0.0 --port 8080 \
  --temp 0.7 --top-p 0.8 --top-k 20 --presence-penalty 1.5 --reasoning off >/root/server.log 2>&1 &

echo "swapped to: $GGUF (ctx $CTX)"
echo "wait ~25s, then: curl http://127.0.0.1:8080/health"
