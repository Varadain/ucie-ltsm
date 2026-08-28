#!/usr/bin/env python3
"""Render reviewable SVG waveform figures from the directed-test VCD.

The script intentionally uses only the Python standard library so the release
evidence can be regenerated without a waveform GUI or third-party package.
"""

from __future__ import annotations

import argparse
import html
from pathlib import Path


STATE_NAMES = {
    "0000": "RESET",
    "0001": "SBINIT",
    "0010": "MBINIT",
    "0011": "MBTRAIN",
    "0100": "LINKINIT",
    "0101": "ACTIVE",
    "0110": "PHYRETRAIN",
    "0111": "TRAINERROR",
    "1000": "L1/L2",
}
MBINIT_NAMES = {
    "000": "PARAM",
    "001": "CAL",
    "010": "RCLK",
    "011": "RVAL",
    "100": "REVMB",
    "101": "RMB",
}
MBTRAIN_NAMES = {
    "0000": "VVREF",
    "0001": "DVREF",
    "0010": "SPDIDL",
    "0011": "TXCAL",
    "0100": "RXCAL",
    "0101": "VTC",
    "0110": "VTVREF",
    "0111": "DTC1",
    "1000": "DTVREF",
    "1001": "RXDSK",
    "1010": "DTC2",
    "1011": "LSPD",
    "1100": "REPAIR",
}

COLORS = {
    "RESET": "#64748b",
    "SBINIT": "#0f766e",
    "MBINIT": "#2563eb",
    "MBTRAIN": "#7c3aed",
    "LINKINIT": "#b45309",
    "ACTIVE": "#15803d",
    "PHYRETRAIN": "#c2410c",
    "TRAINERROR": "#b91c1c",
    "L1/L2": "#475569",
}
MBINIT_COLORS = {
    "000": "#2563eb",
    "001": "#0284c7",
    "010": "#0891b2",
    "011": "#0f766e",
    "100": "#a16207",
    "101": "#c2410c",
}
MBTRAIN_COLORS = {
    "0000": "#7c3aed",
    "0001": "#9333ea",
    "0010": "#2563eb",
    "0011": "#0284c7",
    "0100": "#0891b2",
    "0101": "#0f766e",
    "0110": "#15803d",
    "0111": "#4d7c0f",
    "1000": "#a16207",
    "1001": "#c2410c",
    "1010": "#be123c",
    "1011": "#a21caf",
    "1100": "#475569",
}
SCALAR_COLORS = {
    "phase_done": "#2563eb",
    "rdi_active": "#0f766e",
    "link_up": "#15803d",
    "retrain_req": "#c2410c",
    "fatal_error": "#b91c1c",
    "error_handshake_done": "#a21caf",
}

SIGNAL_GUIDE = "../../../docs/02_ltssm/signals.md"


def parse_vcd(path: Path):
    variables: dict[str, tuple[str, int]] = {}
    changes: dict[str, list[tuple[int, str]]] = {}
    current_time = 0
    in_values = False

    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.strip()
        if line.startswith("$var"):
            parts = line.split()
            width = int(parts[2])
            identifier = parts[3]
            name = parts[4]
            variables[identifier] = (name, width)
            changes[name] = []
        elif line == "$enddefinitions $end":
            in_values = True
        elif in_values and line.startswith("#"):
            current_time = int(line[1:])
        elif in_values and line and not line.startswith("$"):
            if line[0] in "01xXzZ":
                value, identifier = line[0].lower(), line[1:]
            elif line[0] in "bB":
                value, identifier = line[1:].split(maxsplit=1)
                value = value.lower()
            else:
                continue
            if identifier in variables:
                name, width = variables[identifier]
                value = value.zfill(width)
                series = changes[name]
                if series and series[-1][0] == current_time:
                    series[-1] = (current_time, value)
                elif not series or series[-1][1] != value:
                    series.append((current_time, value))
    return variables, changes


def value_at(series: list[tuple[int, str]], time_ps: int) -> str:
    value = "x"
    for change_time, changed_value in series:
        if change_time > time_ps:
            break
        value = changed_value
    return value


def segments(series: list[tuple[int, str]], start_ps: int, end_ps: int):
    points = [(start_ps, value_at(series, start_ps))]
    points.extend((t, v) for t, v in series if start_ps < t < end_ps)
    return [(t, points[i + 1][0] if i + 1 < len(points) else end_ps, v)
            for i, (t, v) in enumerate(points)]


