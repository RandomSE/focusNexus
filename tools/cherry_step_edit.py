"""Incremental cherry blossom tree step edits (idempotent from previous step)."""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


CANVAS_W, CANVAS_H = 1536, 1024


def load_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def tree_mask(arr: np.ndarray, alpha_threshold: int = 10) -> np.ndarray:
    return arr[:, :, 3] > alpha_threshold


def pink_mask(arr: np.ndarray, mask: np.ndarray) -> np.ndarray:
    rgb = arr[:, :, :3].astype(np.int16)
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    return (
        mask
        & (r > 190)
        & (g > 120)
        & (b > 150)
        & (r > g)
        & (r > b - 10)
    )


def bbox_of(mask: np.ndarray) -> tuple[int, int, int, int]:
    ys, xs = np.where(mask)
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())


def crop_to_content(layer: Image.Image) -> tuple[Image.Image, int, int]:
    arr = np.array(layer)
    mask = arr[:, :, 3] > 10
    x0, y0, x1, y1 = bbox_of(mask)
    return layer.crop((x0, y0, x1 + 1, y1 + 1)), x0, y0


def make_step_1(step_0_path: Path, out_path: Path) -> None:
    """Trunk grows 8% -> 12% canvas height, slightly thicker. Canopy unchanged size."""
    im = load_rgba(step_0_path)
    arr = np.array(im)
    mask = tree_mask(arr)
    pink = pink_mask(arr, mask)
    brown = mask & ~pink

    x0, y0, x1, y1 = bbox_of(mask)
    tree_h = y1 - y0 + 1
    cx = (x0 + x1) // 2

    # Trunk is the lower ~62% of tree height; canopy is upper twigs + buds.
    split_y = y0 + int(tree_h * 0.38)
    trunk_h = y1 - split_y + 1

    trunk_growth = 12 / 8  # step_0 trunk spec 8% -> step_1 trunk spec 12%
    delta_h = int(round(trunk_h * (trunk_growth - 1.0)))
    scale_x = 1.10

    tree_crop, ox, oy = crop_to_content(im)
    tw, th = tree_crop.size
    new_w = max(1, int(round(tw * scale_x)))
    new_h = th + delta_h

    # Scale width only on trunk band; translate canopy upward.
    trunk_band = split_y - oy
    trunk_part = tree_crop.crop((0, trunk_band, tw, th))
    canopy_part = tree_crop.crop((0, 0, tw, trunk_band))

    trunk_scaled = trunk_part.resize(
        (max(1, int(round(trunk_part.width * scale_x))), trunk_part.height + delta_h),
        Image.Resampling.LANCZOS,
    )
    canopy_scaled = canopy_part.resize(
        (max(1, int(round(canopy_part.width * scale_x))), canopy_part.height),
        Image.Resampling.LANCZOS,
    )

    composed = Image.new(
        "RGBA",
        (max(trunk_scaled.width, canopy_scaled.width), trunk_scaled.height + canopy_scaled.height),
        (0, 0, 0, 0),
    )
    composed.paste(
        trunk_scaled,
        ((composed.width - trunk_scaled.width) // 2, canopy_scaled.height),
        trunk_scaled,
    )
    composed.paste(
        canopy_scaled,
        ((composed.width - canopy_scaled.width) // 2, 0),
        canopy_scaled,
    )

    comp_arr = np.array(composed)
    _, _, _, comp_bottom = bbox_of(tree_mask(comp_arr))
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    paste_y = y1 - comp_bottom
    paste_x = cx - composed.width // 2
    out.paste(composed, (paste_x, paste_y), composed)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out.save(out_path)


def brown_mask(arr: np.ndarray, mask: np.ndarray) -> np.ndarray:
    return mask & ~pink_mask(arr, mask)


def sample_trunk_brown(arr: np.ndarray, brown: np.ndarray, cx: int, y_from: int, y_to: int) -> tuple[int, int, int]:
    region = brown[y_from : y_to + 1, max(0, cx - 20) : min(CANVAS_W, cx + 21)]
    if not region.any():
        pixels = arr[brown][:, :3]
    else:
        ys, xs = np.where(region)
        pixels = arr[y_from + ys, max(0, cx - 20) + xs][:, :3]
    med = np.median(pixels, axis=0).astype(int)
    return int(med[0]), int(med[1]), int(med[2])


def bezier_points(p0: tuple[int, int], p1: tuple[int, int], p2: tuple[int, int], steps: int = 24) -> list[tuple[int, int]]:
    pts: list[tuple[int, int]] = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        x = int(u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0])
        y = int(u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1])
        pts.append((x, y))
    return pts


