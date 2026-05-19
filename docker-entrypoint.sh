#!/usr/bin/env sh
set -eu

MODEL_PATH="${MODEL_DIR}/${MODEL_FILE}"

mkdir -p "${MODEL_DIR}"

if [ ! -f "${MODEL_PATH}" ] || [ ! -s "${MODEL_PATH}" ]; then
    echo "Downloading model to ${MODEL_PATH}"
    python3 - <<'PY'
import os
from huggingface_hub import hf_hub_download

repo_id = os.environ["HF_REPO"]
model_dir = os.environ["MODEL_DIR"]
model_file = os.environ["MODEL_FILE"]

path = hf_hub_download(
    repo_id=repo_id,
    filename=model_file,
    local_dir=model_dir,
    local_dir_use_symlinks=False,
)
print(path)
PY
fi

export LLAMA_ARG_MODEL="${MODEL_PATH}"
exec "$@"
