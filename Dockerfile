# creative-factory-worker: Runpod serverless ComfyUI worker for Wan 2.2 / VACE / Z-Image
# Base: official worker-comfyui (handler + ComfyUI + comfy-cli). Models live on the network volume.
FROM runpod/worker-comfyui:5.10.0-base

ENV PIP_NO_INPUT=1 PIP_PREFER_BINARY=1 PYTHONUNBUFFERED=1
ARG VENV_PY=/opt/venv/bin/python

# --- custom nodes (pinned commits, 2026-09-07) ---------------------------------
WORKDIR /comfyui/custom_nodes
RUN git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git \
 && git -C ComfyUI-WanVideoWrapper checkout 088128b224242e110d3906c6750e9a3a348a659b \
 && git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git \
 && git -C ComfyUI-VideoHelperSuite checkout 4d907bee61e92c2e65af3bd6383a4e4d356126d1 \
 && git clone https://github.com/kijai/ComfyUI-KJNodes.git \
 && git -C ComfyUI-KJNodes checkout c9869eade9920a1b949de07c4a197156006bcceb \
 && git clone https://github.com/kijai/ComfyUI-DepthAnythingV2.git \
 && git -C ComfyUI-DepthAnythingV2 checkout 553187872eeb1d52e50dc53209fa57e569609a72 \
 && for d in ComfyUI-WanVideoWrapper ComfyUI-VideoHelperSuite ComfyUI-KJNodes ComfyUI-DepthAnythingV2; do \
      if [ -f "$d/requirements.txt" ]; then uv pip install --python ${VENV_PY} -r "$d/requirements.txt"; fi; \
    done \
 && rm -rf /comfyui/custom_nodes/*/.git

# --- tiny in-repo node: encode IMAGE batch -> mp4 and report it under "images" so the
#     stock worker-comfyui handler returns the video as base64 -----------------------
COPY custom_nodes/cf_nodes /comfyui/custom_nodes/cf_nodes

# --- network volume model paths (adds diffusion_models/text_encoders/loras/...) ------
COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml

# --- depth estimator baked into the image (small, avoids cold-start download) ----------
RUN mkdir -p /comfyui/models/depthanything \
 && wget -q -O /comfyui/models/depthanything/depth_anything_v2_vitl_fp16.safetensors \
    https://huggingface.co/Kijai/DepthAnythingV2-safetensors/resolve/main/depth_anything_v2_vitl_fp16.safetensors

# --- build-time smoke test: import every custom node on CPU --------------------------
RUN cd /comfyui && timeout 600 python main.py --quick-test-for-ci --cpu

WORKDIR /
CMD ["/start.sh"]
