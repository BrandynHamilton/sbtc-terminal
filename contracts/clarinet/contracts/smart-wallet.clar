;; SIP-010 sBTC token contract (update to the correct deployer if needed)
(define-constant sbtc-token 'SM3VDXK3WZZSA84XXFKAFAF15NNZX32CTSG82JFQ4.sbtc-token)

;; Snapshot of deployer at contract publish time
(define-constant contract-owner tx-sender)

;; --- Config ---
;; Up to 3 signers; default threshold = 2 (changeable via init)
(define-data-var signers (list 3 principal) (list))
(define-data-var threshold uint u2)

;; Pending transfers keyed by tx-id
(define-map pending-transfers
  { id: uint }
  { recipient: principal
  , amount: uint
  , approvals: (list 3 principal) })

;; --- Helpers ---
(define-read-only (is-signer (who principal))
  (let ((ss (var-get signers)))
    (or
      (match (element-at ss u0) p (is-eq who p) false)
      (match (element-at ss u1) p (is-eq who p) false)
      (match (element-at ss u2) p (is-eq who p) false))))

(define-read-only (has-approved (approvals (list 3 principal)) (who principal))
  (or (is-eq who (element-at approvals u0))
      (is-eq who (element-at approvals u1))
      (is-eq who (element-at approvals u2))))

;; --- Admin: one-time init ---

(define-public (init-wallet (s1 principal) (s2 principal) (s3 principal) (t uint))
  (begin
    ;; only deployer (owner snapshot) can initialize
    (asserts! (is-eq tx-sender contract-owner) (err u100))
    ;; only allow init if never set
    (asserts! (is-eq (var-get signers) (list)) (err u101))
    (asserts! (and (>= t u1) (<= t u3)) (err u102))
    (var-set signers (list s1 s2 s3))
    (var-set threshold t)
    (ok true)
  )
)

;; --- Propose a transfer (any signer can propose) ---

(define-public (propose-transfer (tx-id uint) (recipient principal) (amount uint))
  (begin
    ;; only a signer can propose
    (asserts! (is-signer tx-sender) (err u110))

    ;; ensure transfer with this ID doesn't already exist
    (asserts! (is-none (map-get? pending-transfers { id: tx-id })) (err u111))

    ;; create the pending transfer with empty approvals
    (map-set pending-transfers
      { id: tx-id }
      { recipient: recipient
      , amount: amount
      , approvals: (list) }) ;; empty list

    ;; return the tx-id
    (ok tx-id)
  )
)

;; --- Approve (and possibly execute) a transfer ---

(define-public (approve-transfer (tx-id uint))
  (let ((maybe (map-get? pending-transfers { id: tx-id })))
    (match maybe
      tx
      (begin
        (asserts! (is-signer tx-sender) (err u120))
        (let ((new-approvals (cons tx-sender (get tx approvals))))
          ;; ensure signer has not already approved
          (asserts! (not (or (is-eq tx-sender (unwrap! (get new-approvals a) false))
                             (is-eq tx-sender (unwrap! (get new-approvals b) false))
                             (is-eq tx-sender (unwrap! (get new-approvals c) false))))
                    (err u121))
          ;; add signer to first empty slot
          (let ((new-approvals
                 { a: (if (is-none (get new-approvals a)) (some tx-sender) (get new-approvals a))
                 , b: (if (is-none (get new-approvals b)) (some tx-sender) (get new-approvals b))
                 , c: (if (is-none (get new-approvals c)) (some tx-sender) (get new-approvals c))
                 }))
            (map-set pending-transfers
                     { id: tx-id }
                     { recipient: (get tx recipient)
                     , amount: (get tx amount)
                     , approvals: new-approvals })

            ;; check if threshold met
            (let ((count (+
                           (if (is-some (get new-approvals a)) u1 u0)
                           (if (is-some (get new-approvals b)) u1 u0)
                           (if (is-some (get new-approvals c)) u1 u0))))
              (if (>= count (var-get threshold))
                  ;; execute transfer
                  (let ((res (contract-call? sbtc-token transfer (get tx amount) (as-contract tx-sender) (get tx recipient) none)))
                    (match res
                      success
                      (begin
                        (map-delete pending-transfers { id: tx-id })
                        (print { event: "executed", id: tx-id, to: (get tx recipient), amount: (get tx amount) })
                        (ok "executed")
                      )
                      error (err u130)
                    )
                  )
                  (ok "approved")
              )
            )
          )
        )
      )
      (err u404)
    )
  )
)

;; --- Read-only helpers ---

(define-public (read-balance (account principal))
  (contract-call? sbtc-token get-balance account))

(define-read-only (get-pending (tx-id uint))
  (map-get? pending-transfers { id: tx-id }))

(define-read-only (get-config)
  { signers: (var-get signers), threshold: (var-get threshold) })
