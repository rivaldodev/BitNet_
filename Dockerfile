FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    clang \
    cmake \
    git \
    ninja-build \
    python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

RUN python3 /app/utils/apply_local_patches.py

RUN cp preset_kernels/bitnet_b1_58-large/bitnet-lut-kernels-tl2.h include/bitnet-lut-kernels.h && \
    cp preset_kernels/bitnet_b1_58-large/kernel_config_tl2.ini include/kernel_config.ini

RUN cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DBUILD_SHARED_LIBS=OFF \
    -DLLAMA_BUILD_SERVER=ON \
    && cmake --build build --config Release --target llama-server -j2

FROM ubuntu:24.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/build/bin/llama-server /app/llama-server

RUN python3 -m pip install --break-system-packages --no-cache-dir huggingface_hub

ENV LLAMA_ARG_HOST=0.0.0.0
ENV LLAMA_ARG_PORT=8080
ENV LLAMA_ARG_ALIAS=bitnet
ENV LLAMA_ARG_CTX_SIZE=2048
ENV LLAMA_ARG_THREADS=2
ENV LLAMA_ARG_N_GPU_LAYERS=0
ENV LLAMA_ARG_CONT_BATCHING=1
ENV MODEL_DIR=/models/bitnet
ENV MODEL_FILE=ggml-model-i2_s.gguf
ENV HF_REPO=microsoft/BitNet-b1.58-2B-4T-gguf

EXPOSE 8080

COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["/app/llama-server"]
