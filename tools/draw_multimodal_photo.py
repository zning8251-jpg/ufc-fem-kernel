# -*- coding: utf-8 -*-
"""
Photo-realistic raster output aligned with UFC/.cursor/rules/multimodal.mdc.

Backends
--------
- openai   : DALL-E 3 (requires OPENAI_API_KEY; billable; subject to OpenAI policies).
- diffusers: Local Stable Diffusion (requires torch + diffusers; GPU strongly recommended).

Secrets
-------
Never commit API keys. Use environment variables or a local secret manager.

Compliance
----------
You are responsible for provider Terms of Use, content policies, licensing of
generated images, and any export or deployment rules that apply to your org.
Default prompt is a generic wildlife subject suitable for typical safety filters.
"""
from __future__ import annotations

import argparse
import base64
import os
import sys
from pathlib import Path
from typing import Any
from urllib.error import URLError, HTTPError
from urllib.request import Request, urlopen


DEFAULT_PROMPT = (
    "Professional wildlife photograph of a red fox in soft golden hour light, "
    "sharp focus on the eyes, shallow depth of field, natural fur detail, "
    "National Geographic style, full frame DSLR, 85mm lens look, photorealistic, no text"
)

DEFAULT_OUT = Path(__file__).resolve().parents[1] / "REPORTS" / "multimodal_test_animal_photo.png"


def _save_bytes(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def _download_url(url: str, timeout_s: int = 180) -> bytes:
    req = Request(url, headers={"User-Agent": "UFC-draw_multimodal_photo/1.0"})
    with urlopen(req, timeout=timeout_s) as resp:
        return resp.read()


def backend_openai(
    prompt: str,
    out: Path,
    *,
    size: str,
    quality: str | None,
    model: str,
) -> None:
    try:
        from openai import OpenAI
    except ImportError as e:
        sys.exit(
            "Missing package: openai. Install with:\n"
            "  pip install -r tools/requirements_multimodal_photo.txt\n"
            f"  ({e})"
        )

    key = os.environ.get("OPENAI_API_KEY", "").strip()
    if not key:
        sys.exit("OPENAI_API_KEY is not set (required for --backend openai).")

    client = OpenAI(api_key=key)
    gen_kw: dict[str, Any] = {
        "model": model,
        "prompt": prompt,
        "size": size,
        "n": 1,
    }
    if model == "dall-e-3" and quality:
        gen_kw["quality"] = quality
    resp: Any = client.images.generate(**gen_kw)
    item = resp.data[0]
    revised = getattr(item, "revised_prompt", None)
    if revised:
        print("revised_prompt:", revised, file=sys.stderr)

    b64 = getattr(item, "b64_json", None)
    url = getattr(item, "url", None)
    if b64:
        raw = base64.b64decode(b64)
    elif url:
        try:
            raw = _download_url(url)
        except (HTTPError, URLError, TimeoutError) as e:
            sys.exit(f"Failed to download image URL from OpenAI: {e}")
    else:
        sys.exit("OpenAI image response contained neither b64_json nor url.")

    _save_bytes(out, raw)
    print(out)


def _pick_device(explicit: str | None) -> str:
    if explicit and explicit != "auto":
        return explicit
    try:
        import torch

        return "cuda" if torch.cuda.is_available() else "cpu"
    except ImportError:
        return "cpu"


def backend_diffusers(
    prompt: str,
    out: Path,
    *,
    model: str,
    steps: int,
    guidance: float,
    device: str | None,
    seed: int | None,
    no_safety_checker: bool,
) -> None:
    try:
        import torch
        from diffusers import StableDiffusionPipeline
    except ImportError as e:
        sys.exit(
            "Missing packages: torch and/or diffusers. Install PyTorch for your platform, then:\n"
            "  pip install -r tools/requirements_multimodal_photo.txt\n"
            f"  ({e})"
        )

    dev = _pick_device(device)
    torch_dtype = torch.float16 if dev == "cuda" else torch.float32

    load_kw: dict[str, Any] = {
        "torch_dtype": torch_dtype,
        "use_safetensors": True,
    }
    if no_safety_checker:
        load_kw["safety_checker"] = None
        load_kw["requires_safety_checker"] = False

    token = os.environ.get("HF_TOKEN") or os.environ.get("HUGGING_FACE_HUB_TOKEN")
    if token:
        load_kw["token"] = token

    print(f"Loading diffusers model {model!r} on {dev} ({torch_dtype})...", file=sys.stderr)
    pipe = StableDiffusionPipeline.from_pretrained(model, **load_kw)
    pipe = pipe.to(dev)
    if dev == "cpu" and hasattr(pipe, "enable_attention_slicing"):
        pipe.enable_attention_slicing()

    gen = None
    if seed is not None:
        gen = torch.Generator(device=dev).manual_seed(int(seed))

    result = pipe(
        prompt,
        num_inference_steps=int(steps),
        guidance_scale=float(guidance),
        generator=gen,
    )
    image = result.images[0]
    out.parent.mkdir(parents=True, exist_ok=True)
    image.save(out)
    print(out)


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description="Photo-realistic image: DALL-E 3 (API) or local Stable Diffusion (diffusers)."
    )
    p.add_argument(
        "--backend",
        choices=("openai", "diffusers"),
        required=True,
        help="openai=DALL-E API; diffusers=local SD weights",
    )
    p.add_argument("--prompt", default=DEFAULT_PROMPT, help="Text-to-image prompt")
    p.add_argument("--out", type=Path, default=DEFAULT_OUT, help="Output PNG path")
    # OpenAI
    p.add_argument(
        "--openai-model",
        default="dall-e-3",
        choices=("dall-e-3", "dall-e-2"),
        help="Image model when --backend openai",
    )
    p.add_argument(
        "--openai-size",
        default="1024x1024",
        help="OpenAI size, e.g. 1024x1024, 1792x1024, 1024x1792 (DALL-E 3)",
    )
    p.add_argument(
        "--openai-quality",
        default="hd",
        choices=("standard", "hd"),
        help="DALL-E 3 quality tier",
    )
    # Diffusers
    p.add_argument(
        "--sd-model",
        default="runwayml/stable-diffusion-v1-5",
        help="Hugging Face model id for StableDiffusionPipeline",
    )
    p.add_argument("--sd-steps", type=int, default=35, help="Inference steps (local SD)")
    p.add_argument("--sd-guidance", type=float, default=7.5, help="Classifier-free guidance scale")
    p.add_argument(
        "--device",
        default="auto",
        help="cuda | cpu | auto (diffusers only; auto prefers CUDA if available)",
    )
    p.add_argument("--seed", type=int, default=None, help="RNG seed for diffusers (reproducibility)")
    p.add_argument(
        "--no-safety-checker",
        action="store_true",
        help="Disable SD safety checker (not recommended; may violate provider norms)",
    )
    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    out: Path = args.out.resolve()

    if args.backend == "openai":
        q: str | None = args.openai_quality if args.openai_model == "dall-e-3" else None
        if args.openai_model == "dall-e-2" and args.openai_quality == "hd":
            print("Note: 'hd' applies only to dall-e-3; dall-e-2 ignores quality.", file=sys.stderr)
        backend_openai(
            args.prompt,
            out,
            size=args.openai_size,
            quality=q,
            model=args.openai_model,
        )
    else:
        backend_diffusers(
            args.prompt,
            out,
            model=args.sd_model,
            steps=args.sd_steps,
            guidance=args.sd_guidance,
            device=None if args.device == "auto" else args.device,
            seed=args.seed,
            no_safety_checker=bool(args.no_safety_checker),
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
