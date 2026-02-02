# ClipPin Code Signing & Notarization Guide

This guide explains how to properly sign and notarize ClipPin using your **Paid Apple Developer Account** so it runs on any Mac without warnings.

## Prerequisites

- Paid Apple Developer Program enrollment.
- Access to [developer.apple.com](https://developer.apple.com).
- Admin access to this GitHub repository.

---

## Part 1: Generate the Certificate (One-Time Setup)

To release apps outside the App Store, you need a **Developer ID Application** certificate.

1.  Log in to [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list).
2.  Click the blue **(+)** button next to Certificates.
3.  Select **Developer ID Application** and click Continue.
    *   *Note: If you already have one and don't have the private key, you might need to revoke it and create a new one, or find the Mac that created it.*
4.  Follow the instructions to create a **Certificate Signing Request (CSR)** on your Mac:
    *   Open **Keychain Access**.
    *   Go to **Certificate Assistant** > **Request a Certificate From a Certificate Authority**.
    *   Email: Your email.
    *   Common Name: `ClipPin Developer`.
    *   Save to disk.
5.  Upload the `.certSigningRequest` file to Apple.
6.  Download the resulting `.cer` file (e.g., `developerID_application.cer`).
7.  Double-click the `.cer` file to install it into your Keychain.

## Part 2: Export Credentials for GitHub

GitHub needs your certificate and password to sign the app on its servers.

1.  Open **Keychain Access** on your Mac.
2.  Select **"My Certificates"** tab.
3.  Find proper certificate: `Developer ID Application: Your Name (XXXXXXXXXX)`.
4.  **Right-click** the certificate (ensure you select the certificate, not just the private key) and choose **Export**.
5.  Save as `certificate.p12`.
6.  **Important**: Set a strong password for this file when prompted.
7.  Convert to Base64 (Terminal):
    ```bash
    base64 -i path/to/certificate.p12 | pbcopy
    ```
    (The content is now in your clipboard).

### 🛑 Troubleshooting: "It exports as a .cer file!"

If exported as `.cer`, it means you **do not have the Private Key** on this Mac. This happens if you downloaded the certificate from Apple but created the signing request (CSR) on a *different* machine.

**The Fix:**
1.  **Revoke** the old certificate on the Apple Developer website.
2.  **Start Over from Part 1** on this machine (Create CSR -> Upload -> Download -> Install).
3.  Once installed, you should see a small arrow (▶) next to the certificate in Keychain. Expanding it should reveal the private key.
4.  Then try exporting again.

## Part 3: Generate App-Specific Password (For Notarization)

Notarization requires logging in to Apple, but we use an App-Specific Password for security.

1.  Go to [appleid.apple.com](https://appleid.apple.com).
2.  Sign in.
3.  Go to **App-Specific Passwords**.
4.  Click **(+) Maintain** -> **Generate**.
5.  Name it "GitHub Actions ClipPin".
6.  Copy the password (e.g., `abcd-efgh-ijkl-mnop`).

## Part 4: Configure GitHub Secrets

1.  Go to your GitHub Repo -> **Settings** -> **Secrets and variables** -> **Actions**.
2.  Add the following **New Repository Secrets**:

| Secret Name | Value | Description |
| :--- | :--- | :--- |
| `MACOS_CERTIFICATE` | (Paste from clipboard - Base64 string) | The .p12 file content. |
| `MACOS_CERTIFICATE_PWD` | The password you set in Part 2 Step 6. | To unlock the .p12. |
| `MACOS_CERTIFICATE_NAME` | `Developer ID Application: Your Name (TEAMID)` | The exact name as it appears in Keychain. |
| `AC_USERNAME` | `your-email@example.com` | Your Apple ID email. |
| `AC_PASSWORD` | `abcd-efgh-ijkl-mnop` | The App-Specific Password from Part 3. |
| `AC_TEAM_ID` | `XXXXXXXXXX` | Your 10-character Team ID (From Developer Portal top right). |

## Part 5: Verify the Workflow

The `.github/workflows/release.yaml` has been updated to use these secrets.
When you push a tag (e.g., `v1.2.1`), it will:
1.  **Build** the app.
2.  **Sign** it with your Developer ID (`codesign`).
3.  **Notarize** it with Apple (`xcrun notarytool`).
4.  **Staple** the ticket to the app.
5.  **Zip** and **Release** it.

---

### Verification

After a release build finishes:
1.  Download the zip.
2.  Unzip it.
3.  Run in Terminal:
    ```bash
    spctl --assess --verbose ClipPin.app
    ```
4.  It should say: `ClipPin.app: accepted source=Notarized Developer ID`.
