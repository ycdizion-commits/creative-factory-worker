# creative-factory-worker

Runpod serverless ComfyUI worker (image `runpod/worker-comfyui:5.10.0-base`) with:

- ComfyUI-WanVideoWrapper, ComfyUI-VideoHelperSuite, ComfyUI-KJNodes, ComfyUI-DepthAnythingV2 (pinned commits)
- `CFSaveVideo` node: encodes frames to mp4 and returns it through the stock handler's `output.images`
- Models are NOT baked in. They live on the `cf-models` network volume (`/runpod-volume/models/...`),
  see `models/manifest.txt` and `scripts/download_models.sh`.

Deploy with Runpod's GitHub integration (Dockerfile at repo root). Create a GitHub release to trigger a rebuild.
