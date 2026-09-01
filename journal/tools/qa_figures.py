"""Structural QA for generated journal figures."""

from pathlib import Path
from xml.etree import ElementTree as ET

from PIL import Image

from build_figures import (FIGURES, WAVEFORM_FIGURES, PDF, PNG, SOURCE, SVG,
                           dimensions)


def overlap(a, b):
    return not (
        a["x"] + a["w"] <= b["x"] or b["x"] + b["w"] <= a["x"]
        or a["y"] + a["h"] <= b["y"] or b["y"] + b["h"] <= a["y"]
    )


def main():
    errors = []
    for fig in FIGURES:
        name = fig["name"]
        nodes = fig["nodes"]
        width, height = dimensions(fig)
        for i, n in enumerate(nodes):
            if min(n["x"], n["y"], n["w"], n["h"]) < 0 or n["x"] + n["w"] > width or n["y"] + n["h"] > height:
                errors.append(f"{name}: node {i+1} outside canvas")
            last_baseline = n["y"] + 29 + (28 if n["lines"] else 0) + max(0, len(n["lines"])-1) * max(19, n["size"]+2)
            if last_baseline > n["y"] + n["h"] - 7:
                errors.append(f"{name}: text capacity exceeded in node {i+1}")
            for j in range(i+1, len(nodes)):
                if overlap(n, nodes[j]):
                    errors.append(f"{name}: nodes {i+1} and {j+1} overlap")
        for a in fig["arrows"]:
            for x, y in [(a["x1"], a["y1"]), *a["waypoints"], (a["x2"], a["y2"])]:
                if not (0 <= x <= width and 0 <= y <= height):
                    errors.append(f"{name}: arrow point outside canvas")
        for suffix, directory in ((".drawio", SOURCE), (".svg", SVG), (".png", PNG)):
            path = directory / f"{name}{suffix}"
            if not path.exists() or path.stat().st_size == 0:
                errors.append(f"{name}: missing {suffix}")
        for xml_path in (SOURCE / f"{name}.drawio", SVG / f"{name}.svg"):
            try:
                ET.parse(xml_path)
            except Exception as exc:
                errors.append(f"{name}: invalid XML {xml_path.name}: {exc}")
        with Image.open(PNG / f"{name}.png") as image:
            expected = (1600, round(height * 1600 / width))
            if image.size != expected:
                errors.append(f"{name}: unexpected PNG size {image.size}")
            if image.getbbox() is None:
                errors.append(f"{name}: blank PNG")
    for item in WAVEFORM_FIGURES:
        name = item["name"]
        for suffix, directory in ((".svg", SVG), (".png", PNG)):
            path = directory / f"{name}{suffix}"
            if not path.exists() or path.stat().st_size == 0:
                errors.append(f"{name}: missing {suffix}")
        svg_path = SVG / f"{name}.svg"
        try:
            root = ET.parse(svg_path).getroot()
            src_width = int(root.attrib["width"])
            src_height = int(root.attrib["height"])
        except Exception as exc:
            errors.append(f"{name}: invalid SVG: {exc}")
            continue
        with Image.open(PNG / f"{name}.png") as image:
            expected = (2400, round(src_height * 2400 / src_width))
            if image.size != expected:
                errors.append(f"{name}: unexpected PNG size {image.size}")
            if image.getbbox() is None:
                errors.append(f"{name}: blank PNG")
    if errors:
        print("FIGURE_QA_FAIL")
        print("\n".join(errors))
        raise SystemExit(1)
    print(f"FIGURE_QA_PASS diagrams={len(FIGURES)} waveforms={len(WAVEFORM_FIGURES)} aspect_preserved=yes")


if __name__ == "__main__":
    main()
