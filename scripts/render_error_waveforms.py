#!/usr/bin/env python3
"""Render reviewed v0.4 error-recovery waveform evidence."""

from __future__ import annotations

import argparse
import html
from pathlib import Path

from render_waveforms import parse_vcd, segments, value_at


SIGNAL_BASE = "../../../docs/02_ltssm/signals.md#"
SIGNAL_GUIDE = SIGNAL_BASE + "v04-error-recovery-signal-guide"
SOURCE = "verification/tb_ucie_error_manager.sv"
COLORS = {
    "fatal": "#dc2626",
    "sb_error": "#ea580c",
    "state_timeout": "#a21caf",
    "ack": "#0f766e",
    "clear": "#64748b",
    "pending": "#7c3aed",
    "request": "#2563eb",
    "hs_timeout": "#b45309",
    "enter": "#be123c",
    "state": "#334155",
    "cause": "#9333ea",
    "count": "#0284c7",
    "csr_valid": "#2563eb",
    "csr_write": "#c2410c",
    "csr_ready": "#0f766e",
    "csr_addr": "#7c3aed",
    "csr_rdata": "#0284c7",
}
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
CAUSE_NAMES = {
    "000": "NONE",
    "001": "STATE TIMEOUT",
    "010": "SIDEBAND",
    "011": "LOCAL FATAL",
}
STATE_COLORS = {
    "0000": "#64748b",
    "0001": "#0f766e",
    "0010": "#2563eb",
    "0101": "#15803d",
    "0111": "#b91c1c",
}
CAUSE_COLORS = {
    "000": "#64748b",
    "001": "#a21caf",
    "010": "#ea580c",
    "011": "#dc2626",
}


def bus_segments(series: list[tuple[int, str]], start_ps: int, end_ps: int):
    points = [(start_ps, value_at(series, start_ps))]
    points.extend((time, value) for time, value in series if start_ps < time < end_ps)
    return [
        (time, points[index + 1][0] if index + 1 < len(points) else end_ps, value)
        for index, (time, value) in enumerate(points)
    ]


