"""creative-factory nodes: CFSaveVideo encodes an IMAGE batch to H.264 mp4 with ffmpeg and
reports the file under the "images" ui key, so worker-comfyui's stock handler returns it."""
import os
import subprocess

import numpy as np
import folder_paths


class CFSaveVideo:
    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "images": ("IMAGE",),
                "fps": ("FLOAT", {"default": 16.0, "min": 1.0, "max": 120.0, "step": 0.01}),
                "filename_prefix": ("STRING", {"default": "cf_video"}),
                "crf": ("INT", {"default": 18, "min": 0, "max": 51}),
            }
        }

    RETURN_TYPES = ()
    FUNCTION = "save"
    OUTPUT_NODE = True
    CATEGORY = "creative-factory"

    def save(self, images, fps, filename_prefix, crf):
        out_dir = folder_paths.get_output_directory()
        full_out, filename, counter, subfolder, _ = folder_paths.get_save_image_path(
            filename_prefix, out_dir, images.shape[2], images.shape[1]
        )
        file = f"{filename}_{counter:05}_.mp4"
        path = os.path.join(full_out, file)
        frames = (images.detach().cpu().numpy().clip(0.0, 1.0) * 255.0).round().astype(np.uint8)
        n, h, w, c = frames.shape
        if c == 4:
            frames = frames[..., :3]
        # yuv420p needs even dimensions
        h2, w2 = h - (h % 2), w - (w % 2)
        frames = np.ascontiguousarray(frames[:, :h2, :w2, :])
        cmd = [
            "ffmpeg", "-y", "-v", "error",
            "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{w2}x{h2}", "-r", f"{fps}",
            "-i", "-",
            "-c:v", "libx264", "-preset", "medium", "-crf", str(crf),
            "-pix_fmt", "yuv420p", "-movflags", "+faststart", path,
        ]
        proc = subprocess.run(cmd, input=frames.tobytes(), capture_output=True)
        if proc.returncode != 0:
            raise RuntimeError(f"ffmpeg failed: {proc.stderr.decode(errors='replace')[:2000]}")
        print(f"[cf_nodes] wrote {path} ({n} frames @ {fps} fps, {w2}x{h2})")
        return {"ui": {"images": [{"filename": file, "subfolder": subfolder, "type": "output"}]}}


NODE_CLASS_MAPPINGS = {"CFSaveVideo": CFSaveVideo}
NODE_DISPLAY_NAME_MAPPINGS = {"CFSaveVideo": "CF Save Video (mp4)"}
