#!/bin/bash
# uncensored-start.sh — re-provision the uncensored A100 from scratch.
# One command: rent A100 -> build llama.cpp (sm_80) -> download model -> serve.
# usage: ./uncensored-start.sh
set -euo pipefail

VAST=/tmp/vastai-venv/bin/vastai
SSH_KEY=~/.ssh/id_ed25519
MODEL_REPO=OBLITERATUS/Qwen3.8-27B-OBLITERATED
MODEL_FILE=Qwen3.8-27B-OBLITERATED-Q6_K.gguf

# 1. find an A100 40GB+ (or 80GB) offer
echo "==> searching A100 40GB+..."
OFFER=$("$VAST" search offers 'gpu_name=A100_PCIE gpu_ram>=40000 verified=true' -d -o 'dph_total' --raw 2>/dev/null \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['id'] if d else '')")
if [ -z "$OFFER" ]; then
  # try spot
  OFFER=$("$VAST" search offers 'gpu_name=A100_PCIE gpu_ram>=40000' -i -o 'dph_total' --raw 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['id'] if d else '')")
fi
[ -z "$OFFER" ] && { echo "no A100 available right now"; exit 1; }
echo "==> offer $OFFER"

# 2. rent
echo "==> renting..."
CONTRACT=$("$VAST" create instance "$OFFER" --image nvidia/cuda:12.4.0-devel-ubuntu22.04 --disk 120 --ssh --direct 2>/dev/null \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('new_contract',''))")
[ -z "$CONTRACT" ] && { echo "rent failed"; exit 1; }
echo "==> contract $CONTRACT"

# 3. wait for running
echo "==> waiting for running..."
for i in $(seq 1 60); do
  STATUS=$("$VAST" show instance "$CONTRACT" --raw 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('actual_status',''))")
  [ "$STATUS" = "running" ] && break
  sleep 15
done
[ "$STATUS" = "running" ] || { echo "timeout waiting for running (status: $STATUS)"; exit 1; }

# 4. get ssh details
INFO=$("$VAST" show instance "$CONTRACT" --raw 2>/dev/null)
IP=$(echo "$INFO" | python3 -c "import sys,json; print(json.load(sys.stdin)['public_ipaddr'])")
PORT=$(echo "$INFO" | python3 -c "import sys,json; print(json.load(sys.stdin)['direct_port_start'])")
echo "==> ssh: root@$IP:$PORT"

SSH="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i $SSH_KEY -p $PORT root@$IP"

# 5. build + download + serve
echo "==> build llama.cpp (sm_80)..."
$SSH "apt-get update -qq && apt-get install -y -qq git build-essential cmake python3-pip >/dev/null 2>&1 && pip3 install -q huggingface_hub && git clone --depth 1 https://github.com/ggml-org/llama.cpp.git >/dev/null 2>&1 && cd llama.cpp && cmake -B build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=80 -DCMAKE_BUILD_TYPE=Release >/dev/null 2>&1 && cmake --build build --config Release -j 16 >/dev/null 2>&1 && echo BUILD_OK"

echo "==> download model (21GB)..."
$SSH "mkdir -p /root/models && hf download $MODEL_REPO $MODEL_FILE --local-dir /root/models >/dev/null 2>&1 && echo DL_OK"

echo "==> serve (262k context)..."
$SSH "nohup /root/llama.cpp/build/bin/llama-server -m /root/models/$MODEL_FILE --jinja -c 262144 -ngl 99 --host 0.0.0.0 --port 8080 --temp 0.7 --top-p 0.8 --top-k 20 --presence-penalty 1.5 --reasoning off >/root/server.log 2>&1 &"
sleep 25
$SSH "curl -s http://127.0.0.1:8080/health"

echo ""
echo "==> DONE. Update the launchd tunnel to point at root@$IP:$PORT"
echo "    (edit ~/Library/LaunchAgents/com.emin.vast-tunnel.plist: -p $PORT, root@$IP, then:"
echo "     launchctl unload ~/Library/LaunchAgents/com.emin.vast-tunnel.plist && launchctl load ~/Library/LaunchAgents/com.emin.vast-tunnel.plist)"
