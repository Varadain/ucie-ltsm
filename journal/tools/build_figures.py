"""Build original publication figures and editable diagrams.net sources.

The geometry is intentionally explicit so SVG, PNG, PDF, and draw.io views use
the same layout. No input is read from references_private/.
"""

from __future__ import annotations

import argparse
import html
import math
import os
import subprocess
from pathlib import Path
from xml.etree.ElementTree import Element, SubElement, ElementTree

from reportlab.pdfgen import canvas


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "figures" / "source"
SVG = ROOT / "figures" / "svg"
PDF = ROOT / "figures" / "pdf"
PNG = ROOT / "figures" / "png"

W, H = 1200, 675
P = {
    "bg": "#FFFDF5",
    "ink": "#172033",
    "muted": "#56616F",
    "gold": "#F7E396",
    "gold2": "#FFF3BD",
    "blue": "#DDEBF7",
    "green": "#DFF0D8",
    "red": "#F8D7DA",
    "gray": "#E9ECEF",
    "purple": "#E9E0F7",
    "white": "#FFFFFF",
}


def node(x, y, w, h, title, lines=(), fill="white", stroke="ink", dashed=False, size=16):
    return {"x": x, "y": y, "w": w, "h": h, "title": title,
            "lines": list(lines), "fill": P[fill], "stroke": P[stroke],
            "dashed": dashed, "size": size}


def arrow(x1, y1, x2, y2, label="", dashed=False, color="ink", waypoints=()):
    return {"x1": x1, "y1": y1, "x2": x2, "y2": y2, "label": label,
            "dashed": dashed, "color": P[color], "waypoints": list(waypoints)}


def label(x, y, text, size=16, weight="normal", anchor="middle", color="ink"):
    return {"x": x, "y": y, "text": text, "size": size,
            "weight": weight, "anchor": anchor, "color": P[color]}


