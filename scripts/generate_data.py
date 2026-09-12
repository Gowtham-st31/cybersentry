from __future__ import annotations

import json
import random
from datetime import datetime, timezone


def make_event(i: int) -> dict:
    return {
        "event_id": f"EVT-{i:06d}",
        "@timestamp": datetime.now(timezone.utc).isoformat(),
        "event_type": random.choice(
            [
                "authentication",
                "process",
                "dns",
                "network",
                "cloud",
            ]
        ),
        "host_id": f"HOST-{random.randint(1, 60):04d}",
        "user_name": f"user{random.randint(1, 20)}",
        "source_ip": f"10.0.{random.randint(1, 10)}.{random.randint(1, 254)}",
        "message": "Synthetic CyberSentry telemetry event",
    }


def main() -> None:
    events = [make_event(i) for i in range(1, 301)]

    with open("data/sample_events.jsonl", "w", encoding="utf-8") as f:
        for event in events:
            f.write(json.dumps(event) + "\n")

    print(f"Generated {len(events)} events.")


if __name__ == "__main__":
    main()