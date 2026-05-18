# -*- coding: utf-8 -*-
"""
UFC/.cursor/rules/multimodal.mdc: raster via Python (matplotlib + numpy).
Procedural shaded “photo-like” fox — not a cartoon flat fill; no external API.
"""
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


def _ellipse_mask(x: np.ndarray, y: np.ndarray, cx: float, cy: float, rx: float, ry: float) -> np.ndarray:
    return ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0


def _soft_mask(mask: np.ndarray, sigma_px: float = 2.0) -> np.ndarray:
    """Cheap separable Gaussian blur for anti-aliased edges (sigma in pixels)."""
    if sigma_px <= 0:
        return mask.astype(np.float64)
    s = max(1, int(round(3 * sigma_px)))
    k = np.arange(-s, s + 1, dtype=np.float64)
    g = np.exp(-(k**2) / (2 * sigma_px**2))
    g /= g.sum()
    m = mask.astype(np.float64)
    # convolve rows
    pad = s
    m2 = np.pad(m, ((0, 0), (pad, pad)), mode="edge")
    acc = np.zeros_like(m)
    for i in range(m.shape[1]):
        sl = m2[:, i : i + 2 * pad + 1]
        acc[:, i] = (sl * g).sum(axis=1)
    m2 = np.pad(acc, ((pad, pad), (0, 0)), mode="edge")
    out = np.zeros_like(acc)
    for j in range(m.shape[0]):
        sl = m2[j : j + 2 * pad + 1, :]
        out[j, :] = (sl * g[:, None]).sum(axis=0)
    return np.clip(out, 0.0, 1.0)