def trunk_base_metrics(arr: np.ndarray, brown: np.ndarray, cx: int, y1: int) -> tuple[int, int, int, int]:
    """Return trunk bottom row and left/right attachment x at base."""
    for y in range(y1, max(0, y1 - 8), -1):
        row = brown[y]
        if row.any():
            xs = np.where(row)[0]
            center_slice = row[max(0, cx - 18) : min(CANVAS_W, cx + 19)]
            if center_slice.any():
                return y, int(xs.min()), int(xs.max()), cx
    row = brown[y1]
    xs = np.where(row)[0]
    return y1, int(xs.min()), int(xs.max()), cx


def make_step_3(step_2_path: Path, out_path: Path) -> None:
    """Add two small exposed root curves at base, spreading slightly."""
    im = load_rgba(step_2_path)
    arr = np.array(im)
    mask = tree_mask(arr)
    brown = brown_mask(arr, mask)

    x0, y0, x1, y1 = bbox_of(mask)
    cx = (x0 + x1) // 2
    base_y, base_left, base_right, _ = trunk_base_metrics(arr, brown, cx, y1)
    trunk_color = sample_trunk_brown(arr, brown, cx, max(y0, base_y - 12), base_y)
    dark_root = tuple(int(c * 0.82) for c in trunk_color)
    light_root = tuple(int(min(255, c * 1.08 + 8)) for c in trunk_color)

    overlay = Image.new("RGBA", im.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    stroke = max(4, (base_right - base_left) // 6)

    left_start = (base_left + 2, base_y)
    left_ctrl = (base_left - 16, base_y + 6)
    left_end = (base_left - 28, base_y + 14)
    right_start = (base_right - 2, base_y)
    right_ctrl = (base_right + 16, base_y + 6)
    right_end = (base_right + 28, base_y + 14)

    for pts, color in (
        (bezier_points(left_start, left_ctrl, left_end), dark_root),
        (bezier_points(right_start, right_ctrl, right_end), dark_root),
    ):
        draw.line(pts, fill=color + (235,), width=stroke, joint="curve")

    # Subtle upper-edge highlight on each root curve.
    draw.line(
        bezier_points(
            (left_start[0] + 1, left_start[1] - 1),
            (left_ctrl[0] + 4, left_ctrl[1] - 1),
            (left_end[0] + 2, left_end[1] - 1),
        ),
        fill=light_root + (90,),
        width=max(2, stroke // 2),
        joint="curve",
    )
    draw.line(
        bezier_points(
            (right_start[0] - 1, right_start[1] - 1),
            (right_ctrl[0] - 4, right_ctrl[1] - 1),
            (right_end[0] - 2, right_end[1] - 1),
        ),
        fill=light_root + (90,),
        width=max(2, stroke // 2),
        joint="curve",
    )

    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=0.35))
    out = Image.alpha_composite(im, overlay)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out.save(out_path)


def cubic_bezier_points(
    p0: tuple[int, int],
    p1: tuple[int, int],
    p2: tuple[int, int],
    p3: tuple[int, int],
    steps: int = 36,
) -> list[tuple[int, int]]:
    pts: list[tuple[int, int]] = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        x = int(
            u**3 * p0[0]
            + 3 * u**2 * t * p1[0]
            + 3 * u * t**2 * p2[0]
            + t**3 * p3[0]
        )
        y = int(
            u**3 * p0[1]
            + 3 * u**2 * t * p1[1]
            + 3 * u * t**2 * p2[1]
            + t**3 * p3[1]
        )
        pts.append((x, y))
    return pts


def trunk_body_bounds(
    arr: np.ndarray,
    brown: np.ndarray,
    x0: int,
    y0: int,
    y1: int,
    cx: int,
    half: int,
) -> tuple[int, int]:
    tree_h = y1 - y0 + 1
    trunk_top = y0 + int(tree_h * 0.38)
    trunk_mask = brown & (np.abs(np.arange(CANVAS_W)[None, :] - cx) < half)
    trunk_mask[:trunk_top, :] = False
    # Exclude root flare pixels below main trunk column.
    trunk_mask[y1 - int(tree_h * 0.08) :, :] = False
    ty = np.where(trunk_mask)
    if len(ty[0]) == 0:
        return trunk_top, y1 - int(tree_h * 0.08)
    return int(ty[0].min()), int(ty[0].max())


def fork_region_metrics(
    brown: np.ndarray,
    x0: int,
    y0: int,
    y1: int,
    cx: int,
) -> tuple[int, int, int, int]:
    tip_band = brown[y0 : y0 + int((y1 - y0) * 0.2), :]
    ty, tx = np.where(tip_band)
    if len(ty) == 0:
        raise RuntimeError("Could not locate fork region.")
    tip_y = int(ty.min() + y0)
    fork_base_y = int(ty.max() + y0)
    center_xs = tx[np.abs(tx - (cx - x0)) <= 14]
    tip_cx = int(np.median(center_xs) + x0) if len(center_xs) else cx
    return tip_y, fork_base_y, tip_cx, fork_base_y


def root_curve_specs(
    base_y: int,
    base_left: int,
    base_right: int,
    stroke: int,
) -> tuple[
    tuple[tuple[int, int], tuple[int, int], tuple[int, int]],
    tuple[tuple[int, int], tuple[int, int], tuple[int, int]],
]:
    left = (
        (base_left + 2, base_y),
        (base_left - 16, base_y + 6),
        (base_left - 28, base_y + 14),
    )
    right = (
        (base_right - 2, base_y),
        (base_right + 16, base_y + 6),
        (base_right + 28, base_y + 14),
    )
    return left, right


def make_step_5(step_4_path: Path, out_path: Path) -> None:
    """Fork becomes more distinct — two sub-trunks leaning slightly outward."""
    im = load_rgba(step_4_path)
    arr = np.array(im)
    mask = tree_mask(arr)
    brown = brown_mask(arr, mask)

    x0, y0, x1, y1 = bbox_of(mask)
    cx = (x0 + x1) // 2
    tip_y, fork_base_y, tip_cx, _ = fork_region_metrics(brown, x0, y0, y1, cx)
    stroke = max(4, (x1 - x0) // 65)
    trunk_color = sample_trunk_brown(arr, brown, tip_cx, fork_base_y - 6, min(y1, fork_base_y + 4))
    dark = tuple(int(c * 0.9) for c in trunk_color)

    out_arr = np.array(im.copy())
    fork_zone = (
        brown
        & (np.arange(CANVAS_H)[:, None] >= tip_y - 2)
        & (np.arange(CANVAS_H)[:, None] <= fork_base_y + 4)
        & (np.abs(np.arange(CANVAS_W)[None, :] - tip_cx) <= stroke + 8)
    )
    out_arr[fork_zone] = (0, 0, 0, 0)
    out = Image.fromarray(out_arr)

    draw = ImageDraw.Draw(out)
    junction = (tip_cx, fork_base_y + 2)
    left_tip = (tip_cx - 16, tip_y - 2)
    right_tip = (tip_cx + 16, tip_y - 2)
    mid_left = (tip_cx - 8, fork_base_y - 6)
    mid_right = (tip_cx + 8, fork_base_y - 6)

    draw.line([junction, mid_left, left_tip], fill=trunk_color + (255,), width=stroke, joint="curve")
    draw.line([junction, mid_right, right_tip], fill=trunk_color + (255,), width=stroke, joint="curve")
    draw.ellipse(
        [
            junction[0] - stroke // 2,
            junction[1] - stroke // 2,
            junction[0] + stroke // 2,
            junction[1] + stroke // 2,
        ],
        fill=dark + (255,),
    )

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out.save(out_path)


def _bark_overlay(
    arr: np.ndarray,
    brown: np.ndarray,
    cx: int,
    trunk_top: int,
    trunk_bottom: int,
    half: int,
    side: str,
) -> Image.Image:
    trunk_color = sample_trunk_brown(arr, brown, cx, trunk_top + 4, trunk_bottom - 4)
    dark = tuple(int(c * 0.62) for c in trunk_color) + (72,)
    overlay = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    h = trunk_bottom - trunk_top
    offset = max(4, half // 3)
    if side == "left":
        p0 = (cx - offset, trunk_top + 10)
        p1 = (cx + offset // 2, trunk_top + h // 4)
        p2 = (cx - offset, trunk_top + h // 2)
        p3 = (cx + offset // 3, trunk_bottom - 10)
    else:
        p0 = (cx + offset, trunk_top + 12)
        p1 = (cx - offset // 2, trunk_top + h // 3)
        p2 = (cx + offset, trunk_top + (2 * h) // 3)
        p3 = (cx - offset // 3, trunk_bottom - 8)

    draw.line(cubic_bezier_points(p0, p1, p2, p3), fill=dark, width=2, joint="curve")
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=0.6))

    trunk_mask = brown & (np.abs(np.arange(CANVAS_W)[None, :] - cx) < half + 2)
    trunk_mask[:trunk_top, :] = False
    trunk_mask[trunk_bottom + 1 :, :] = False
    overlay_arr = np.array(overlay)
    overlay_arr[~trunk_mask] = (0, 0, 0, 0)
    return Image.fromarray(overlay_arr)


def make_step_6(step_5_path: Path, out_path: Path) -> None:
    """Bark gains first texture line — faint dark S-curve down the trunk."""
    im = load_rgba(step_5_path)
    arr = np.array(im)
    mask = tree_mask(arr)
    brown = brown_mask(arr, mask)

    x0, y0, x1, y1 = bbox_of(mask)
    cx = (x0 + x1) // 2
    half = max(8, (x1 - x0) // 5)
    trunk_top, trunk_bottom = trunk_body_bounds(arr, brown, x0, y0, y1, cx, half)

    overlay = _bark_overlay(arr, brown, cx, trunk_top, trunk_bottom, half, "left")
    out = Image.alpha_composite(im, overlay)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out.save(out_path)


def make_step_7(step_6_path: Path, out_path: Path) -> None:
    """Second bark line appears on opposite side."""
    im = load_rgba(step_6_path)
    arr = np.array(im)
    mask = tree_mask(arr)
    brown = brown_mask(arr, mask)

    x0, y0, x1, y1 = bbox_of(mask)
    cx = (x0 + x1) // 2
    half = max(8, (x1 - x0) // 5)
    trunk_top, trunk_bottom = trunk_body_bounds(arr, brown, x0, y0, y1, cx, half)

    overlay = _bark_overlay(arr, brown, cx, trunk_top, trunk_bottom, half, "right")
    out = Image.alpha_composite(im, overlay)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out.save(out_path)


def make_step_8(step_7_path: Path, out_path: Path) -> None:
    """Root curves thicken very slightly, more grounded."""
    im = load_rgba(step_7_path)
    arr = np.array(im)
    mask = tree_mask(arr)
    brown = brown_mask(arr, mask)

    x0, y0, x1, y1 = bbox_of(mask)
    cx = (x0 + x1) // 2
    base_y, base_left, base_right, _ = trunk_base_metrics(arr, brown, cx, y1)
    trunk_color = sample_trunk_brown(arr, brown, cx, max(y0, base_y - 12), base_y)
    dark_root = tuple(int(c * 0.8) for c in trunk_color)
    light_root = tuple(int(min(255, c * 1.08 + 8)) for c in trunk_color)

    overlay = Image.new("RGBA", im.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    stroke = max(5, (base_right - base_left) // 5)

    left, right = root_curve_specs(base_y, base_left, base_right, stroke)
    left_end = (left[2][0] - 4, left[2][1] + 3)
    right_end = (right[2][0] + 4, right[2][1] + 3)

    for pts, color in (
        (bezier_points(left[0], left[1], left_end), dark_root),
        (bezier_points(right[0], right[1], right_end), dark_root),
    ):
        draw.line(pts, fill=color + (245,), width=stroke, joint="curve")

    draw.line(
        bezier_points(
            (left[0][0] + 1, left[0][1]),
            (left[1][0] + 5, left[1][1]),
            (left_end[0] + 2, left_end[1] - 1),
        ),
        fill=light_root + (95,),
        width=max(2, stroke // 2),
        joint="curve",
    )
    draw.line(
        bezier_points(
            (right[0][0] - 1, right[0][1]),
            (right[1][0] - 5, right[1][1]),
            (right_end[0] - 2, right_end[1] - 1),
        ),
        fill=light_root + (95,),
        width=max(2, stroke // 2),
        joint="curve",
    )

    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=0.4))
    out = Image.alpha_composite(im, overlay)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out.save(out_path)


def make_step_4(step_3_path: Path, out_path: Path) -> None:
    """Trunk top begins to fork — subtle Y shape at the very tip."""
    im = load_rgba(step_3_path)
    arr = np.array(im)
    mask = tree_mask(arr)
    brown = brown_mask(arr, mask)

    x0, y0, x1, y1 = bbox_of(mask)
    cx = (x0 + x1) // 2

    # Center trunk tip: narrow brown column in upper tree.
    tip_band = brown[y0 : y0 + int((y1 - y0) * 0.18), :]
    ty, tx = np.where(tip_band)
    if len(ty) == 0:
        raise RuntimeError("Could not locate trunk tip in step_3 image.")
    tip_y = int(ty.min() + y0)
    tip_rows = tip_band[: max(1, int(ty.max()) + 1), :]
    row_ys, row_xs = np.where(tip_rows)
    center_xs = row_xs[np.abs(row_xs - cx) <= 12]
    tip_cx = int(np.median(center_xs)) if len(center_xs) else cx

    stroke = max(3, (x1 - x0) // 70)
    fork_base_y = int(ty.max() + y0)
    trunk_color = sample_trunk_brown(arr, brown, tip_cx, fork_base_y - 8, min(y1, fork_base_y + 2))
    dark = tuple(int(c * 0.88) for c in trunk_color)

    out_arr = np.array(im.copy())
    tip_column = (
        brown
        & (np.abs(np.arange(CANVAS_W)[None, :] - tip_cx) <= stroke + 1)
        & (np.arange(CANVAS_H)[:, None] >= tip_y - 1)
        & (np.arange(CANVAS_H)[:, None] <= fork_base_y + 2)
    )
    out_arr[tip_column] = (0, 0, 0, 0)
    out = Image.fromarray(out_arr)

    draw = ImageDraw.Draw(out)
    junction = (tip_cx, fork_base_y + 1)
    left_tip = (tip_cx - 7, tip_y + 2)
    right_tip = (tip_cx + 7, tip_y + 2)
    draw.line([junction, left_tip], fill=trunk_color + (255,), width=stroke, joint="curve")
    draw.line([junction, right_tip], fill=trunk_color + (255,), width=stroke, joint="curve")
    draw.ellipse(
        [
            junction[0] - stroke // 2,
            junction[1] - stroke // 2,
            junction[0] + stroke // 2,
            junction[1] + stroke // 2,
        ],
        fill=dark + (255,),
    )

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out.save(out_path)


def make_step_2(step_1_path: Path, out_path: Path) -> None:
    """Add faint lighter stripe on left trunk edge only."""
    im = load_rgba(step_1_path)
    arr = np.array(im)
    mask = tree_mask(arr)
    pink = pink_mask(arr, mask)
    brown = mask & ~pink

    x0, y0, x1, y1 = bbox_of(mask)
    cx = (x0 + x1) // 2
    half = max(8, (x1 - x0) // 5)

    tree_h = y1 - y0 + 1
    trunk_bottom_y = y0 + int(tree_h * 0.62)
    trunk_mask = brown & (np.abs(np.arange(CANVAS_W)[None, :] - cx) < half)
    trunk_mask[:y0, :] = False
    trunk_mask[trunk_bottom_y:, :] = False

    ty = np.where(trunk_mask)
    if len(ty[0]) == 0:
        trunk_mask = brown & (np.abs(np.arange(CANVAS_W)[None, :] - cx) < half)
        ty = np.where(trunk_mask)
    trunk_top, trunk_bottom = int(ty[0].min()), int(ty[0].max())

    overlay = Image.new("RGBA", im.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    trunk_pixels = arr[trunk_mask][:, :3]
    base = np.median(trunk_pixels, axis=0).astype(int)
    highlight = tuple(int(min(255, c * 1.22 + 24)) for c in base) + (58,)

    left_x = cx - half + 3
    stripe_w = max(3, half // 3)
    y_top = trunk_top + 4
    y_bottom = max(y_top + 8, trunk_bottom - 2)
    draw.rounded_rectangle(
        [left_x, y_top, left_x + stripe_w, y_bottom],
        radius=stripe_w // 2,
        fill=highlight,
    )
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=1.0))

    overlay_arr = np.array(overlay)
    overlay_arr[~trunk_mask] = (0, 0, 0, 0)
    overlay = Image.fromarray(overlay_arr)

    out = Image.alpha_composite(im, overlay)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out.save(out_path)


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    stage0 = root / "assets/images/cherry_blossom_tree/stage_0/step_0.png"
    stage1_dir = root / "assets/images/cherry_blossom_tree/stage_1"
    step1 = stage1_dir / "step_1.png"
    step2 = stage1_dir / "step_2.png"
    step3 = stage1_dir / "step_3.png"
    step4 = stage1_dir / "step_4.png"
    step5 = stage1_dir / "step_5.png"
    step6 = stage1_dir / "step_6.png"
    step7 = stage1_dir / "step_7.png"
    step8 = stage1_dir / "step_8.png"

    cmd = sys.argv[1] if len(sys.argv) > 1 else "all"
    if cmd in ("1", "all"):
        make_step_1(stage0, step1)
        print(f"Wrote {step1}")
    if cmd in ("2", "all"):
        make_step_2(step1, step2)
        print(f"Wrote {step2}")
    if cmd in ("3", "all"):
        make_step_3(step2, step3)
        print(f"Wrote {step3}")
    if cmd in ("4", "all"):
        make_step_4(step3, step4)
        print(f"Wrote {step4}")
    if cmd in ("5", "all"):
        make_step_5(step4, step5)
        print(f"Wrote {step5}")
    if cmd in ("6", "all"):
        make_step_6(step5, step6)
        print(f"Wrote {step6}")
    if cmd in ("7", "all"):
        make_step_7(step6, step7)
        print(f"Wrote {step7}")
    if cmd in ("8", "all"):
        make_step_8(step7, step8)
        print(f"Wrote {step8}")


if __name__ == "__main__":
    main()
