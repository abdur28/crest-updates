# crest-updates

Release hosting + [Sparkle](https://sparkle-project.org) auto-update feed for **Crest** (a private macOS build shared with friends).

## What's here
- `appcast.xml` — the Sparkle update feed the app checks. Its URL is baked into the app:
  `https://raw.githubusercontent.com/abdur28/crest-updates/main/appcast.xml`
- `Crest-<version>.zip` — the notarized, stapled app builds referenced by the appcast.
- `PRIVACY.md` — privacy policy (linked from the app's onboarding).
- `release.sh` + `ExportOptions.plist` — one-shot release tooling (see below).

## Publishing a new release
One-time setup (stores your Apple notarization credentials in a keychain profile named `crest-notary`):

```sh
xcrun notarytool store-credentials crest-notary \
  --apple-id "you@example.com" \
  --team-id 63849CL7RV \
  --password "app-specific-password"   # create at appleid.apple.com ▸ Sign-In & Security ▸ App-Specific Passwords
```

Then, for each release, bump the version in Xcode (Target ▸ Build Settings ▸ *Marketing Version* and *Current Project Version*) and run:

```sh
./release.sh 2.3.4
```

That archives, exports with Developer ID, notarizes + staples, zips, regenerates `appcast.xml` (signed with your Sparkle EdDSA key), then commits and pushes here. Friends' apps pick up the update automatically.
