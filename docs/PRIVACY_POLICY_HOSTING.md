# Privacy Policy hosting (Google Play Console)

FocusNexus ships a static Privacy Policy page for Play Console. The canonical
legal text lives in [`legal/PRIVACY_POLICY.md`](../legal/PRIVACY_POLICY.md)
(version **1.0.0**). The publish mirror is
[`docs/privacy/index.html`](privacy/index.html).

## Current Play Console URL

Paste this HTTPS URL into Play Console (App content / Privacy policy):

https://sparkling-gumdrop-1d2c86.netlify.app

Do **not** use the Discord invite link as the Play Console privacy URL. Discord
is contact only; Play needs a normal HTTPS page that shows the full policy.

In-app Dart constant: `kPrivacyPolicyPublicUrl` in
`lib/legal/legal_documents.dart`.

## Why not GitHub Pages?

The FocusNexus GitHub repository is **private**. GitHub Pages on a private repo
is not a free, simple path for a public HTTPS policy URL. This guide uses
**Netlify Drop** instead: drag a local folder, get HTTPS, no repo connection.

## Netlify Drop (primary, v1)

Netlify Drop publishes only the files you drag. Your private GitHub repo never
needs to be public, and you do **not** connect Netlify to GitHub for this flow.

### Easy Drop walkthrough

1. In the local checkout, open the folder `docs/privacy/` (it must contain
   `index.html`; that file is the page).
2. In a browser go to [https://app.netlify.com/drop](https://app.netlify.com/drop)
   (Netlify Drop). Sign in with email/GitHub/etc if asked; a free account is
   enough. Do not connect the private GitHub repo.
3. Drag the **privacy** folder (the one that contains `index.html`) onto the
   Drop zone. Do not zip it. Do not drop the whole FocusNexus repo.
4. Wait until Netlify shows a live site URL like
   `https://something-something.netlify.app`. Open that URL and confirm the
   full policy text is visible over HTTPS.
5. Copy that HTTPS URL.
6. In Play Console: the app, then **App content** (or **Store listing** /
   **Privacy policy** field), paste the URL, then save.
7. To update later: change `docs/privacy/index.html` to match
   `legal/PRIVACY_POLICY.md`, then on the Drop site use **Deploys** / drag a new
   drop of the same folder (or create a new Drop and update the Console URL if
   the hostname changes). Prefer updating the same site so the Play URL stays
   stable.

### What to paste in Play Console

Paste the current public URL:

https://sparkling-gumdrop-1d2c86.netlify.app

If you create a new Drop (new hostname), update this file,
`kPrivacyPolicyPublicUrl`, `legal/PRIVACY_POLICY.md`,
`docs/privacy/index.html`, and `docs/STORE_LISTING_DISCLAIMERS.md`, then
redeploy the HTML folder.

Open the URL in a private/incognito window before saving in Console.

### Troubleshooting

- **404 or blank page:** The dropped folder probably lacked `index.html` at its
  root (for example you dropped `docs/` or the whole repo instead of
  `docs/privacy/`).
- **Wrong text:** Edit `docs/privacy/index.html` to match
  `legal/PRIVACY_POLICY.md`, then redeploy via Drop.
- **Custom domain:** Optional and out of scope for v1. The default
  `*.netlify.app` hostname is enough for Play Console.

## Keep HTML in sync

When you bump the version in `legal/PRIVACY_POLICY.md`:

1. Update `docs/privacy/index.html` so every section matches (mirror only; do
   not invent new clauses).
2. Redeploy the `docs/privacy/` folder via Netlify Drop (step 7 above).
3. Confirm the live URL still shows the new version string.

## Later alternative (not v1)

**Cloudflare Pages** can host the same static folder if you outgrow Drop, but
Drop is the intended free path while the repo stays private.

## Related docs

- Canonical policy: [`legal/PRIVACY_POLICY.md`](../legal/PRIVACY_POLICY.md)
- Store listing disclaimers:
  [`docs/STORE_LISTING_DISCLAIMERS.md`](STORE_LISTING_DISCLAIMERS.md)
- Play Console questionnaires:
  [`PLAY_CONSOLE_OPERATOR_FORMS.md`](PLAY_CONSOLE_OPERATOR_FORMS.md)