FIGURES = [
    {
        "name": "fig01_scope", "title": "Implemented digital-control boundary",
        "nodes": [
            node(55, 110, 220, 130, "Link partner / PHY model",
                 ["ready-valid sideband", "sample/corruption stimulus", "phase completion"], "blue"),
            node(340, 70, 520, 330, "UCIe 2.0-derived digital-control subset",
                 ["Nine top-level LTSM states", "Sideband retry and message matching",
                  "DATATRAINCENTER1 LFSR measurement", "Retained TRAINERROR cause/count",
                  "Compact byte-addressed FPGA CSR"], "gold", size=18),
            node(925, 110, 220, 130, "System consumer",
                 ["link-up / state status", "retrain and PM requests", "CSR reads and clear"], "green"),
            node(90, 500, 1020, 90, "Outside the evidence boundary",
                 ["Analog PHY and channel  |  BER / eye / lane rate  |  Mainband datapath  |  Complete adapter/protocol  |  Compliance and interoperability"],
                 "gray", dashed=True, size=17),
        ],
        "arrows": [
            arrow(275, 175, 340, 175, "stimulus"),
            arrow(340, 215, 275, 215, "responses"),
            arrow(860, 175, 925, 175, "status"),
            arrow(925, 215, 860, 215, "requests"),
        ],
        "labels": [],
    },
    {
        "name": "fig02_rtl_architecture", "title": "Modular RTL architecture",
        "nodes": [
            node(45, 100, 200, 115, "Control inputs", ["reset / phase_done", "retrain / PM", "fatal / clear"], "blue"),
            node(45, 290, 200, 115, "Link-partner inputs", ["sideband ready/valid", "training samples", "backpressure"], "blue"),
            node(320, 70, 350, 360, "ucie_ltsm", ["state + substate registers", "residency timer", "next-state control", "production gate", "status outputs"], "gold", size=19),
            node(755, 70, 380, 90, "ucie_sb_sequencer", ["SEND / WAIT / RETRY / ERROR"], "gold2"),
            node(755, 205, 380, 105, "ucie_lfsr_training_engine", ["16 lane states, accepted samples", "strict threshold + saturation"], "gold2"),
            node(755, 355, 380, 105, "ucie_error_manager", ["cause priority, pending retention", "bounded entry + protected clear"], "gold2"),
            node(320, 525, 815, 85, "ucie_ltsm_fpga_wrapper", ["CSR 0x00–0x0A status  |  0x10 control  |  reduced external diagnostics"], "green"),
        ],
        "arrows": [
            arrow(245, 155, 320, 155), arrow(245, 345, 320, 345),
            arrow(670, 130, 755, 115, "command/status"),
            arrow(670, 250, 755, 255, "start/result"),
            arrow(670, 375, 755, 405, "event/entry"),
            arrow(495, 430, 495, 525, "state + diagnostics"),
            arrow(945, 460, 945, 525, "retained log"),
        ],
        "labels": [],
    },
    {
        "name": "fig03_ltsm_flow", "title": "Hierarchical LTSM control flow",
        "nodes": [
            node(55, 120, 130, 70, "RESET", [], "gray"),
            node(225, 120, 130, 70, "SBINIT", [], "gold2"),
            node(395, 120, 130, 70, "MBINIT", ["6 substates"], "gold2"),
            node(565, 120, 130, 70, "MBTRAIN", ["13 substates"], "gold"),
            node(735, 120, 130, 70, "LINKINIT", [], "gold2"),
            node(905, 120, 130, 70, "ACTIVE", ["link_up = 1"], "green"),
            node(795, 315, 180, 75, "PHYRETRAIN", ["three targets"], "purple"),
            node(1010, 315, 140, 75, "L1 / L2", ["low power"], "blue"),
            node(425, 500, 330, 85, "TRAINERROR", ["retained cause + count", "recovery or protected clear"], "red"),
            node(485, 265, 300, 105, "Integrated MBTRAIN focus", ["DATATRAINCENTER1", "START → PATTERN → END", "then DATATRAINVREF"], "gold"),
        ],
        "arrows": [
            arrow(185, 155, 225, 155), arrow(355, 155, 395, 155),
            arrow(525, 155, 565, 155), arrow(695, 155, 735, 155),
            arrow(865, 155, 905, 155),
            arrow(930, 190, 850, 315), arrow(1000, 190, 1070, 315),
            arrow(900, 315, 955, 190), arrow(1110, 315, 1015, 190),
            arrow(630, 190, 635, 265, "CENTER1"),
            arrow(425, 542, 185, 190, "recovery", dashed=True),
            arrow(600, 425, 600, 500, "eligible error", color="ink"),
        ],
        "labels": [
            label(185, 450, "Global timeout / sideband protocol / local fatal", 15, "bold", "start"),
            label(845, 285, "to retrain", 13, "bold"), label(955, 285, "return", 13, "bold"),
            label(1045, 285, "enter PM", 13, "bold"), label(1140, 285, "wake", 13, "bold"),
        ],
    },
    {
        "name": "fig04_integrated_sequence", "title": "Production DATATRAINCENTER1 sequence",
        "nodes": [
            node(50, 75, 190, 55, "Controller", [], "gold"),
            node(310, 75, 190, 55, "Sideband engine", [], "gold2"),
            node(570, 75, 190, 55, "Link partner", [], "blue"),
            node(830, 75, 190, 55, "LFSR engine", [], "gold2"),
            node(315, 545, 700, 70, "Advance guard", ["pattern pass  AND  matching END response  →  DATATRAINVREF"], "green", size=18),
        ],
        "arrows": [
            arrow(145, 180, 405, 180, "START command"),
            arrow(405, 225, 665, 225, "START request"),
            arrow(665, 270, 405, 270, "matching response"),
            arrow(405, 315, 925, 315, "begin pattern"),
            arrow(925, 360, 145, 360, "pass / fail + exact error count"),
            arrow(145, 405, 405, 405, "END only after pass"),
            arrow(405, 450, 665, 450, "END request / response"),
            arrow(665, 495, 145, 495, "closing response observed"),
            arrow(405, 495, 405, 545),
        ],
        "labels": [
            label(1090, 225, "Retry on timeout", 15, "bold"),
            label(1090, 250, "Abort on mismatch", 15),
            label(1090, 365, "Fail retries PATTERN", 15, "bold"),
            label(1090, 390, "without sending END", 15),
            label(140, 650, "Independent predictor checks order, accepted samples, lane state, threshold, abort cause, and advancement", 15, "bold", "start"),
        ],
        "lifelines": [145, 405, 665, 925],
    },
    {
        "name": "fig05_lfsr_engine", "title": "Per-lane LFSR measurement engine",
        "nodes": [
            node(50, 90, 210, 140, "Inputs", ["start / abort", "sample_valid", "16 received bits", "error threshold"], "blue"),
            node(330, 65, 470, 165, "16 independent 23-bit LFSRs", ["eight nonzero seeds repeated across lanes", "polynomial: x²³+x²¹+x¹⁶+x⁸+x⁵+x²+1", "advance only on accepted sample"], "gold", size=18),
            node(330, 300, 220, 125, "Mismatch compare", ["expected vs. received", "per accepted sample"], "gold2"),
            node(610, 300, 220, 125, "16-bit error count", ["saturates at 65,535", "no wraparound"], "gold2"),
            node(900, 90, 245, 130, "Outputs", ["busy / done", "passed", "error_count"], "green"),
            node(900, 320, 245, 105, "Decision", ["pass iff errors < threshold", "equality is failure"], "green"),
            node(330, 515, 500, 85, "Independent UVM reference", ["separate polynomial/state update and exact lane/error prediction"], "purple", dashed=True),
        ],
        "arrows": [
            arrow(260, 150, 330, 150), arrow(800, 150, 900, 150),
            arrow(565, 230, 440, 300), arrow(550, 362, 610, 362),
            arrow(830, 362, 900, 362), arrow(1022, 320, 1022, 220),
            arrow(580, 515, 580, 425, "cross-check", dashed=True),
        ],
        "labels": [],
    },
    {
        "name": "fig06_error_recovery", "title": "Retained error and recovery behavior",
        "nodes": [
            node(50, 80, 240, 130, "Eligible events", ["state timeout (highest)", "sideband protocol", "local fatal"], "red"),
            node(360, 80, 260, 130, "Error manager", ["accept one event", "retain pending request", "bound entry latency"], "gold"),
            node(700, 80, 220, 130, "TRAINERROR", ["stable cause", "saturating event count", "clear protected here"], "red"),
            node(985, 80, 165, 130, "CSR view", ["cause", "count", "pending"], "green"),
            node(360, 330, 260, 115, "Entry handshake", ["immediate or acknowledged", "manager timeout fallback"], "gold2"),
            node(700, 330, 220, 115, "Recovery route", ["return to RESET", "clear only when allowed"], "blue"),
            node(360, 535, 560, 75, "SVA invariants", ["pending holds request  |  entry is bounded  |  log is stable  |  illegal clear is ignored"], "purple", dashed=True),
        ],
        "arrows": [
            arrow(290, 145, 360, 145, "fixed priority"), arrow(620, 145, 700, 145, "request"),
            arrow(920, 145, 985, 145, "read-only status"),
            arrow(490, 210, 490, 330),
            arrow(620, 385, 810, 210, "entered", waypoints=[(660, 385), (660, 245), (810, 245)]),
            arrow(810, 210, 810, 330, "recover", dashed=True),
            arrow(810, 445, 810, 535, "checked", dashed=True),
        ],
        "labels": [label(55, 265, "Priority is deterministic when events coincide", 15, "bold", "start")],
    },
    {
        "name": "fig07_verification", "title": "Layered verification and evidence flow",
        "nodes": [
            node(45, 75, 220, 120, "Scenario generator", ["9 guaranteed classes", "fixed-seed variations", "backpressure + faults"], "blue"),
            node(45, 270, 220, 120, "Directed suites", ["controller / sideband", "LFSR / error manager", "FPGA CSR wrapper"], "blue"),
            node(330, 75, 260, 315, "DUT", ["LTSM controller", "sideband sequencer", "LFSR engine", "error manager", "CSR wrapper"], "gold", size=19),
            node(660, 75, 230, 120, "Interface monitor", ["requests / responses", "samples / state", "error status"], "gold2"),
            node(660, 270, 230, 120, "SVA", ["safety invariants", "bounded entry", "phase ordering"], "purple"),
            node(955, 75, 200, 150, "Independent predictor", ["message order", "23-bit lane LFSR", "threshold + cause"], "green"),
            node(955, 270, 200, 120, "Explicit coverage", ["scenario bins", "phase/gap/corrupt", "cross counters"], "green"),
            node(330, 500, 825, 90, "Release evidence", ["zero accepted-log errors/fatals/assertion failures  |  fixed seeds  |  qualified Quartus reports"], "gray", dashed=True),
        ],
        "arrows": [
            arrow(265, 135, 330, 135), arrow(265, 330, 330, 330),
            arrow(590, 135, 660, 135), arrow(590, 330, 660, 330),
            arrow(890, 135, 955, 135), arrow(890, 330, 955, 330),
            arrow(1055, 225, 1055, 270, "compare + sample"),
            arrow(1055, 390, 1055, 500), arrow(775, 390, 775, 500),
            arrow(460, 390, 460, 500),
        ],
        "labels": [label(600, 620, "Starter-license boundary: explicit sampled counters are reported; native UCDB/code-coverage closure is not claimed", 15, "bold")],
    },
    {
        "name": "fig08_fpga_results", "title": "Qualified FPGA implementation evidence",
        "nodes": [
            node(60, 80, 480, 230, "Wide core top — negative result", ["Mapping: 763 logic elements", "505 registers", "151 external pins", "Fitter: FAILED at 151 / 151 pins", "No successful-fit timing claim"], "red", size=19),
            node(660, 80, 480, 230, "Compact CSR wrapper — fitted result", ["824 / 24,624 logic elements (3%)", "505 registers", "119 / 151 pins (79%)", "Fitter: SUCCESS; zero virtual pins", "Target: Cyclone 10 LP 10CL025YU256C8G"], "green", size=19),
            node(660, 365, 480, 140, "Internal-clock timing", ["80 MHz (12.5 ns constraint)", "worst setup slack: +1.013 ns", "worst hold slack: +0.179 ns", "reported negative slack: 0"], "gold"),
            node(60, 365, 480, 140, "Why the wrapper changes feasibility", ["Wide debug/status buses consume package pins", "CSR serializes diagnostics into byte reads", "Logic cost rises slightly; pin demand falls by 32"], "gold2"),
            node(60, 560, 1080, 65, "Qualification", ["No board pin locations or external I/O delays → internal timing evidence only; not board closure, ASIC PPA, or UCIe PHY performance"], "gray", dashed=True, size=17),
        ],
        "arrows": [arrow(540, 195, 660, 195, "replace wide diagnostics with CSR", dashed=True)],
        "labels": [],
    },
]


