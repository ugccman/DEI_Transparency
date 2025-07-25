# DEI Transparency Token System

This Clarity smart contract implements a decentralized system to encourage transparent reporting of diversity, equity, and inclusion (DEI) metrics by companies. It uses a tokenized reward mechanism and community auditing to validate submitted reports.

## Features

* **Company Registration**: Entities can register and begin reporting diversity metrics.
* **DEI Reporting**: Registered companies submit structured diversity reports.
* **Auditor Governance**: Approved auditors verify submitted reports.
* **Token Incentives**: Verified reports earn `dei-token` rewards.
* **Reward Pool**: Public STX donations are distributed as incentives to compliant companies.
* **Transparency Score**: Companies build reputation based on report frequency and approval.

## Token

* **`dei-token`**: Fungible token rewarded to companies for approved diversity reports.

## Data Structures

* **Companies Map**: Stores registration info, reporting history, and status.
* **Diversity Reports Map**: Structured data on gender, ethnicity, leadership, pay equity, and initiatives.
* **Report Counter Map**: Tracks the number of reports per company.
* **Auditor Votes Map**: Records auditor approvals or rejections.
* **Auditors Map**: Verifies if a principal is an approved auditor.

## Public Functions

* `register-company`: Companies register with name and principal address.
* `submit-diversity-report`: Submit metrics and initiatives for auditing.
* `add-auditor`: Contract owner grants auditor status to a principal.
* `audit-report`: Auditors approve/reject reports and issue token rewards.
* `donate-to-reward-pool`: Adds STX to the reward pool.
* `claim-transparency-reward`: Verified companies can claim a share of the reward pool.

## Read-Only Functions

* `get-company-info`
* `get-diversity-report`
* `get-token-balance`
* `is-auditor`

## Governance and Logic

* Auditing window: 4320 blocks (\~30 days).
* Reward: 100 `dei-token` per approved report.
* STX reward pool is distributed evenly to verified companies.
* Audit status tracked per report with "pending" status by default.

## Error Handling

Ensures:

* Only registered companies report.
* Data integrity with score validation (0–100).
* Only approved auditors can audit.
* No audit after the review period ends.
* Rewards only disbursed to verified companies.