def merged_segments(changes, signal, start_ps, end_ps, qualifier=None):
    cut_points = {start_ps, end_ps}
    for t, _ in changes[signal]:
        if start_ps < t < end_ps:
            cut_points.add(t)
    if qualifier:
        qualifier_signal, _ = qualifier
        for t, _ in changes[qualifier_signal]:
            if start_ps < t < end_ps:
                cut_points.add(t)
    ordered = sorted(cut_points)
    result = []
    for start, end in zip(ordered, ordered[1:]):
        value = value_at(changes[signal], start)
        if qualifier:
            qualifier_signal, required_value = qualifier
            if value_at(changes[qualifier_signal], start) != required_value:
                value = "inactive"
        if result and result[-1][2] == value:
            result[-1] = (result[-1][0], end, value)
        else:
            result.append((start, end, value))
    return result


def render_figure(changes, output: Path, title: str, subtitle: str,
                  start_ns: int, end_ns: int, rows):
    width = 1400
    left, right, top, row_height = 210, 34, 132, 58
    plot_width = width - left - right
    height = top + len(rows) * row_height + 92
    start_ps, end_ps = start_ns * 1000, end_ns * 1000

    def x(time_ps: int) -> float:
        return left + ((time_ps - start_ps) / (end_ps - start_ps)) * plot_width

    svg = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">',
        f'<title id="title">{html.escape(title)}</title>',
        f'<desc id="desc">{html.escape(subtitle)} Generated from the directed Questa VCD.</desc>',
        '<style>',
        'text{font-family:Inter,Segoe UI,Arial,sans-serif;fill:#172033}',
        '.title{font-size:24px;font-weight:700}.subtitle{font-size:14px;fill:#536179}',
        '.label{font-size:14px;font-weight:600}.tick{font-size:12px;fill:#64748b}',
        '.guide{font-size:13px;font-weight:600;fill:#2563eb;text-decoration:underline}',
        '.bus{font-size:10px;font-weight:600;fill:#fff}.bus-dark{font-size:10px;font-weight:600;fill:#172033}',
        '.grid{stroke:#dbe2ea;stroke-width:1}.axis{stroke:#94a3b8;stroke-width:1}',
        '.digital{fill:none;stroke-width:2.5;stroke-linejoin:miter}',
        '</style>',
        '<rect width="100%" height="100%" fill="#ffffff"/>',
        f'<text class="title" x="24" y="34">{html.escape(title)}</text>',
        f'<text class="subtitle" x="24" y="60">{html.escape(subtitle)}</text>',
        '<text class="subtitle" x="24" y="82">Source: Questa 2023.3 · verification/tb_ucie_ltsm.sv · timescale 1 ps</text>',
        f'<a href="{SIGNAL_GUIDE}#waveform-signal-guide"><text class="guide" x="1376" y="82" text-anchor="end">Signal definitions and functionality ↗</text></a>',
    ]

    tick_step = 10 if end_ns - start_ns <= 80 else 20
    first_tick = ((start_ns + tick_step - 1) // tick_step) * tick_step
    for tick in range(first_tick, end_ns + 1, tick_step):
        tick_x = x(tick * 1000)
        svg.append(f'<line class="grid" x1="{tick_x:.2f}" y1="{top - 18}" x2="{tick_x:.2f}" y2="{top + len(rows) * row_height - 10}"/>')
        svg.append(f'<text class="tick" x="{tick_x:.2f}" y="{top - 27}" text-anchor="middle">{tick}</text>')
    svg.append(f'<text class="tick" x="{left + plot_width / 2:.2f}" y="{height - 22}" text-anchor="middle">simulation time (ns)</text>')

    for index, row in enumerate(rows):
        center = top + index * row_height + 18
        row_color = row.get("color", SCALAR_COLORS.get(row["signal"], "#172033"))
        label_text = f'<text class="label" style="fill:{row_color};text-decoration:underline" x="{left - 18}" y="{center + 5}" text-anchor="end">{html.escape(row["label"])}</text>'
        if row.get("href"):
            label_text = f'<a href="{html.escape(row["href"], quote=True)}">{label_text}</a>'
        svg.append(label_text)
        svg.append(f'<line class="axis" x1="{left}" y1="{center}" x2="{left + plot_width}" y2="{center}"/>')
        if row["kind"] == "scalar":
            high, low = center - 13, center + 13
            row_segments = segments(changes[row["signal"]], start_ps, end_ps)
            path = []
            for seg_index, (seg_start, seg_end, value) in enumerate(row_segments):
                y = high if value == "1" else low
                if seg_index == 0:
                    path.append(f'M {x(seg_start):.2f} {y}')
                else:
                    path.append(f'V {y}')
                path.append(f'H {x(seg_end):.2f}')
            svg.append(f'<path class="digital" style="stroke:{row_color}" d="{" ".join(path)}"/>')
            svg.append(f'<text class="tick" style="fill:{row_color}" x="{left + 5}" y="{high - 4}">1</text>')
            svg.append(f'<text class="tick" style="fill:{row_color}" x="{left + 5}" y="{low - 4}">0</text>')
        else:
            qualifier = row.get("qualifier")
            row_segments = merged_segments(changes, row["signal"], start_ps, end_ps, qualifier)
            name_map = row["names"]
            for seg_start, seg_end, value in row_segments:
                seg_x, seg_w = x(seg_start), x(seg_end) - x(seg_start)
                if value == "inactive":
                    fill, label, text_class = "#eef2f6", "—", "bus-dark"
                else:
                    label = name_map.get(value, value)
                    fill = row.get("palette", {}).get(value, COLORS.get(label, row.get("fill", "#334155")))
                    text_class = "bus"
                svg.append(f'<rect x="{seg_x:.2f}" y="{center - 16}" width="{max(seg_w, 0):.2f}" height="32" fill="{fill}" stroke="#ffffff"/>')
                if seg_w > max(24, len(label) * 5.2):
                    svg.append(f'<text class="{text_class}" x="{seg_x + seg_w / 2:.2f}" y="{center + 4}" text-anchor="middle">{html.escape(label)}</text>')

    svg.append(f'<rect x="{left}" y="{top - 18}" width="{plot_width}" height="{len(rows) * row_height - 2}" fill="none" stroke="#94a3b8"/>')
    svg.append('</svg>')
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(svg) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("vcd", type=Path, nargs="?", default=Path("build/waves/directed_training.vcd"))
    parser.add_argument("--output-dir", type=Path, default=Path("assets/waveforms/v0.1-basic-ltssm"))
    args = parser.parse_args()
    _, changes = parse_vcd(args.vcd)

    render_figure(
        changes,
        args.output_dir / "nominal-training.svg",
        "v0.1 nominal link training",
        "RESET residence through SBINIT, MBINIT, MBTRAIN, LINKINIT, and ACTIVE",
        1000,
        1245,
        [
            {"kind": "bus", "signal": "state", "label": "LTSM state", "names": STATE_NAMES, "color": "#475569", "href": f"{SIGNAL_GUIDE}#wave-state-output"},
            {"kind": "bus", "signal": "mbi", "label": "MBINIT substate", "names": MBINIT_NAMES, "palette": MBINIT_COLORS, "qualifier": ("state", "0010"), "color": "#2563eb", "href": f"{SIGNAL_GUIDE}#wave-mbinit-output"},
            {"kind": "bus", "signal": "mbt", "label": "MBTRAIN substate", "names": MBTRAIN_NAMES, "palette": MBTRAIN_COLORS, "qualifier": ("state", "0011"), "color": "#7c3aed", "href": f"{SIGNAL_GUIDE}#wave-mbtrain-output"},
            {"kind": "scalar", "signal": "phase_done", "label": "phase_done_i", "href": f"{SIGNAL_GUIDE}#wave-phase-done"},
            {"kind": "scalar", "signal": "rdi_active", "label": "rdi_active_i", "href": f"{SIGNAL_GUIDE}#wave-rdi-active"},
            {"kind": "scalar", "signal": "link_up", "label": "link_up_o", "href": f"{SIGNAL_GUIDE}#wave-link-up"},
        ],
    )
    render_figure(
        changes,
        args.output_dir / "retrain-error-recovery.svg",
        "v0.1 retrain and fatal-error recovery",
        "ACTIVE to PHYRETRAIN, MBTRAIN.SPEEDIDLE, TRAINERROR, and RESET",
        1210,
        1280,
        [
            {"kind": "bus", "signal": "state", "label": "LTSM state", "names": STATE_NAMES, "color": "#475569", "href": f"{SIGNAL_GUIDE}#wave-state-output"},
            {"kind": "bus", "signal": "mbt", "label": "MBTRAIN substate", "names": MBTRAIN_NAMES, "palette": MBTRAIN_COLORS, "qualifier": ("state", "0011"), "color": "#7c3aed", "href": f"{SIGNAL_GUIDE}#wave-mbtrain-output"},
            {"kind": "scalar", "signal": "retrain_req", "label": "retrain_req_i", "href": f"{SIGNAL_GUIDE}#wave-retrain-request"},
            {"kind": "scalar", "signal": "phase_done", "label": "phase_done_i", "href": f"{SIGNAL_GUIDE}#wave-phase-done"},
            {"kind": "scalar", "signal": "fatal_error", "label": "fatal_error_i", "href": f"{SIGNAL_GUIDE}#wave-fatal-error"},
            {"kind": "scalar", "signal": "error_handshake_done", "label": "error_handshake_done_i", "href": f"{SIGNAL_GUIDE}#wave-error-handshake"},
            {"kind": "scalar", "signal": "link_up", "label": "link_up_o", "href": f"{SIGNAL_GUIDE}#wave-link-up"},
        ],
    )


if __name__ == "__main__":
    main()