def svg_text(parts, x, y, lines, size, weight="normal", anchor="middle", color=None, gap=None):
    color = color or P["ink"]
    gap = gap or int(size * 1.3)
    for i, line_text in enumerate(lines):
        safe = html.escape(line_text)
        parts.append(
            f'<text x="{x}" y="{y + i * gap}" text-anchor="{anchor}" '
            f'font-family="Arial, Helvetica, sans-serif" font-size="{size}" '
            f'font-weight="{weight}" fill="{color}">{safe}</text>'
        )


def build_svg(fig):
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
        '<defs><marker id="arrow" markerWidth="10" markerHeight="8" refX="9" refY="4" orient="auto" markerUnits="strokeWidth"><path d="M0,0 L10,4 L0,8 Z" fill="#172033"/></marker></defs>',
        f'<rect width="{W}" height="{H}" fill="{P["bg"]}"/>',
        f'<text x="{W/2}" y="38" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="25" font-weight="bold" fill="{P["ink"]}">{html.escape(fig["title"])}</text>',
    ]
    for x in fig.get("lifelines", []):
        parts.append(f'<line x1="{x}" y1="130" x2="{x}" y2="520" stroke="{P["muted"]}" stroke-width="2" stroke-dasharray="7 6"/>')
    for n in fig["nodes"]:
        dash = ' stroke-dasharray="8 6"' if n["dashed"] else ""
        parts.append(f'<rect x="{n["x"]}" y="{n["y"]}" width="{n["w"]}" height="{n["h"]}" rx="12" fill="{n["fill"]}" stroke="{n["stroke"]}" stroke-width="2.5"{dash}/>')
        cx = n["x"] + n["w"] / 2
        title_y = n["y"] + 29
        svg_text(parts, cx, title_y, [n["title"]], n["size"], "bold")
        if n["lines"]:
            line_y = title_y + 28
            svg_text(parts, cx, line_y, n["lines"], max(13, n["size"] - 3), "normal", gap=max(19, n["size"] + 2))
    for a in fig["arrows"]:
        dash = ' stroke-dasharray="8 6"' if a["dashed"] else ""
        pts = [(a["x1"], a["y1"]), *a["waypoints"], (a["x2"], a["y2"])]
        path = " ".join(("M" if i == 0 else "L") + f" {x} {y}" for i, (x, y) in enumerate(pts))
        parts.append(f'<path d="{path}" fill="none" stroke="{a["color"]}" stroke-width="2.5" marker-end="url(#arrow)"{dash}/>')
        if a["label"]:
            mx = sum(p[0] for p in pts) / len(pts)
            my = sum(p[1] for p in pts) / len(pts) - 8
            tw = max(70, len(a["label"]) * 8)
            parts.append(f'<rect x="{mx-tw/2}" y="{my-15}" width="{tw}" height="21" fill="{P["bg"]}"/>')
            svg_text(parts, mx, my, [a["label"]], 14, "bold")
    for t in fig.get("labels", []):
        svg_text(parts, t["x"], t["y"], [t["text"]], t["size"], t["weight"], t["anchor"], t["color"])
    parts.append("</svg>")
    return "\n".join(parts)


