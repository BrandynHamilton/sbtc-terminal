(define-constant sbtc-token 'SM3VDXK3WZZSA84XXFKAFAF15NNZX32CTSG82JFQ4.sbtc-token)

(define-constant contract-owner tx-sender)

(define-public (withdraw (recipient principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err u100))
    (match (contract-call? sbtc-token transfer amount (as-contract tx-sender) recipient none)
      success
        (begin
          (print {event: "withdraw", recipient: recipient, amount: amount})
          (ok amount))
      error (err u101))))

(define-public (transfer-from-contract (amount uint) (recipient principal))
  (begin
    ;; Only contract owner can initiate this
    (asserts! (is-eq tx-sender contract-owner) (err u103))
    (match (contract-call? sbtc-token transfer amount (as-contract tx-sender) recipient none)
      success
        (begin
          (print {event: "transfer-from-contract", recipient: recipient, amount: amount})
          (ok amount))
      error (err u104))))

(define-read-only (get-sbtc-balance (account principal))
  (contract-call? sbtc-token get-balance account))
