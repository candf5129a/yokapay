# YokaPay

YokaPay is an early Flutter mobile banking prototype for Android and iOS, designed to make transactions accessible and money easier to manage. The prototype now includes a navigable account overview, currency wallet and rate views, transfers, a currency calculator, group savings concepts, card designs, activity, notifications, and light/dark themes.

## Product direction

- Familiar, fast-to-scan home screen inspired by OPay's visible service shortcuts and transaction-first layout, with a distinct YokaPay visual identity.
- Theme mode and accent colors (gold, silver, blue, red, green) saved on the device. Tap the theme icon to switch light/dark; hold it for three seconds to open color choices.
- Currency wallet and indicative market-rate screens, with a calculator that estimates conversions without executing an exchange.
- Transfers between YokaPay accounts or to another bank as a preview; no payment is sent.
- Group contribution goals with a planned release date and a sample early-withdrawal vote. No funds are held.
- Digital card and gift card designs, including artist, gamer, travel, and transit concepts. No payment card is issued.
- A 12-item home service grid and a categorized More screen, including a BVN service preview that never asks for a BVN.
- Notifications, activity history, and clearly labeled sample partner placements.
- Emergency safety mode that can discreetly request help, lock down the account, or initiate a real, clearly labeled payment only after confirmation. It must never create counterfeit receipts or transfers.
- Payment verification based on a server-authoritative transaction record and a recipient's own account activity. A screenshot, notification, or client-generated identifier is never proof of payment.
- Fraud reports and safety notifications that do not secretly locate or track another person. Sound and alert behavior follows device settings and platform rules.

## Prototype status

The current app is a visual prototype. Balances, account details, market values, transactions, voting, and partner placements are sample content. It does not connect to a bank or market feed, move money, issue cards, authenticate users, collect identity information, or hold savings. Never enter real banking or identity information in a prototype.

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