def drawio_value(n):
    title = f"<b>{html.escape(n['title'])}</b>"
    body = "<br>".join(html.escape(x) for x in n["lines"])
    return title + ("<br>" + body if body else "")


def build_drawio(fig, path):
    mxfile = Element("mxfile", host="app.diagrams.net", modified="2026-09-01T00:00:00.000Z", agent="journal/tools/build_figures.py", version="24.7.17")
    diagram = SubElement(mxfile, "diagram", id=fig["name"], name="Page-1")
    model = SubElement(diagram, "mxGraphModel", dx="1200", dy="675", grid="1", gridSize="10", guides="1", tooltips="1", connect="1", arrows="1", fold="1", page="1", pageScale="1", pageWidth=str(W), pageHeight=str(H), math="0", shadow="0", background=P["bg"])
    root = SubElement(model, "root")
    SubElement(root, "mxCell", id="0")
    SubElement(root, "mxCell", id="1", parent="0")
    title_cell = SubElement(root, "mxCell", id="title", value=fig["title"], style="text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;fontFamily=Arial;fontSize=25;fontStyle=1;fontColor=#172033;", vertex="1", parent="1")
    SubElement(title_cell, "mxGeometry", x="200", y="5", width="800", height="40", **{"as": "geometry"})
    node_ids = []
    for i, n in enumerate(fig["nodes"], 1):
        nid = f"n{i}"
        node_ids.append(nid)
        dashed = "1" if n["dashed"] else "0"
        style = f"rounded=1;whiteSpace=wrap;html=1;fillColor={n['fill']};strokeColor={n['stroke']};strokeWidth=2;fontFamily=Arial;fontSize={n['size']};fontColor=#172033;dashed={dashed};spacing=8;"
        cell = SubElement(root, "mxCell", id=nid, value=drawio_value(n), style=style, vertex="1", parent="1")
        SubElement(cell, "mxGeometry", x=str(n["x"]), y=str(n["y"]), width=str(n["w"]), height=str(n["h"]), **{"as": "geometry"})
    for i, a in enumerate(fig["arrows"], 1):
        dashed = "1" if a["dashed"] else "0"
        style = f"edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=block;endFill=1;strokeWidth=2;strokeColor={a['color']};dashed={dashed};fontFamily=Arial;fontSize=14;fontStyle=1;labelBackgroundColor={P['bg']};"
        cell = SubElement(root, "mxCell", id=f"e{i}", value=a["label"], style=style, edge="1", parent="1")
        geo = SubElement(cell, "mxGeometry", relative="1", **{"as": "geometry"})
        SubElement(geo, "mxPoint", x=str(a["x1"]), y=str(a["y1"]), **{"as": "sourcePoint"})
        SubElement(geo, "mxPoint", x=str(a["x2"]), y=str(a["y2"]), **{"as": "targetPoint"})
        if a["waypoints"]:
            arr = SubElement(geo, "Array", **{"as": "points"})
            for x, y in a["waypoints"]:
                SubElement(arr, "mxPoint", x=str(x), y=str(y))
    for i, t in enumerate(fig.get("labels", []), 1):
        align = {"start": "left", "middle": "center", "end": "right"}[t["anchor"]]
        style = f"text;html=1;align={align};verticalAlign=middle;resizable=0;points=[];autosize=1;fontFamily=Arial;fontSize={t['size']};fontStyle={'1' if t['weight']=='bold' else '0'};fontColor={t['color']};"
        cell = SubElement(root, "mxCell", id=f"l{i}", value=html.escape(t["text"]), style=style, vertex="1", parent="1")
        SubElement(cell, "mxGeometry", x=str(t["x"] - (0 if align == "left" else 350)), y=str(t["y"]-22), width="700", height="30", **{"as": "geometry"})
    ElementTree(mxfile).write(path, encoding="utf-8", xml_declaration=True)


