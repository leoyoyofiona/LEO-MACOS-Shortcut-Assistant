#!/usr/bin/env python3
"""Build the README demo GIF from project screenshots."""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
IMAGES = ROOT / "docs" / "images"
OUTPUT = IMAGES / "demo.gif"
SIZE = (1100, 720)
FPS = 10


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/SFNSDisplay.ttf",
        "/System/Library/Fonts/PingFang.ttc",
    ]
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size=size, index=1 if bold else 0)
        except OSError:
            continue
    return ImageFont.load_default()


def canvas(message: str, detail: str) -> Image.Image:
    image = Image.new("RGBA", SIZE, "#eef1f5")
    draw = ImageDraw.Draw(image)
    icon = Image.open(ROOT / "Resources" / "AppIcon-Source.png").convert("RGBA")
    icon.thumbnail((165, 165), Image.Resampling.LANCZOS)
    image.alpha_composite(icon, ((SIZE[0] - icon.width) // 2, 125))
    title_font = font(42, bold=True)
    detail_font = font(24)
    title_box = draw.textbbox((0, 0), message, font=title_font)
    detail_box = draw.textbbox((0, 0), detail, font=detail_font)
    draw.text(((SIZE[0] - (title_box[2] - title_box[0])) / 2, 340), message, fill="#20242b", font=title_font)
    draw.text(((SIZE[0] - (detail_box[2] - detail_box[0])) / 2, 410), detail, fill="#626a76", font=detail_font)
    return image


def fit(path: Path) -> Image.Image:
    source = Image.open(path).convert("RGBA")
    source.thumbnail((SIZE[0] - 40, SIZE[1] - 40), Image.Resampling.LANCZOS)
    image = Image.new("RGBA", SIZE, "#dfe4eb")
    image.alpha_composite(source, ((SIZE[0] - source.width) // 2, (SIZE[1] - source.height) // 2))
    return image


def hold(frame: Image.Image, seconds: float) -> list[Image.Image]:
    return [frame.copy() for _ in range(round(seconds * FPS))]


def fade(left: Image.Image, right: Image.Image, seconds: float = 0.5) -> list[Image.Image]:
    count = max(2, round(seconds * FPS))
    return [Image.blend(left, right, i / (count - 1)) for i in range(1, count)]


start = canvas("Hold your trigger key", "按住自定义触发键")
panel = fit(IMAGES / "panel-en.png")
end = canvas("Release to hide", "松开按键，面板立即隐藏")

frames = hold(start, 1.2) + fade(start, panel) + hold(panel, 2.2) + fade(panel, end) + hold(end, 1.2)
frames[0].save(
    OUTPUT,
    save_all=True,
    append_images=frames[1:],
    duration=round(1000 / FPS),
    loop=0,
    optimize=True,
    disposal=2,
)
print(OUTPUT)
