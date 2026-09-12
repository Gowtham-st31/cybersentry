\# CyberSentry



CyberSentry is a defensive SOC and threat-detection platform.



\## Milestone 1



M1 establishes the foundation for:



\- Security telemetry ingestion

\- ATT\&CK-based detection rules

\- Deterministic detection correlation

\- Incident and case state

\- Response playbooks

\- OpenSearch telemetry storage

\- PostgreSQL case storage



\## Infrastructure



\- Apache Kafka

\- Zookeeper

\- OpenSearch 2.14

\- PostgreSQL 16

\- Redis 7

\- MLflow 2.14.1



\## Kafka Topics



\- `sec.raw`

\- `sec.normalized`

\- `sec.detections`

\- `sec.dlq`



\## Detection Rules



Detection-as-code is maintained in:



`config/detection\_rules.yml`



M1 includes 8 initial detection rules mapped to MITRE ATT\&CK techniques.



\## Domain Library



The pure domain logic is located in:



`libs/sentry\_domain/`



It provides:



\- Severity calculation

\- Risk scoring

\- Deduplication

\- Entity selection

\- Deterministic correlation



\## Running



```text

make up

make db-init

make seed

make data

make test

make verify

