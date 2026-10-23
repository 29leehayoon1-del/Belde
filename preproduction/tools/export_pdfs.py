"""Export existing Belde PNG boards as four review PDFs without raster edits.

The original PNG pixels and dimensions are embedded through ReportLab ImageReader.
Only PDF page placement and text are added; no image resizing/resampling is performed.
Requires ReportLab, PyMuPDF and Pillow, all provided in the current environment.
"""
from __future__ import annotations

import json
import os
from pathlib import Path

import fitz
from PIL import Image
from reportlab import rl_config
from reportlab.lib.colors import HexColor
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas


ROOT = Path(__file__).resolve().parents[1]
DELIVERY = ROOT.parent / "delivery"
PAGE_WIDTH, PAGE_HEIGHT = 1200, 800
INK = HexColor("#151b2b")
PARCHMENT = HexColor("#eee0b7")
GOLD = HexColor("#f4c86b")
MUTED = HexColor("#b0bdc8")
LINE = HexColor("#405165")

VOLUMES = [
    ("Belde-01-initial-recruits.pdf", "Initial recruits", 0, 6,
     "The bar, kingdom and village: 31 recruit models."),
    ("Belde-02-reinforcements-and-generals.pdf", "Reinforcements & generals", 6, 11,
     "The royal capital, prison and five monster generals: 27 recruit models."),
    ("Belde-03-enemies-boss-and-maps.pdf", "Enemies, boss & battlefields", 11, 16,
     "Eight ordinary enemy species, Avarren, and all six battlefield studies."),
    ("Belde-04-world-interface-and-motion.pdf", "World, interface & motion", 16, 21,
     "Recruitment locations, connected-editor UI, towers, traps, storyboards and Tornel's motion study."),
]


def register_fonts() -> tuple[str, str]:
    regular = Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")
    bold = Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf")
    if regular.is_file() and bold.is_file():
        pdfmetrics.registerFont(TTFont("BeldeSans", str(regular)))
        pdfmetrics.registerFont(TTFont("BeldeSansBold", str(bold)))
        return "BeldeSans", "BeldeSansBold"
    return "Helvetica", "Helvetica-Bold"


FONT, BOLD = register_fonts()
# Binary Flate streams avoid the 25% size overhead of ASCII85 wrapping.
# This changes PDF stream encoding only, never the embedded raster pixels.
rl_config.useA85 = False


def wrap(text: str, font: str, size: float, width: float) -> list[str]:
    words = text.split()
    lines: list[str] = []
    line = ""
    for word in words:
        candidate = f"{line} {word}".strip()
        if line and pdfmetrics.stringWidth(candidate, font, size) > width:
            lines.append(line)
            line = word
        else:
            line = candidate
    if line:
        lines.append(line)
    return lines


def paragraph(c: canvas.Canvas, text: str, x: float, y: float, width: float,
              size: float = 12, leading: float = 19) -> float:
    c.setFont(FONT, size)
    for line in wrap(text, FONT, size, width):
        c.drawString(x, y, line)
        y -= leading
    return y


def background(c: canvas.Canvas) -> None:
    c.setFillColor(INK)
    c.rect(0, 0, PAGE_WIDTH, PAGE_HEIGHT, fill=1, stroke=0)


def cover(c: canvas.Canvas, volume: int, title: str, summary: str,
          boards: list[dict]) -> None:
    background(c)
    c.setFillColor(GOLD)
    c.setFont(BOLD, 15)
    c.drawString(64, 718, f"VISUAL PREPRODUCTION  /  VOLUME {volume} OF 4")
    c.setFillColor(PARCHMENT)
    c.setFont(BOLD, 64)
    c.drawString(60, 627, "BELDE")
    c.setFont(FONT, 27)
    c.drawString(64, 581, "The Wrong Commander")
    c.setFillColor(GOLD)
    c.setFont(BOLD, 26)
    c.drawString(64, 510, title)
    c.setFillColor(PARCHMENT)
    y = paragraph(c, summary, 64, 471, 1040, 15, 23)
    c.setFillColor(MUTED)
    y = paragraph(c,
        "Original concept boards and key-pose references. The source PNGs are embedded at their original raster dimensions; zoom in to inspect them. These are visual models, not finished sprite atlases or playable software. Balance numbers remain untested design targets.",
        64, y - 20, 1040, 12, 19)
    y -= 26
    c.setFillColor(GOLD)
    c.setFont(BOLD, 13)
    c.drawString(64, y, "BOARDS IN THIS VOLUME")
    y -= 27
    c.setFillColor(PARCHMENT)
    for i, board in enumerate(boards, 1):
        c.setFont(FONT, 13)
        c.drawString(74, y, f"{i:02d}   {board['title']}")
        y -= 26
    c.setStrokeColor(LINE)
    c.line(64, 67, 1136, 67)
    c.setFillColor(MUTED)
    c.setFont(FONT, 10)
    c.drawString(64, 44, "One original board per page. Names, stats and timing in the model catalog are authoritative.")
    c.showPage()


