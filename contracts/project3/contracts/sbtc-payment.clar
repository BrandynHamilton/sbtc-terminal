;; contracts/sbtc-payment.clar

;; Define the sBTC token contract reference
(define-constant sbtc-token 'SM3VDXK3WZZSA84XXFKAFAF15NNZX32CTSG82JFQ4.sbtc-token)

;; Error codes
(define-constant err-insufficient-balance (err u100))
(define-constant err-transfer-failed (err u101))

;; Accept sBTC payment
(define-public (pay-with-sbtc (amount uint) (recipient principal))
  (contract-call? sbtc-token transfer
    amount
    tx-sender
    recipient
    none))