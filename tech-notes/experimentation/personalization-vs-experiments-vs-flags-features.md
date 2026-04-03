## 1. Personalization

Definition: Tailoring the product experience to an individual user (or cohort) based on their behavior, profile, or context.

Examples:
* Netflix recommending shows based on your watch history.
* Spotify generating custom playlists.
* E-commerce sites showing personalized deals.

Purpose: Increase engagement and relevance for each specific user.

## 2. Experimentation

Definition: Running controlled trials (like A/B tests or multivariate tests) to measure how a change impacts user behavior or business metrics.

Examples:
* Testing two different checkout flows to see which increases conversion.
* Trying a new recommendation algorithm with 10% of users.
Purpose: Learn what actually works before rolling it out widely; reduce risk of harmful changes.

## 3. Feature Flags

Definition: A mechanism to turn features on/off dynamically without redeploying code, often controlled at runtime.
Examples:
* Launching a new “dark mode” behind a flag.
* Gradually rolling out a payment method to 5%, then 50%, then 100% of users.

Purpose: Control rollout, enable canary releases, reduce deployment risk, allow quick rollback.

## 4. Core Features

Definition: The foundational functionality of the product — the parts that every user expects and cannot opt out of.

Examples:
* Messaging in WhatsApp.
* Searching in Google.
* File upload in Dropbox.

Purpose: Define the product’s identity and value; they are not optional or gated by flags/experiments.

## 5. Configurations / Preferences

Definition: User-controlled or admin-controlled settings that adjust product behavior or presentation.
Examples:
* Changing language or timezone in account settings.
* Choosing default home page in a browser.
* Turning notifications on/off.

Purpose: Give users autonomy to customize their experience within supported parameters.

✅ How they relate:
* Feature flags → Control whether something is active.
* Experimentation → Measures impact of changes (often using flags under the hood).
* Personalization → Decides who sees what, dynamically.
* Configurations/preferences → Let users control their own experience.
* Core features → The baseline; everything else builds around them.