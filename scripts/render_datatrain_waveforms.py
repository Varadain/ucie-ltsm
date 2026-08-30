#!/usr/bin/env python3
"""Render reviewed v0.3 DATATRAINCENTER1 waveform evidence."""

from __future__ import annotations

import argparse
import html
from pathlib import Path

from render_waveforms import parse_vcd, segments


SIGNAL_GUIDE = "../../../docs/02_ltssm/signals.md"
SOURCE = "verification/tb_ucie_lfsr_training_engine.sv"
COLORS = {
    "start": "#7c3aed",
    "abort": "#be123c",
    "rx_valid": "#0284c7",
    "tx_valid": "#2563eb",
    "busy": "#475569",
    "done": "#f59e0b",
    "pass": "#16a34a",
    "threshold": "#a21caf",
    "errors": "#dc2626",
    "tx_pattern": "#2563eb",
    "rx_pattern": "#0f766e",
}


def value_at(series: list[tuple[int, str]], time_ps: int) -> str:
    value = "x"
    for change_time, changed_value in series:
        if change_time > time_ps:
            break
        value = changed_value
    return value


def bus_segments(series: list[tuple[int, str]], start_ps: int, end_ps: int):
    points = [(start_ps, value_at(series, start_ps))]
    points.extend((time, value) for time, value in series if start_ps < time < end_ps)
    return [
        (time, points[index + 1][0] if index + 1 < len(points) else end_ps, value)
        for index, (time, value) in enumerate(points)
    ]


def format_bus(signal: str, value: str) -> str:
    if not value or any(bit not in "01" for bit in value):
        return value.upper()
    number = int(value, 2)
    if signal in {"errors", "threshold"}:
        return str(number)
    return f"0x{number:04X}"


