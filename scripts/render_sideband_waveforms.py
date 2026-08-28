#!/usr/bin/env python3
"""Render the reviewed v0.2 sideband-sequencer waveform evidence."""

from __future__ import annotations

import argparse
from pathlib import Path

from render_waveforms import SIGNAL_GUIDE, parse_vcd, render_figure


MESSAGE_NAMES = {
    "00000000": "NOP",
    "00000001": "DONE_REQ",
    "00000010": "DONE_RESP",
}

MESSAGE_COLORS = {
    "00000000": "#64748b",
    "00000001": "#2563eb",
    "00000010": "#15803d",
}

SOURCE = "verification/tb_ucie_sb_sequencer.sv"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "vcd",
        type=Path,
        nargs="?",
        default=Path("build/waves/sideband_sequencer.vcd"),
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("assets/waveforms/v0.2-sideband"),
    )
    args = parser.parse_args()
    _, changes = parse_vcd(args.vcd)

    render_figure(
        changes,
        args.output_dir / "success-bounded-retry.svg",
        "v0.2 sideband success and bounded retry",
        "Backpressure hold, accepted SBINIT request, expected response, and retry completion",
        20,
        195,
        [
            {"kind": "scalar", "signal": "start", "label": "start_i", "color": "#7c3aed", "href": f"{SIGNAL_GUIDE}#wave-sb-start"},
            {"kind": "scalar", "signal": "tx_valid", "label": "sb_tx_valid_o", "color": "#2563eb", "href": f"{SIGNAL_GUIDE}#wave-sb-tx-valid"},
            {"kind": "scalar", "signal": "tx_ready", "label": "sb_tx_ready_i", "color": "#0284c7", "href": f"{SIGNAL_GUIDE}#wave-sb-tx-ready"},
            {"kind": "bus", "signal": "tx_message", "label": "sb_tx_message_o", "names": MESSAGE_NAMES, "palette": MESSAGE_COLORS, "color": "#1d4ed8", "href": f"{SIGNAL_GUIDE}#wave-sb-tx-message"},
            {"kind": "scalar", "signal": "rx_valid", "label": "sb_rx_valid_i", "color": "#0f766e", "href": f"{SIGNAL_GUIDE}#wave-sb-rx-valid"},
            {"kind": "bus", "signal": "rx_message", "label": "sb_rx_message_i", "names": MESSAGE_NAMES, "palette": MESSAGE_COLORS, "color": "#15803d", "href": f"{SIGNAL_GUIDE}#wave-sb-rx-message"},
            {"kind": "scalar", "signal": "busy", "label": "sb_busy_o", "color": "#475569", "href": f"{SIGNAL_GUIDE}#wave-sb-busy"},
            {"kind": "scalar", "signal": "retry", "label": "sb_retry_o", "color": "#c2410c", "href": f"{SIGNAL_GUIDE}#wave-sb-retry"},
            {"kind": "scalar", "signal": "done", "label": "completion pulse", "color": "#15803d", "href": f"{SIGNAL_GUIDE}#wave-sb-done"},
        ],
        source=SOURCE,
    )

    render_figure(
        changes,
        args.output_dir / "exhaustion-mismatch-abort.svg",
        "v0.2 sideband exhaustion, mismatch, and abort",
        "Retry budget exhaustion, unexpected response rejection, and clean transaction cancellation",
        190,
        380,
        [
            {"kind": "scalar", "signal": "start", "label": "start_i", "color": "#7c3aed", "href": f"{SIGNAL_GUIDE}#wave-sb-start"},
            {"kind": "scalar", "signal": "abort", "label": "abort_i", "color": "#a21caf", "href": f"{SIGNAL_GUIDE}#wave-sb-abort"},
            {"kind": "scalar", "signal": "tx_valid", "label": "sb_tx_valid_o", "color": "#2563eb", "href": f"{SIGNAL_GUIDE}#wave-sb-tx-valid"},
            {"kind": "scalar", "signal": "tx_ready", "label": "sb_tx_ready_i", "color": "#0284c7", "href": f"{SIGNAL_GUIDE}#wave-sb-tx-ready"},
            {"kind": "scalar", "signal": "rx_valid", "label": "sb_rx_valid_i", "color": "#0f766e", "href": f"{SIGNAL_GUIDE}#wave-sb-rx-valid"},
            {"kind": "bus", "signal": "rx_message", "label": "sb_rx_message_i", "names": MESSAGE_NAMES, "palette": MESSAGE_COLORS, "color": "#15803d", "href": f"{SIGNAL_GUIDE}#wave-sb-rx-message"},
            {"kind": "scalar", "signal": "busy", "label": "sb_busy_o", "color": "#475569", "href": f"{SIGNAL_GUIDE}#wave-sb-busy"},
            {"kind": "scalar", "signal": "retry", "label": "sb_retry_o", "color": "#c2410c", "href": f"{SIGNAL_GUIDE}#wave-sb-retry"},
            {"kind": "scalar", "signal": "protocol_error", "label": "sb_protocol_error_o", "color": "#b91c1c", "href": f"{SIGNAL_GUIDE}#wave-sb-protocol-error"},
        ],
        source=SOURCE,
    )


if __name__ == "__main__":
    main()
