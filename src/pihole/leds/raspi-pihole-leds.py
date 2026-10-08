#!/usr/bin/env python3
"""Flash GPIO LEDs for answered and blocked Pi-hole DNS queries."""

import os
import signal
import sys
import time
from pathlib import Path

from gpiozero import LED


ANSWERED_MARKERS = (" reply ", " cached ")
BLOCKED_MARKERS = (
    " gravity blocked ",
    " regex denied ",
    " exactly denied ",
    " denylisted ",
)


def positive_float(name: str, default: str) -> float:
    value = float(os.environ.get(name, default))
    if value <= 0:
        raise ValueError(f"{name} must be greater than zero")
    return value


def flash(led: LED, duration: float) -> None:
    led.on()
    time.sleep(duration)
    led.off()


def follow(path: Path):
    """Yield appended lines and reopen the file after log rotation."""
    handle = None
    identity = None

    while True:
        try:
            current_identity = (path.stat().st_dev, path.stat().st_ino)
            if handle is None or current_identity != identity:
                if handle is not None:
                    handle.close()
                handle = path.open("r", encoding="utf-8", errors="replace")
                handle.seek(0, os.SEEK_END)
                identity = current_identity

            line = handle.readline()
            if line:
                yield line.lower()
            else:
                time.sleep(0.2)
        except FileNotFoundError:
            if handle is not None:
                handle.close()
                handle = None
                identity = None
            time.sleep(1)


def main() -> int:
    answered_gpio = int(os.environ.get("ANSWERED_GPIO", "20"))
    blocked_gpio = int(os.environ.get("BLOCKED_GPIO", "21"))
    log_path = Path(os.environ.get("PIHOLE_LOG", "/var/log/pihole/pihole.log"))
    duration = positive_float("BLINK_SECONDS", "0.08")

    answered = LED(answered_gpio)
    blocked = LED(blocked_gpio)

    def stop(_signum, _frame):
        answered.off()
        blocked.off()
        raise SystemExit(0)

    signal.signal(signal.SIGINT, stop)
    signal.signal(signal.SIGTERM, stop)

    try:
        for line in follow(log_path):
            if any(marker in line for marker in BLOCKED_MARKERS):
                flash(blocked, duration)
            elif any(marker in line for marker in ANSWERED_MARKERS):
                flash(answered, duration)
    finally:
        answered.close()
        blocked.close()

    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, RuntimeError, ValueError) as error:
        print(f"raspi-pihole-leds: {error}", file=sys.stderr)
        sys.exit(1)