def render(changes, output: Path, title: str, subtitle: str, start_ns: int,
           end_ns: int, rows, bands, source: str = SOURCE) -> None:
    width = 1660
    left, right, top, row_height = 262, 42, 168, 58
    plot_width = width - left - right
    height = top + len(rows) * row_height + 102
    start_ps, end_ps = start_ns * 1000, end_ns * 1000

    def x(time_ps: int) -> float:
        return left + (time_ps - start_ps) * plot_width / (end_ps - start_ps)

    svg = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">',
        f'<title id="title">{html.escape(title)}</title>',
        f'<desc id="desc">{html.escape(subtitle)} Generated from a self-checking Questa VCD.</desc>',
        '<style>text{font-family:Inter,Segoe UI,Arial,sans-serif;fill:#172033}.title{font-size:25px;font-weight:700}.subtitle{font-size:14px;fill:#536179}.label{font-size:14px;font-weight:650}.tick{font-size:12px;fill:#64748b}.band{font-size:12px;font-weight:700}.bus{font-size:11px;font-weight:700;fill:#fff}.guide{font-size:13px;font-weight:650;fill:#2563eb;text-decoration:underline}.digital{fill:none;stroke-width:2.8;stroke-linejoin:miter}.grid{stroke:#dbe2ea;stroke-width:1}</style>',
        '<rect width="100%" height="100%" fill="#ffffff"/>',
        f'<text class="title" x="28" y="38">{html.escape(title)}</text>',
        f'<text class="subtitle" x="28" y="65">{html.escape(subtitle)}</text>',
        f'<text class="subtitle" x="28" y="90">Source: Questa 2023.3 · {html.escape(source)} · timescale 1 ps</text>',
        f'<a href="{SIGNAL_GUIDE}"><text class="guide" x="1630" y="90" text-anchor="end">Signal definitions and functionality ↗</text></a>',
    ]

    for band_start, band_end, label, fill, text_fill in bands:
        band_x = x(band_start * 1000)
        band_w = x(band_end * 1000) - band_x
        svg.append(f'<rect x="{band_x:.2f}" y="112" width="{band_w:.2f}" height="31" rx="5" fill="{fill}"/>')
        if band_w > len(label) * 7.2:
            svg.append(f'<text class="band" x="{band_x + band_w / 2:.2f}" y="133" text-anchor="middle" style="fill:{text_fill}">{html.escape(label)}</text>')

    first_tick = ((start_ns + 9) // 10) * 10
    for tick in range(first_tick, end_ns + 1, 10):
        tick_x = x(tick * 1000)
        svg.append(f'<line class="grid" x1="{tick_x:.2f}" y1="151" x2="{tick_x:.2f}" y2="{top + len(rows) * row_height - 10}"/>')
        svg.append(f'<text class="tick" x="{tick_x:.2f}" y="162" text-anchor="middle">{tick}</text>')

    for index, row in enumerate(rows):
        signal, label, kind, anchor = row
        center = top + index * row_height + 22
        color = COLORS[signal]
        background = "#f8fafc" if index % 2 == 0 else "#ffffff"
        svg.append(f'<rect x="{left}" y="{center - 25}" width="{plot_width}" height="50" fill="{background}"/>')
        svg.append(f'<a href="{SIGNAL_BASE}{anchor}"><text class="label" x="{left - 18}" y="{center + 5}" text-anchor="end" style="fill:{color}">{html.escape(label)}</text></a>')
        svg.append(f'<line x1="{left}" y1="{center}" x2="{left + plot_width}" y2="{center}" stroke="#94a3b8"/>')
        if kind == "scalar":
            high, low = center - 13, center + 13
            path = []
            for seg_index, (seg_start, seg_end, value) in enumerate(
                    segments(changes[signal], start_ps, end_ps)):
                y = high if value == "1" else low
                path.append(f'M {x(seg_start):.2f} {y}' if seg_index == 0 else f'V {y}')
                path.append(f'H {x(seg_end):.2f}')
            svg.append(f'<path class="digital" style="stroke:{color}" d="{" ".join(path)}"/>')
        else:
            for seg_start, seg_end, value in bus_segments(
                    changes[signal], start_ps, end_ps):
                seg_x, seg_w = x(seg_start), x(seg_end) - x(seg_start)
                if signal == "state":
                    display, fill = STATE_NAMES.get(value, value.upper()), STATE_COLORS.get(value, color)
                elif signal == "cause":
                    display, fill = CAUSE_NAMES.get(value, value.upper()), CAUSE_COLORS.get(value, color)
                elif signal in {"csr_addr", "csr_rdata"} and value and set(value) <= {"0", "1"}:
                    display, fill = f"0x{int(value, 2):02X}", color
                else:
                    display = str(int(value, 2)) if value and set(value) <= {"0", "1"} else value.upper()
                    fill = color
                svg.append(f'<rect x="{seg_x:.2f}" y="{center - 16}" width="{max(seg_w, 0):.2f}" height="32" fill="{fill}" stroke="#ffffff"/>')
                if seg_w > max(24, len(display) * 7.3):
                    svg.append(f'<text class="bus" x="{seg_x + seg_w / 2:.2f}" y="{center + 4}" text-anchor="middle">{html.escape(display)}</text>')

    svg.append(f'<rect x="{left}" y="{top - 3}" width="{plot_width}" height="{len(rows) * row_height - 2}" fill="none" stroke="#94a3b8"/>')
    svg.append(f'<text class="tick" x="{left + plot_width / 2:.2f}" y="{height - 24}" text-anchor="middle">simulation time (ns)</text>')
    svg.append('</svg>')
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(svg) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("vcd", type=Path, nargs="?", default=Path("build/waves/error_recovery.vcd"))
    parser.add_argument("--wrapper-vcd", type=Path, default=Path("build/waves/fpga_csr_wrapper.vcd"))
    parser.add_argument("--output-dir", type=Path, default=Path("assets/waveforms/v0.4-error-recovery"))
    args = parser.parse_args()
    _, changes = parse_vcd(args.vcd)

    render(
        changes,
        args.output_dir / "retained-handshake.svg",
        "v0.4 retained fault and bounded TRAINERROR entry",
        "A one-cycle local-fatal pulse is retained; clear is ignored while pending; the request holds until the bounded entry",
        30,
        116,
        [
            ("fatal", "local_fatal_error_i", "scalar", "wave-error-local-fatal"),
            ("request", "handshake_request_o", "scalar", "wave-error-handshake-request"),
            ("pending", "pending_o", "scalar", "wave-error-pending"),
            ("clear", "clear_log_i", "scalar", "wave-error-clear"),
            ("ack", "handshake_done_i", "scalar", "wave-error-handshake-done"),
            ("hs_timeout", "handshake_timeout_o", "scalar", "wave-error-handshake-timeout"),
            ("enter", "enter_trainerror_o", "scalar", "wave-error-enter-trainerror"),
            ("state", "state_i", "bus", "wave-error-state"),
            ("cause", "cause_o", "bus", "wave-error-cause"),
            ("count", "event_count_o", "bus", "wave-error-count"),
        ],
        [
            (30, 46, "ONE-CYCLE FAULT", "#fee2e2", "#991b1b"),
            (46, 75, "PENDING · CLEAR IGNORED", "#ede9fe", "#5b21b6"),
            (75, 96, "BOUNDED ENTRY · RETAINED LOG", "#ffedd5", "#9a3412"),
            (96, 116, "RESET · ALLOWED CLEAR", "#dcfce7", "#166534"),
        ],
    )

    if args.wrapper_vcd.exists():
        _, wrapper_changes = parse_vcd(args.wrapper_vcd)
        aliases = {
            "fatal": "fatal_error_i",
            "ack": "error_handshake_done_i",
            "pending": "error_pending",
            "request": "handshake_request",
            "cause": "error_cause",
            "count": "error_event_count",
            "clear": "clear_error_log",
            "csr_valid": "csr_valid_i",
            "csr_write": "csr_write_i",
            "csr_ready": "csr_ready_o",
            "csr_addr": "csr_addr_i",
            "csr_rdata": "csr_rdata_o",
        }
        for alias, original in aliases.items():
            wrapper_changes[alias] = wrapper_changes[original]

        render(
            wrapper_changes,
            args.output_dir / "fpga-csr-read-clear.svg",
            "v0.4 FPGA CSR read, protected clear, and recovery",
            "The compact wrapper exposes retained status; TRAINERROR clear is ignored, then RESET clear succeeds",
            1235,
            1400,
            [
                ("fatal", "fatal_error_i", "scalar", "wave-csr-fatal"),
                ("request", "internal request", "scalar", "wave-csr-request"),
                ("pending", "internal pending", "scalar", "wave-csr-pending"),
                ("ack", "error_handshake_done_i", "scalar", "wave-csr-ack"),
                ("state", "internal LTSM state", "bus", "wave-csr-state"),
                ("cause", "retained cause", "bus", "wave-csr-cause"),
                ("count", "retained event count", "bus", "wave-csr-count"),
                ("csr_valid", "csr_valid_i", "scalar", "wave-csr-valid"),
                ("csr_write", "csr_write_i", "scalar", "wave-csr-write"),
                ("csr_addr", "csr_addr_i", "bus", "wave-csr-address"),
                ("csr_rdata", "csr_rdata_o", "bus", "wave-csr-read-data"),
                ("csr_ready", "csr_ready_o", "scalar", "wave-csr-ready"),
                ("clear", "internal clear request", "scalar", "wave-csr-clear"),
            ],
            [
                (1235, 1260, "ACTIVE · CSR READS", "#dcfce7", "#166534"),
                (1260, 1315, "FATAL RETAINED · CAUSE / COUNT READS", "#fee2e2", "#991b1b"),
                (1315, 1355, "TRAINERROR · CLEAR IGNORED", "#f3e8ff", "#6b21a8"),
                (1355, 1400, "RESET · CLEAR SUCCEEDS · INVALID READ = 0", "#dbeafe", "#1e40af"),
            ],
            source="verification/tb_ucie_ltsm_fpga_wrapper.sv",
        )

    render(
        changes,
        args.output_dir / "timeout-and-priority.svg",
        "v0.4 timeout, immediate-entry, and cause priority",
        "Held local fault counts once; SBINIT protocol error enters immediately; simultaneous causes retain state-timeout priority",
        115,
        226,
        [
            ("fatal", "local_fatal_error_i", "scalar", "wave-error-local-fatal"),
            ("sb_error", "sideband_protocol_error_i", "scalar", "wave-error-sideband"),
            ("state_timeout", "state_timeout_i", "scalar", "wave-error-state-timeout"),
            ("request", "handshake_request_o", "scalar", "wave-error-handshake-request"),
            ("pending", "pending_o", "scalar", "wave-error-pending"),
            ("hs_timeout", "handshake_timeout_o", "scalar", "wave-error-handshake-timeout"),
            ("enter", "enter_trainerror_o", "scalar", "wave-error-enter-trainerror"),
            ("state", "state_i", "bus", "wave-error-state"),
            ("cause", "cause_o", "bus", "wave-error-cause"),
            ("count", "event_count_o", "bus", "wave-error-count"),
        ],
        [
            (115, 166, "HELD FAULT · ONE EVENT · MANAGER TIMEOUT", "#fee2e2", "#991b1b"),
            (166, 196, "SBINIT PROTOCOL · IMMEDIATE", "#ffedd5", "#9a3412"),
            (196, 216, "SIMULTANEOUS · TIMEOUT PRIORITY", "#f3e8ff", "#6b21a8"),
            (216, 226, "RESET", "#e2e8f0", "#334155"),
        ],
    )


if __name__ == "__main__":
    main()
