;; SafeStream Insurance Protocol

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-params (err u101))
(define-constant err-policy-not-found (err u102))
(define-constant err-insufficient-funds (err u103))

;; Data Variables
(define-data-var min-premium uint u100000) ;; in STX
(define-data-var claim-threshold uint u500000) ;; min income drop %
(define-data-var pool-balance uint u0)

;; Data Maps
(define-map policies
  principal
  {
    premium: uint,
    coverage: uint,
    last-payment: uint,
    income-source: (string-ascii 64),
    active: bool
  }
)

(define-map verified-sources
  (string-ascii 64) 
  bool
)

;; Public Functions
(define-public (create-policy (premium uint) (coverage uint) (income-source (string-ascii 64)))
  (begin
    (asserts! (>= premium (var-get min-premium)) err-invalid-params)
    (asserts! (map-get? verified-sources income-source) err-invalid-params)
    (ok (map-set policies tx-sender {
      premium: premium,
      coverage: coverage,
      last-payment: block-height,
      income-source: income-source,
      active: true
    }))
  )
)

(define-public (pay-premium)
  (let (
    (policy (unwrap! (map-get? policies tx-sender) err-policy-not-found))
  )
    (begin
      (asserts! (is-eq (get active policy) true) err-unauthorized)
      (try! (stx-transfer? (get premium policy) tx-sender (as-contract tx-sender)))
      (var-set pool-balance (+ (var-get pool-balance) (get premium policy)))
      (ok (map-set policies tx-sender (merge policy { last-payment: block-height })))
    )
  )
)

(define-public (file-claim (income uint))
  (let (
    (policy (unwrap! (map-get? policies tx-sender) err-policy-not-found))
    (threshold-amount (* (get coverage policy) (var-get claim-threshold)))
  )
    (begin
      (asserts! (is-eq (get active policy) true) err-unauthorized)
      (asserts! (< income threshold-amount) err-invalid-params)
      (try! (as-contract (stx-transfer? (get coverage policy) tx-sender tx-sender)))
      (var-set pool-balance (- (var-get pool-balance) (get coverage policy)))
      (ok true)
    )
  )
)

;; Admin Functions
(define-public (add-verified-source (source (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (ok (map-set verified-sources source true))
  )
)