def build_png(svg_path, png_path):
    """Rasterize with the bundled sharp/libvips runtime (no Cairo dependency)."""
    node_bin = Path(r"C:\Users\dell\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe")
    node_modules = Path(r"C:\Users\dell\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules")
    if not node_bin.exists():
        node_bin = Path("node")
    script = "const sharp=require('sharp'); sharp(process.argv[1]).resize(1600,900).png().toFile(process.argv[2]).catch(e=>{console.error(e);process.exit(1)});"
    env = os.environ.copy()
    env["NODE_PATH"] = str(node_modules)
    subprocess.run([str(node_bin), "-e", script, str(svg_path), str(png_path)], check=True, env=env)


def pdf_y(y):
    return H - y


def set_pdf_color(c, hex_color, stroke=False):
    value = hex_color.lstrip("#")
    rgb = tuple(int(value[i:i+2], 16) / 255 for i in (0, 2, 4))
    (c.setStrokeColorRGB if stroke else c.setFillColorRGB)(*rgb)


def pdf_text(c, x, y, lines, size, weight="normal", anchor="middle", color=None, gap=None):
    set_pdf_color(c, color or P["ink"])
    c.setFont("Helvetica-Bold" if weight == "bold" else "Helvetica", size)
    gap = gap or int(size * 1.3)
    for i, item in enumerate(lines):
        yy = pdf_y(y + i * gap)
        if anchor == "start":
            c.drawString(x, yy, item)
        elif anchor == "end":
            c.drawRightString(x, yy, item)
        else:
            c.drawCentredString(x, yy, item)