def render(
    changes,
    output: Path,
    title: str,
    subtitle: str,
    start_ns: int,
    end_ns: int,
    rows,
    bands,
) -> None:
    width = 1600
    left, right, top, row_height = 250, 38, 154, 58
    plot_width = width - left - right
    height = top + len(rows) * row_height + 104
    start_ps, end_ps = start_ns * 1000, end_ns * 1000

    def x(time_ps: int) -> float:
        return left + (time_ps - start_ps) * plot_width / (end_ps - start_ps)

    svg = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">',
        f'<title id="title">{html.escape(title)}</title>',
        f'<desc id="desc">{html.escape(subtitle)} Generated from a self-checking Questa VCD.</desc>',
        '<style>text{font-family:Inter,Segoe UI,Arial,sans-serif;fill:#172033}.title{font-size:25px;font-weight:700}.subtitle{font-size:14px;fill:#536179}.label{font-size:14px;font-weight:650}.tick{font-size:12px;fill:#64748b}.band{font-size:12px;font-weight:700}.bus{font-size:11px;font-weight:650;fill:#fff}.guide{font-size:13px;font-weight:650;fill:#2563eb;text-decoration:underline}.digital{fill:none;stroke-width:2.6;stroke-linejoin:miter}.grid{stroke:#dbe2ea;stroke-width:1}</style>',
        '<rect width="100%" height="100%" fill="#ffffff"/>',
        f'<text class="title" x="26" y="36">{html.escape(title)}</text>',
        f'<text class="subtitle" x="26" y="62">{html.escape(subtitle)}</text>',
        f'<text class="subtitle" x="26" y="84">Source: Questa 2023.3 · {SOURCE} · timescale 1 ps</text>',
        f'<a href="{SIGNAL_GUIDE}#v03-training-signal-guide"><text class="guide" x="1572" y="84" text-anchor="end">Signal definitions and functionality ↗</text></a>',
    ]

    for start, end, label, fill, text_fill in bands:
        band_x, band_w = x(start * 1000), x(end * 1000) - x(start * 1000)
        svg.append(f'<rect x="{band_x:.2f}" y="102" width="{band_w:.2f}" height="28" rx="5" fill="{fill}"/>')
        if band_w > len(label) * 7:
            svg.append(f'<text class="band" x="{band_x + band_w / 2:.2f}" y="121" text-anchor="middle" style="fill:{text_fill}">{html.escape(label)}</text>')

    span = end_ns - start_ns
    tick_step = 50 if span > 300 else 20
    first_tick = ((start_ns + tick_step - 1) // tick_step) * tick_step
    for tick in range(first_tick, end_ns + 1, tick_step):
        tick_x = x(tick * 1000)
        svg.append(f'<line class="grid" x1="{tick_x:.2f}" y1="136" x2="{tick_x:.2f}" y2="{top + len(rows) * row_height - 10}"/>')
        svg.append(f'<text class="tick" x="{tick_x:.2f}" y="148" text-anchor="middle">{tick}</text>')

    for index, row in enumerate(rows):
        signal, label, kind, anchor = row
        center = top + index * row_height + 22
        color = COLORS[signal]
        background = "#f8fafc" if index % 2 == 0 else "#ffffff"
        svg.append(f'<rect x="{left}" y="{center - 25}" width="{plot_width}" height="50" fill="{background}"/>')
        svg.append(f'<a href="{SIGNAL_GUIDE}#{anchor}"><text class="label" x="{left - 18}" y="{center + 5}" text-anchor="end" style="fill:{color}">{html.escape(label)}</text></a>')
        svg.append(f'<line x1="{left}" y1="{center}" x2="{left + plot_width}" y2="{center}" stroke="#94a3b8"/>')
        if kind == "scalar":
            high, low = center - 13, center + 13
            path = []
            for seg_index, (seg_start, seg_end, value) in enumerate(segments(changes[signal], start_ps, end_ps)):
                y = high if value == "1" else low
                if seg_index == 0:
                    path.append(f'M {x(seg_start):.2f} {y}')
                else:
                    path.append(f'V {y}')
                path.append(f'H {x(seg_end):.2f}')
            svg.append(f'<path class="digital" style="stroke:{color}" d="{" ".join(path)}"/>')
        else:
            for seg_start, seg_end, value in bus_segments(changes[signal], start_ps, end_ps):
                seg_x, seg_w = x(seg_start), x(seg_end) - x(seg_start)
                display = format_bus(signal, value)
                svg.append(f'<rect x="{seg_x:.2f}" y="{center - 16}" width="{max(seg_w, 0):.2f}" height="32" fill="{color}" stroke="#ffffff"/>')
                minimum_label_width = 18 if signal in {"errors", "threshold"} else max(48, len(display) * 10)
                if seg_w > minimum_label_width:
                    svg.append(f'<text class="bus" x="{seg_x + seg_w / 2:.2f}" y="{center + 4}" text-anchor="middle">{html.escape(display)}</text>')

    svg.append(f'<rect x="{left}" y="{top - 3}" width="{plot_width}" height="{len(rows) * row_height - 2}" fill="none" stroke="#94a3b8"/>')
    svg.append(f'<text class="tick" x="{left + plot_width / 2:.2f}" y="{height - 24}" text-anchor="middle">simulation time (ns)</text>')
    svg.append('</svg>')
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(svg) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("vcd", type=Path, nargs="?", default=Path("build/waves/datatrain_lfsr.vcd"))
    parser.add_argument("--output-dir", type=Path, default=Path("assets/waveforms/v0.3-advanced-training"))
    args = parser.parse_args()
    _, changes = parse_vcd(args.vcd)

    render(
        changes,
        args.output_dir / "pattern-progression.svg",
        "v0.3 LFSR pattern progression",
        "Eight accepted samples with two-cycle receive gaps; TX and RX match for a clean attempt",
        20,
        285,
        [
            ("start", "start_i", "scalar", "wave-train-start"),
            ("busy", "train_busy_o", "scalar", "wave-train-busy"),
            ("tx_valid", "train_tx_valid_o", "scalar", "wave-train-tx-valid"),
            ("tx_pattern", "train_tx_pattern_o", "bus", "wave-train-tx-pattern"),
            ("rx_valid", "train_rx_valid_i", "scalar", "wave-train-rx-valid"),
            ("rx_pattern", "train_rx_pattern_i", "bus", "wave-train-rx-pattern"),
            ("errors", "train_error_count_o", "bus", "wave-train-error-count"),
            ("done", "train_done_o", "scalar", "wave-train-done"),
            ("pass", "train_pass_o", "scalar", "wave-train-pass"),
        ],
        [(20, 285, "CLEAN ATTEMPT · 8 SAMPLES · 2-CYCLE GAPS", "#dcfce7", "#166534")],
    )

    render(
        changes,
        args.output_dir / "threshold-and-abort.svg",
        "v0.3 strict threshold and abort behavior",
        "Clean pass, equality failure, threshold-above-count pass, and deterministic abort clearing",
        20,
        620,
        [
            ("start", "start_i", "scalar", "wave-train-start"),
            ("abort", "abort_i", "scalar", "wave-train-abort"),
            ("busy", "train_busy_o", "scalar", "wave-train-busy"),
            ("rx_valid", "train_rx_valid_i", "scalar", "wave-train-rx-valid"),
            ("threshold", "train_error_threshold_i", "bus", "wave-train-threshold"),
            ("errors", "train_error_count_o", "bus", "wave-train-error-count"),
            ("done", "train_done_o", "scalar", "wave-train-done"),
            ("pass", "train_pass_o", "scalar", "wave-train-pass"),
        ],
        [
            (20, 285, "CLEAN · PASS", "#dcfce7", "#166534"),
            (285, 385, "ERRORS = THRESHOLD · FAIL", "#fee2e2", "#991b1b"),
            (385, 565, "THRESHOLD > ERRORS · PASS", "#dbeafe", "#1e40af"),
            (565, 620, "ABORT · CLEAR", "#f3e8ff", "#6b21a8"),
        ],
    )


if __name__ == "__main__":
    main()
