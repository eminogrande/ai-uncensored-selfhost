#!/bin/bash
# swap_model.sh — switch which uncensored model llama-server serves on :8080
# usage: swap_model.sh {hui|r1}
set -euo pipefail

MODEL="${1:-}"
case "$MODEL" in
  hui) GGUF=/root/models/Huihui-Qwen3.8-27B-abliterated-Q4_K.gguf ;;
  r1)  GGUF=/root/models/DeepSeek-R1-Distill-Qwen-32B-abliterated-Q4_K_M.gguf ;;
  *)   echo "usage: swap_model.sh {hui|r1}" >&2; exit 1 ;;
esac

pkill -9 -f llama-server 2>/dev/null || true
sleep 2

# --jinja (baked template) + --reasoning off (kill the Qwen3.8 think-loop) are REQUIRED.
# temp 0 is fine for Huihui; if a model degenerates ("/" loop), raise to 0.7.
nohup /root/llama.cpp/build/bin/llama-server \
  -m "$GGUF" --jinja -c 65536 -ngl 99 --host 0.0.0.0 --port 8080 \
  --temp 0 --repeat-penalty 1.15 --reasoning off >/root/server.log 2>&1 &

echo "swapped to: $GGUF"
echo "wait ~25s, then: curl http://127.0.0.1:8080/health"
