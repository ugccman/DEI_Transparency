;; DEI Transparency Token System
;; Incentivizes transparent reporting of diversity metrics

;; Define fungible token
(define-fungible-token dei-token)

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-registered (err u102))
(define-constant err-invalid-score (err u103))
(define-constant err-audit-period-active (err u104))
(define-constant err-insufficient-balance (err u105))

;; Define data variables
(define-data-var total-companies uint u0)
(define-data-var reward-pool uint u0)
(define-data-var audit-period-blocks uint u4320) ;; ~30 days

;; Define maps
(define-map companies
    principal
    {
        name: (string-utf8 100),
        registration-block: uint,
        last-report-block: uint,
        transparency-score: uint,
        verified: bool
    }
)

(define-map diversity-reports
    { company: principal, report-id: uint }
    {
        gender-diversity: uint, ;; percentage 0-100
        ethnic-diversity: uint, ;; percentage 0-100
        leadership-diversity: uint, ;; percentage 0-100
        pay-equity-score: uint, ;; score 0-100
        inclusion-initiatives: (string-utf8 500),
        report-block: uint,
        audit-status: (string-utf8 20)
    }
)

(define-map report-counter principal uint)

(define-map auditor-votes
    { company: principal, report-id: uint, auditor: principal }
    bool ;; true = approve, false = reject
)

(define-map auditors principal bool)

;; Read-only functions
(define-read-only (get-company-info (company principal))
    (map-get? companies company)
)

(define-read-only (get-diversity-report (company principal) (report-id uint))
    (map-get? diversity-reports { company: company, report-id: report-id })
)

(define-read-only (get-token-balance (account principal))
    (ft-get-balance dei-token account)
)

(define-read-only (is-auditor (account principal))
    (default-to false (map-get? auditors account))
)

;; Public functions
(define-public (register-company (name (string-utf8 100)))
    (begin
        (asserts! (is-none (get-company-info tx-sender)) err-already-registered)
        (map-set companies tx-sender {
            name: name,
            registration-block: stacks-block-height,
            last-report-block: u0,
            transparency-score: u0,
            verified: false
        })
        (var-set total-companies (+ (var-get total-companies) u1))
        (ok true)
    )
)

(define-public (submit-diversity-report
    (gender-diversity uint)
    (ethnic-diversity uint)
    (leadership-diversity uint)
    (pay-equity-score uint)
    (inclusion-initiatives (string-utf8 500)))
    (let
        (
            (company-info (unwrap! (get-company-info tx-sender) err-not-registered))
            (current-report-id (default-to u0 (map-get? report-counter tx-sender)))
            (new-report-id (+ current-report-id u1))
        )
        (asserts! (<= gender-diversity u100) err-invalid-score)
        (asserts! (<= ethnic-diversity u100) err-invalid-score)
        (asserts! (<= leadership-diversity u100) err-invalid-score)
        (asserts! (<= pay-equity-score u100) err-invalid-score)
        
        (map-set diversity-reports
            { company: tx-sender, report-id: new-report-id }
            {
                gender-diversity: gender-diversity,
                ethnic-diversity: ethnic-diversity,
                leadership-diversity: leadership-diversity,
                pay-equity-score: pay-equity-score,
                inclusion-initiatives: inclusion-initiatives,
                report-block: stacks-block-height,
                audit-status: u"pending"
            }
        )
        (map-set report-counter tx-sender new-report-id)
        (map-set companies tx-sender 
            (merge company-info { last-report-block: stacks-block-height })
        )
        (ok new-report-id)
    )
)

(define-public (add-auditor (new-auditor principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set auditors new-auditor true)
        (ok true)
    )
)

(define-public (audit-report (company principal) (report-id uint) (approve bool))
    (let
        (
            (report (unwrap! (get-diversity-report company report-id) err-not-registered))
            (audit-deadline (+ (get report-block report) (var-get audit-period-blocks)))
        )
        (asserts! (is-auditor tx-sender) err-owner-only)
        (asserts! (< stacks-block-height audit-deadline) err-audit-period-active)
        
        (map-set auditor-votes
            { company: company, report-id: report-id, auditor: tx-sender }
            approve
        )
        
        (if approve
            (try! (ft-mint? dei-token u100 company))
            true
        )
        (ok true)
    )
)

(define-public (donate-to-reward-pool (amount uint))
    (begin
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (var-set reward-pool (+ (var-get reward-pool) amount))
        (ok true)
    )
)

(define-public (claim-transparency-reward)
    (let
        (
            (company-info (unwrap! (get-company-info tx-sender) err-not-registered))
            (reward-amount (/ (var-get reward-pool) (var-get total-companies)))
        )
        (asserts! (get verified company-info) err-owner-only)
        (asserts! (> (var-get reward-pool) u0) err-insufficient-balance)
        
        (try! (as-contract (stx-transfer? reward-amount tx-sender tx-sender)))
        (var-set reward-pool (- (var-get reward-pool) reward-amount))
        (ok reward-amount)
    )
)