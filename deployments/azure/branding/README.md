## Entra sign-in branding (partial layout)

Partial-screen branding for the standard Entra (non-B2C) sign-in page, with lightweight CSS (legacy-supported tenants only) and a one-time Terms of Use flow.

### What you need
- Favicon: 32x32px, PNG/JPG, ≤5 KB.
- Background image: 1920x1080px, PNG/JPG, ≤300 KB. Keep subject center/right; avoid text in the image.
- Banner logo: 245x36px, transparent PNG, ≤50 KB.
- Square logos: 240x240px, transparent PNG, ≤50 KB for light and dark.
- Background color: solid color matching the hero image for graceful fallback.
- Footer text: one short link label (clickable on web only; plain text in some native/embedded clients).

### Apply branding (partial)
1. Go to Entra admin center → Identity → Company branding → Edit default branding.
2. Layout: choose partial background. Upload favicon, banner, square logos, background color, and hero image.
3. Text: set concise page title, description, sign-in message, and footer text (Markdown-lite only; no HTML/emojis). Keep footer to a single short link label.
4. Localization: add language-specific branding if needed; unmatched locales fall back to default.
5. Test desktop/mobile: verify cropping (hero focus center/right), logo contrast on light/dark, and footer visibility.

### GIMP optimization (macOS)
- Favicon: open source image → Image → Scale to 32x32px → File → Export As… → PNG (uncheck metadata; keep ≤5 KB).
- Background: open source image → Image → Scale Image… to 1920x1080 → File → Save (XCF) to preserve layers → File → Export As… → JPEG with quality ~75–85, uncheck metadata; target ≤300 KB.
- Logos: keep transparent background, export as PNG; if size is high, run through pngquant/ImageOptim after export.

### Optional CSS (legacy tenants only)
- Tenants created before 2026-01-05 can upload custom CSS. Newer tenants cannot.
- Use the sample: [custom-branding.css](custom-branding.css). Keep it small, scoped, and layout-safe (no deep selectors or `!important`).
- Re-test after Entra UI updates; DOM classes can change.

### Terms of Use (one-time)
1. Entra admin center → Protection → Conditional Access → Terms of use.
2. Upload PDF (one per locale if needed). Name the version clearly.
3. Set one-time acceptance, reaccept on new version. Device-level vs account-level depends on the CA policy scope.
4. Test web and mobile sign-in; confirm acceptance records in reports.
5. Plan a yearly review: update the PDF if needed and trigger reaccept by versioning.

### Notes
- This repo is public: use placeholders for tenant URLs and do not commit secrets or real identifiers.
- Keep assets as small as possible for fast first paint; avoid busy backgrounds behind the form.
- If CSS is disabled in your tenant, use only images/colors/text fields. It can be easier and simpler to use.