def pdf_arrow(c, a):
    set_pdf_color(c, a["color"], stroke=True)
    set_pdf_color(c, a["color"])
    c.setLineWidth(2.5)
    c.setDash(8, 6) if a["dashed"] else c.setDash()
    pts = [(a["x1"], a["y1"]), *a["waypoints"], (a["x2"], a["y2"])]
    path = c.beginPath()
    path.moveTo(pts[0][0], pdf_y(pts[0][1]))
    for x, y in pts[1:]:
        path.lineTo(x, pdf_y(y))
    c.drawPath(path, stroke=1, fill=0)
    x1, y1 = pts[-2]
    x2, y2 = pts[-1]
    angle = math.atan2(-(y2-y1), x2-x1)
    length, half = 12, 5
    p1 = (x2, pdf_y(y2))
    p2 = (x2 - length*math.cos(angle) + half*math.sin(angle), pdf_y(y2) - length*math.sin(angle) - half*math.cos(angle))
    p3 = (x2 - length*math.cos(angle) - half*math.sin(angle), pdf_y(y2) - length*math.sin(angle) + half*math.cos(angle))
    head = c.beginPath()
    head.moveTo(*p1); head.lineTo(*p2); head.lineTo(*p3); head.close()
    c.drawPath(head, stroke=0, fill=1)
    c.setDash()
    if a["label"]:
        mx = sum(p[0] for p in pts) / len(pts)
        my = sum(p[1] for p in pts) / len(pts) - 8
        tw = max(70, len(a["label"]) * 8)
        set_pdf_color(c, P["bg"])
        c.rect(mx-tw/2, pdf_y(my)+2, tw, 21, fill=1, stroke=0)
        pdf_text(c, mx, my, [a["label"]], 14, "bold")


