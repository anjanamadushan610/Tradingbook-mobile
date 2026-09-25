# Google Play listing — ready-to-paste material

Assets are in `store/`: `play-icon-512.png`, `feature-graphic-1024x500.png`,
and phone screenshots in `store/screenshots/` (1080×2160).

## Store listing

**App name** (30 max): `TradingBook: Traders' Network`

**Short description** (80 max):
`Share trade setups, follow traders, join trading groups and track crypto prices.`

**Full description:**

```
TradingBook is the social network built for traders.

SHARE YOUR SETUPS
Post your analysis with up to 10 chart screenshots, tag it (#BTC, #Gold, #Forex) and choose who sees it: everyone, only your followers, or just you.

FOLLOW TRADERS YOU LEARN FROM
Build a feed of the traders, pages and groups you care about. Like, comment, reply and save posts to read later.

JOIN TRADING COMMUNITIES
Groups for every market and style — public or private, with their own moderators. Brands, desks and analysts publish through Pages.

TRACK THE MARKETS
Live spot crypto prices and candlestick charts from 1-minute to weekly, with a personal watchlist. Every price shows how old it is — no stale numbers dressed up as live.

A SAFER COMMUNITY
Every post is reviewed by moderators before it goes live. Report anything that looks like a scam or manipulation, and block anyone with one tap.

TradingBook is for education and discussion. Nothing on TradingBook is financial advice.
```

**Category:** Social  **Tags:** Social, Finance, Community
**Contact email:** privacy@tradingbooknet.com
**Website:** https://tradingbooknet.com
**Privacy policy:** https://tradingbooknet.com/privacy

## App access (for Google's reviewers)

All functionality requires sign-in. Provide a test account in
Play Console → App content → App access:

- Email: `prodtest@example.com`  Password: *(its current password)*
- This account is also a moderator, so reviewers can see the moderation tools.

## Content rating questionnaire (IARC)

- Category: **Social / communication**.
- Users can interact / exchange content: **Yes** (posts, comments).
- Shares user location: **No**.
- Digital purchases: **No**. Gambling / simulated gambling: **No**.
- Violence, sexual content, drugs, profanity *in the app's own content*: **No**
  (user content is moderated before publication; reporting and blocking exist).

## Data safety form

Data **collected** (all encrypted in transit, none sold, none used for ads):

| Data type | Collected | Shared | Purpose | Optional? |
| :--- | :--- | :--- | :--- | :--- |
| Email address | Yes | No | Account management | Required |
| Name (display name) | Yes | No | App functionality, account | Required |
| User IDs | Yes | No | App functionality | Required |
| Photos (avatar, cover, post images) | Yes | No | App functionality | Optional |
| Other user-generated content (posts, comments) | Yes | No | App functionality | Optional |
| App interactions (views, time on post) | Yes | No | Analytics, personalisation (feed ranking) | Required when signed in |
| Device or other IDs (push token) | Yes, once push is enabled | Shared with Google (FCM) for delivery | App functionality | Optional (OS permission) |

- Data is encrypted in transit: **Yes** (HTTPS only in release builds).
- Users can request deletion: **Yes** — in-app (Settings → Delete account) and
  via https://tradingbooknet.com/privacy (email privacy@tradingbooknet.com).
- Location: **not collected** (image EXIF, including GPS, is stripped on the
  device before upload).

## Account deletion (Play policy)

- In app: Profile → Settings → Delete account (password or typed DELETE).
- Web: the policy asks for a URL where users can request deletion without
  the app. https://tradingbooknet.com/privacy says to email
  privacy@tradingbooknet.com; a dedicated `/delete-account` page on the web
  app would be the cleaner answer (the API is `DELETE /api/v1/me`).

## Financial features declaration

TradingBook shows market prices and hosts discussion; it does **not** offer
trading, brokerage, crypto custody, loans or payments. Declare
"My app doesn't provide any financial features".

## Target audience

18+ (finance discussion). Not designed for children.
