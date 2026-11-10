# YokaPay

YokaPay is an early Flutter mobile banking prototype for Android and iOS. The first iteration focuses on a calm, trustworthy account overview, clear payment status, and accessible light and dark themes.

## Product direction

- Familiar, fast-to-scan home screen inspired by OPay's visible service shortcuts and transaction-first layout, with a distinct YokaPay visual identity.
- Currency wallets that keep incoming funds in the received currency until the user chooses to convert.
- Digital card concepts for online payment and transit, subject to issuer and local transit support.
- Emergency safety mode that can discreetly request help, lock down the account, or initiate a real, clearly labeled payment only after confirmation. It must never create counterfeit receipts or transfers.
- Payment verification based on a server-authoritative transaction record and a recipient's own account activity. A screenshot, notification, or client-generated identifier is never proof of payment.
- Fraud reports and safety notifications that do not secretly locate or track another person. Sound and alert behavior follows device settings and platform rules.

## Prototype status

The current app is a visual, local-only prototype. It does not connect to a bank, move money, issue cards, authenticate users, or store personal data. Never enter real banking or identity information in a prototype.

## Run

Install Flutter, then from this directory run:

```sh
flutter pub get
flutter run
```

## Next steps

1. Confirm the target launch market, regulated banking/payment partners, and supported currencies.
2. Design onboarding, account recovery, real transaction confirmation, and recipient-side verification.
3. Define a threat model, privacy policy, data retention rules, and independent security review before collecting identity documents or handling funds.
4. Integrate licensed payment, FX, card issuing, and transit providers through a secure backend.