def board_page(c: canvas.Canvas, board: dict, number: int, total: int,
               volume: int) -> None:
    background(c)
    c.setFillColor(PARCHMENT)
    c.setFont(BOLD, 20)
    c.drawString(32, 763, board["title"])
    c.setFillColor(MUTED)
    paragraph(c, board.get("description", "Concept artwork."),
              32, 741, 1136, size=10.5, leading=15)
    path = ROOT / board["file"]
    with Image.open(path) as image:
        width, height = image.size
    box_x, box_y, box_w, box_h = 32, 48, 1136, 654
    scale = min(box_w / width, box_h / height)
    draw_w, draw_h = width * scale, height * scale
    x = box_x + (box_w - draw_w) / 2
    y = box_y + (box_h - draw_h) / 2
    bookmark = f"board-{volume}-{number}"
    c.bookmarkPage(bookmark)
    c.addOutlineEntry(board["title"], bookmark, level=0, closed=False)
    c.drawImage(ImageReader(str(path)), x, y, width=draw_w, height=draw_h,
                mask="auto", preserveAspectRatio=True)
    c.setFillColor(MUTED)
    c.setFont(FONT, 9)
    c.drawString(32, 22, f"BELDE  /  Volume {volume}  /  Concept references")
    c.drawRightString(1168, 22, f"Board {number} of {total}  |  Original {width} x {height} px")
    c.showPage()


def verify(path: Path, boards: list[dict]) -> dict:
    with fitz.open(path) as doc:
        assert len(doc) == len(boards) + 1, (path.name, len(doc))
        for page in doc:
            assert abs(page.rect.width - PAGE_WIDTH) < 0.01
            assert abs(page.rect.height - PAGE_HEIGHT) < 0.01
        for i, board in enumerate(boards, 1):
            with Image.open(ROOT / board["file"]) as image:
                expected = image.size
            images = doc[i].get_images(full=True)
            assert any((entry[2], entry[3]) == expected for entry in images), (
                path.name, board["file"], expected,
                [(entry[2], entry[3]) for entry in images])
        pages = len(doc)
    return {
        "file": path.name,
        "pages": pages,
        "board_count": len(boards),
        "page_points": [PAGE_WIDTH, PAGE_HEIGHT],
        "bytes": path.stat().st_size,
        "mib": round(path.stat().st_size / 1024 / 1024, 2),
        "source_raster_dimensions_preserved": True,
        "validation": "PyMuPDF page count, page geometry and image XObject dimensions passed",
    }


def main() -> None:
    manifest = json.loads((ROOT / "art/manifest.json").read_text())
    assert len(manifest) == 21
    DELIVERY.mkdir(parents=True, exist_ok=True)
    os.chmod(DELIVERY, 0o755)
    results = []
    for volume, (filename, title, start, end, summary) in enumerate(VOLUMES, 1):
        boards = manifest[start:end]
        path = DELIVERY / filename
        c = canvas.Canvas(str(path), pagesize=(PAGE_WIDTH, PAGE_HEIGHT),
                          pageCompression=1)
        c.setTitle(f"BELDE — {title} — Visual preproduction volume {volume}")
        c.setAuthor("Belde visual preproduction")
        c.setSubject("Original concept boards; source PNGs embedded without raster resampling")
        cover(c, volume, title, summary, boards)
        for number, board in enumerate(boards, 1):
            board_page(c, board, number, len(boards), volume)
        c.save()
        os.chmod(path, 0o644)
        results.append(verify(path, boards))
    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
