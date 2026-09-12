-- CyberSentry M1 seed data

-- ATT&CK tactics
INSERT INTO attack_tactics (tactic_id, name) VALUES
('TA0001', 'Initial Access'),
('TA0002', 'Execution'),
('TA0003', 'Persistence'),
('TA0006', 'Credential Access'),
('TA0007', 'Discovery'),
('TA0011', 'Command and Control'),
('TA0010', 'Exfiltration')
ON CONFLICT (tactic_id) DO NOTHING;

-- ATT&CK techniques
INSERT INTO attack_techniques
(technique_id, name, tactic_id, parent_technique_id)
VALUES
('T1078', 'Valid Accounts', 'TA0001', NULL),
('T1110', 'Brute Force', 'TA0006', NULL),
('T1003', 'OS Credential Dumping', 'TA0006', NULL),
('T1003.001', 'LSASS Memory', 'TA0006', 'T1003'),
('T1059', 'Command and Scripting Interpreter', 'TA0002', NULL),
('T1059.001', 'PowerShell', 'TA0002', 'T1059'),
('T1071', 'Application Layer Protocol', 'TA0011', NULL),
('T1071.004', 'DNS', 'TA0011', 'T1071'),
('T1098', 'Account Manipulation', 'TA0003', NULL),
('T1046', 'Network Service Discovery', 'TA0007', NULL),
('T1041', 'Exfiltration Over C2 Channel', 'TA0010', NULL)
ON CONFLICT (technique_id) DO NOTHING;

-- Detection rules
INSERT INTO detection_rules
(rule_code, rule_version, name, technique_id, base_severity, parameters)
VALUES
(
 'DR001_BRUTE_FORCE', 1,
 'Repeated failed authentication from a single source',
 'T1110', 'medium',
 '{"failures": 15, "window_minutes": 5}'
),
(
 'DR002_IMPOSSIBLE_TRAVEL', 1,
 'Successful logins from impossible locations',
 'T1078', 'high',
 '{"max_kph": 900}'
),
(
 'DR003_LSASS_ACCESS', 1,
 'Non-system process opened a handle to LSASS',
 'T1003.001', 'critical',
 '{}'
),
(
 'DR004_ENCODED_POWERSHELL', 1,
 'PowerShell executed with an encoded command',
 'T1059.001', 'high',
 '{"min_length": 120}'
),
(
 'DR005_DNS_TUNNEL', 1,
 'Anomalous DNS volume and entropy to a single domain',
 'T1071.004', 'high',
 '{"queries_per_minute": 60, "min_entropy": 3.5}'
),
(
 'DR006_CLOUD_KEY_CREATED', 1,
 'New access key created for a privileged identity',
 'T1098', 'medium',
 '{}'
),
(
 'DR007_PORT_SCAN', 1,
 'Single source contacted many ports on many hosts',
 'T1046', 'low',
 '{"unique_ports": 50}'
),
(
 'DR008_LARGE_EGRESS', 1,
 'Unusual outbound data volume to an external address',
 'T1041', 'high',
 '{"mb_threshold": 500}'
)
ON CONFLICT (rule_code, rule_version) DO NOTHING;

-- Playbooks
INSERT INTO playbooks
(playbook_code, name, technique_id, actions, requires_approval)
VALUES
(
 'PB_CRED_DUMP',
 'Credential dumping containment',
 'T1003.001',
 '["isolate_host", "collect_forensics", "disable_account", "notify_owner"]',
 TRUE
),
(
 'PB_BRUTE_FORCE',
 'Brute force response',
 'T1110',
 '["block_ip", "notify_owner"]',
 FALSE
),
(
 'PB_C2_DNS',
 'DNS command and control',
 'T1071.004',
 '["block_ip", "isolate_host", "collect_forensics"]',
 TRUE
)
ON CONFLICT (playbook_code) DO NOTHING;