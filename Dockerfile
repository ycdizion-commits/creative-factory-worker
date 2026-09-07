FROM runpod/worker-comfyui:5.10.0-base

ENV PIP_NO_INPUT=1
ENV PIP_PREFER_BINARY=1
ENV PYTHONUNBUFFERED=1

WORKDIR /comfyui/custom_nodes

RUN git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git && cd ComfyUI-WanVideoWrapper && git checkout 088128b224242e110d3906c6750e9a3a348a659b && rm -rf .git
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && cd ComfyUI-VideoHelperSuite && git checkout 4d907bee61e92c2e65af3bd6383a4e4d356126d1 && rm -rf .git
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git && cd ComfyUI-KJNodes && git checkout c9869eade9920a1b949de07c4a197156006bcceb && rm -rf .git
RUN git clone https://github.com/kijai/ComfyUI-DepthAnythingV2.git && cd ComfyUI-DepthAnythingV2 && git checkout 553187872eeb1d52e50dc53209fa57e569609a72 && rm -rf .git

RUN uv pip install --python /opt/venv/bin/python -r ComfyUI-WanVideoWrapper/requirements.txt
RUN uv pip install --python /opt/venv/bin/python -r ComfyUI-VideoHelperSuite/requirements.txt
RUN uv pip install --python /opt/venv/bin/python -r ComfyUI-KJNodes/requirements.txt
RUN uv pip install --python /opt/venv/bin/python -r ComfyUI-DepthAnythingV2/requirements.txt

COPY custom_nodes/cf_nodes /comfyui/custom_nodes/cf_nodes
COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml

RUN mkdir -p /comfyui/models/depthanything && wget -q -O /comfyui/models/depthanything/depth_anything_v2_vitl_fp16.safetensors https://huggingface.co/Kijai/DepthAnythingV2-safetensors/resolve/main/depth_anything_v2_vitl_fp16.safetensors

RUN cd /comfyui && timeout 600 python main.py --quick-test-for-ci --cpu

WORKDIR /
