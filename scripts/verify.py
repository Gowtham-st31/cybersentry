from pathlib import Path


REQUIRED_FILES = [
    "scripts/init_db.sql",
    "scripts/seed.sql",
    "scripts/seed.ps1",
    "config/detection_rules.yml",
    "config/opensearch_template.json",
    "docker-compose.yml",
    ".env.example",
    ".gitignore",
    "Makefile",
]


def main() -> None:
    root = Path(__file__).resolve().parent.parent

    missing = [
        file
        for file in REQUIRED_FILES
        if not (root / file).exists()
    ]

    if missing:
        print("Missing required files:")
        for file in missing:
            print(f"  - {file}")
        raise SystemExit(1)

    print("CyberSentry M1 file verification passed.")


if __name__ == "__main__":
    main()