def build_scene(width: int = 960, height: int = 720) -> np.ndarray:
    """RGB float32 in [0,1], shape (H, W, 3)."""
    xs = np.linspace(0.0, 1.0, width)
    ys = np.linspace(0.0, 1.0, height)
    x, y = np.meshgrid(xs, ys)

    # Sky + distant warm haze (golden hour)
    t = 1.0 - y
    sky_r = 0.52 + 0.38 * (t**0.9) + 0.04 * np.sin(x * np.pi * 3.2)
    sky_g = 0.42 + 0.42 * (t**1.1)
    sky_b = 0.28 + 0.55 * (t**1.25)
    img = np.stack([sky_r, sky_g, sky_b], axis=-1)

    # Ground / bokeh grass
    ground = (y > 0.68).astype(np.float64)
    gnoise = 0.12 * np.sin(x * 120 + y * 40) * np.sin(x * 35 + 8)
    grass = np.stack(
        [
            0.12 + 0.18 * ground + gnoise * ground,
            0.28 + 0.32 * ground + 0.5 * gnoise * ground,
            0.08 + 0.12 * ground + 0.3 * gnoise * ground,
        ],
        axis=-1,
    )
    img = img * (1.0 - ground[..., None]) + grass * ground[..., None]

    # --- Fox masks (normalized coords) ---
    body = _ellipse_mask(x, y, 0.46, 0.62, 0.14, 0.16)
    head = _ellipse_mask(x, y, 0.40, 0.40, 0.11, 0.13)
    snout = _ellipse_mask(x, y, 0.54, 0.44, 0.065, 0.055)
    ear_l = _ellipse_mask(x, y, 0.30, 0.24, 0.038, 0.095)
    ear_r = _ellipse_mask(x, y, 0.48, 0.22, 0.038, 0.095)
    tail = _ellipse_mask(x, y, 0.72, 0.64, 0.12, 0.07)

    raw_fox = body | head | snout | ear_l | ear_r | tail
    fox = _soft_mask(raw_fox, sigma_px=2.2)

    # Key light from upper-left
    lx, ly = 0.18, 0.22
    dx, dy = x - lx, y - ly
    dist = np.sqrt(dx * dx + dy * dy) + 1e-6
    ndx, ndy = dx / dist, dy / dist
    # fake normal: radial from body center
    cx, cy = 0.44, 0.52
    nx, ny = x - cx, y - cy
    nn = np.sqrt(nx * nx + ny * ny) + 1e-6
    nx, ny = nx / nn, ny / nn
    light = np.clip(0.35 + 0.65 * (-ndx * nx - ndy * ny), 0.0, 1.0)
    fur_detail = 0.14 * (np.sin(x * 95 + y * 70) * 0.5 + 0.5) + 0.08 * np.sin(x * 18 * np.pi + y * 12 * np.pi)
    shade = np.clip(light + fur_detail, 0.0, 1.0)

    # Orange-red fur with depth
    fur_r = np.clip(0.32 + 0.55 * shade, 0.0, 1.0)
    fur_g = np.clip(0.12 + 0.28 * shade, 0.0, 1.0)
    fur_b = np.clip(0.04 + 0.10 * shade, 0.0, 1.0)
    fur = np.stack([fur_r, fur_g, fur_b], axis=-1)

    # White muzzle / chest
    muzzle = _soft_mask(_ellipse_mask(x, y, 0.50, 0.46, 0.055, 0.045), 1.5)
    chest = _soft_mask(_ellipse_mask(x, y, 0.48, 0.66, 0.07, 0.09), 2.0)
    white = np.stack([np.ones_like(x) * 0.96, np.ones_like(x) * 0.93, np.ones_like(x) * 0.88], axis=-1)
    blend = np.clip(muzzle + chest, 0.0, 1.0)[..., None]
    fur = fur * (1.0 - 0.92 * blend) + white * (0.92 * blend)

    # Composite fox over scene
    f = fox[..., None]
    img = img * (1.0 - f) + fur * f

    # Eyes (dark, slight wet highlight)
    eye_l = _soft_mask(_ellipse_mask(x, y, 0.36, 0.38, 0.018, 0.022), 0.8)
    eye_r = _soft_mask(_ellipse_mask(x, y, 0.44, 0.38, 0.018, 0.022), 0.8)
    eye = np.clip(eye_l + eye_r, 0.0, 1.0)[..., None]
    dark = np.stack([0.06 * np.ones_like(x), 0.05 * np.ones_like(x), 0.05 * np.ones_like(x)], axis=-1)
    img = img * (1.0 - 0.85 * eye) + dark * (0.85 * eye)
    hi_l = _soft_mask(_ellipse_mask(x, y, 0.362, 0.376, 0.006, 0.007), 0.5)
    hi_r = _soft_mask(_ellipse_mask(x, y, 0.432, 0.376, 0.006, 0.007), 0.5)
    hi = np.clip(hi_l + hi_r, 0.0, 1.0)[..., None]
    spec = np.ones_like(img)
    img = img * (1.0 - hi) + spec * hi * 0.95

    # Nose
    nose = _soft_mask(_ellipse_mask(x, y, 0.535, 0.455, 0.012, 0.010), 0.6)[..., None]
    blk = np.stack([0.12 * np.ones_like(x), 0.08 * np.ones_like(x), 0.07 * np.ones_like(x)], axis=-1)
    img = img * (1.0 - nose) + blk * nose

    # Vignette
    cx2, cy2 = 0.5, 0.48
    vr = np.sqrt((x - cx2) ** 2 + (y - cy2) ** 2)
    vig = np.clip(1.15 - 0.55 * (vr**1.35), 0.0, 1.0)
    img *= vig[..., None]

    return np.clip(img.astype(np.float32), 0.0, 1.0)


def main() -> None:
    out = Path(__file__).resolve().parents[1] / "REPORTS" / "multimodal_test_animal.png"
    out.parent.mkdir(parents=True, exist_ok=True)

    rgb = build_scene(960, 720)
    h, w, _ = rgb.shape
    dpi = 100
    fig = plt.figure(figsize=(w / dpi, h / dpi), dpi=dpi)
    ax = fig.add_axes((0, 0, 1, 1))
    ax.imshow(rgb, origin="upper", interpolation="bilinear")
    ax.axis("off")
    fig.text(
        0.02,
        0.97,
        "multimodal.mdc — matplotlib + numpy (procedural shaded)",
        transform=fig.transFigure,
        fontsize=9,
        color="white",
        va="top",
        family="sans-serif",
    )
    fig.savefig(out, dpi=dpi, pad_inches=0, bbox_inches="tight", facecolor="black")
    plt.close(fig)
    print(out)


if __name__ == "__main__":
    main()
