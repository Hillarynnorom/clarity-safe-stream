;; SafeStream Insurance Protocol

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-params (err u101))
(define-constant err-policy-not-found (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-policy-expired (err u104))
(define-constant err-pool-capacity (err u105))
(define-constant err-contract-paused (err u106))
(define-constant err-arithmetic (err u107))

;; Data Variables
(define-data-var min-premium uint u100000)
(define-data-var claim-threshold uint u500000)
(define-data-var pool-balance uint u0)
(define-data-var policy-duration uint u5256)
(define-data-var total-coverage uint u0)
(define-data-var max-coverage-ratio uint u800000)
(define-data-var contract-paused bool false)

;; Data Maps
(define-map policies
  principal
  {
    premium: uint,
    coverage: uint,
    last-payment: uint,
    income-source: (string-ascii 64),
    active: bool,
    total-paid: uint
  }
)

(define-map verified-sources
  (string-ascii 64) 
  bool
)

;; Private Functions
(define-private (is-policy-expired (last-payment uint))
  (> block-height (+ last-payment (var-get policy-duration)))
)

(define-private (check-pool-capacity (new-coverage uint))
  (match (to-uint (* (var-get pool-balance) (var-get max-coverage-ratio)))
    success (ok (<= (+ (var-get total-coverage) new-coverage) success))
    error err-arithmetic
  )
)

;; Public Functions
(define-public (create-policy (premium uint) (coverage uint) (income-source (string-ascii 64)))
  (begin
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (>= premium (var-get min-premium)) err-invalid-params)
    (asserts! (map-get? verified-sources income-source) err-invalid-params)
    (asserts! (unwrap! (check-pool-capacity coverage) err-arithmetic) err-pool-capacity)
    (var-set total-coverage (+ (var-get total-coverage) coverage))
    (ok (map-set policies tx-sender {
      premium: premium,
      coverage: coverage,
      last-payment: block-height,
      income-source: income-source,
      active: true,
      total-paid: u0
    }))
  )
)

(define-public (pay-premium)
  (let (
    (policy (unwrap! (map-get? policies tx-sender) err-policy-not-found))
  )
    (begin
      (asserts! (not (var-get contract-paused)) err-contract-paused)
      (asserts! (is-eq (get active policy) true) err-unauthorized)
      (asserts! (not (is-policy-expired (get last-payment policy))) err-policy-expired)
      (try! (stx-transfer? (get premium policy) tx-sender (as-contract tx-sender)))
      (var-set pool-balance (+ (var-get pool-balance) (get premium policy)))
      (ok (map-set policies tx-sender (merge policy { 
        last-payment: block-height,
        total-paid: (+ (get total-paid policy) (get premium policy))
      })))
    )
  )
)

(define-public (file-claim (income uint))
  (let (
    (policy (unwrap! (map-get? policies tx-sender) err-policy-not-found))
    (threshold-amount (* (get coverage policy) (var-get claim-threshold)))
  )
    (begin
      (asserts! (not (var-get contract-paused)) err-contract-paused)
      (asserts! (is-eq (get active policy) true) err-unauthorized)
      (asserts! (not (is-policy-expired (get last-payment policy))) err-policy-expired)
      (asserts! (< income threshold-amount) err-invalid-params)
      (asserts! (<= (get coverage policy) (var-get pool-balance)) err-insufficient-funds)
      ;; Update state before transfer
      (var-set pool-balance (- (var-get pool-balance) (get coverage policy)))
      (var-set total-coverage (- (var-get total-coverage) (get coverage policy)))
      (map-set policies tx-sender (merge policy { active: false }))
      ;; Perform transfer last
      (try! (as-contract (stx-transfer? (get coverage policy) (as-contract tx-sender) tx-sender)))
      (ok true)
    )
  )
)

;; Admin Functions
(define-public (withdraw-excess-funds (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (asserts! (<= amount (- (var-get pool-balance) (/ (var-get total-coverage) (var-get max-coverage-ratio)))) err-insufficient-funds)
    (var-set pool-balance (- (var-get pool-balance) amount))
    (try! (as-contract (stx-transfer? amount (as-contract tx-sender) contract-owner)))
    (ok true)
  )
)
