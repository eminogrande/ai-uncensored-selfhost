#!/bin/bash
# swap_model.sh — switch which uncensored model llama-server serves on :8080
# usage: swap_model.sh {obl|hui|r1}
set -euo pipefail

MODEL="${1:-}"
case "$MODEL" in
  obl) GGUF=/root/models/Qwen3.8-27B-OBLITERATED-Q4_K_M.gguf ;;
  hui) GGUF=/root/models/Huihui-Qwen3.8-27B-abliterated-Q4_K.gguf ;;
  r1)  GGUF=/root/models/DeepSeek-R1-Distill-Qwen-32B-abliterated-Q4_K_M.gguf ;;
  *)   echo "usage: swap_model.sh {obl|hui|r1}" >&2; exit 1 ;;
esac

pkill -9 -f llama-server 2>/dev/null || true
sleep 2

nohup /root/llama.cpp/build/bin/llama-server \
  -m "$GGUF" -ngl 99 -c 65536 --host 0.0.0.0 --port 8080 \
  --temp 0 --repeat-penalty 1.15 >/root/server.log 2>&1 &

echo "swapped to: $GGUF"
echo "wait ~25s for load, then: curl http://127.0.0.1:8080/health"