def build_pdf(fig, path):
    c = canvas.Canvas(str(path), pagesize=(W, H), pageCompression=1)
    set_pdf_color(c, P["bg"])
    c.rect(0, 0, W, H, fill=1, stroke=0)
    pdf_text(c, W/2, 38, [fig["title"]], 25, "bold")
    for x in fig.get("lifelines", []):
        set_pdf_color(c, P["muted"], stroke=True)
        c.setLineWidth(2); c.setDash(7, 6)
        c.line(x, pdf_y(130), x, pdf_y(520)); c.setDash()
    for n in fig["nodes"]:
        set_pdf_color(c, n["fill"])
        set_pdf_color(c, n["stroke"], stroke=True)
        c.setLineWidth(2.5); c.setDash(8, 6) if n["dashed"] else c.setDash()
        c.roundRect(n["x"], H-n["y"]-n["h"], n["w"], n["h"], 12, fill=1, stroke=1)
        c.setDash()
        cx = n["x"] + n["w"] / 2
        title_y = n["y"] + 29
        pdf_text(c, cx, title_y, [n["title"]], n["size"], "bold")
        if n["lines"]:
            pdf_text(c, cx, title_y+28, n["lines"], max(13, n["size"]-3), gap=max(19, n["size"]+2))
    for a in fig["arrows"]:
        pdf_arrow(c, a)
    for t in fig.get("labels", []):
        pdf_text(c, t["x"], t["y"], [t["text"]], t["size"], t["weight"], t["anchor"], t["color"])
    c.showPage(); c.save()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--no-pdf", action="store_true", help="skip PDF export during visual preflight")
    args = parser.parse_args()
    for directory in (SOURCE, SVG, PDF, PNG):
        directory.mkdir(parents=True, exist_ok=True)
    for fig in FIGURES:
        svg_path = SVG / f"{fig['name']}.svg"
        png_path = PNG / f"{fig['name']}.png"
        pdf_path = PDF / f"{fig['name']}.pdf"
        drawio_path = SOURCE / f"{fig['name']}.drawio"
        svg_text_data = build_svg(fig)
        svg_path.write_text(svg_text_data, encoding="utf-8")
        build_drawio(fig, drawio_path)
        build_png(svg_path, png_path)
        if not args.no_pdf:
            build_pdf(fig, pdf_path)
        print(fig["name"])


if __name__ == "__main__":
    main()
