# Privacy Policy — SachDrishti

**Effective Date:** April 9, 2025
**Last Updated:** April 9, 2025

---

## 1. Introduction

Welcome to **SachDrishti** ("we", "our", or "us"). SachDrishti is a news verification application designed to help users identify misinformation. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application ("App").

By using the App, you agree to the collection and use of information in accordance with this policy.

---

## 2. Information We Collect

### 2.1 Information You Provide Directly
- **Account Information:** When you register, we collect your name, email address, and password (stored securely via Firebase Authentication).
- **Profile Information:** Display name and profile picture (if provided or imported via Google Sign-In).

### 2.2 Information Collected Automatically
- **Images & Screenshots:** Images you upload or capture within the App for OCR-based text extraction. These images are processed locally on-device using Google ML Kit and are **not stored on our servers permanently**.
- **Verification History:** The results of your news verifications (text extracted, verdict, confidence score, timestamp) are stored in your Firestore account to enable history and offline caching.
- **Usage Data:** Basic app usage information (e.g., features used) may be logged for improving app stability.

### 2.3 Information from Third-Party Services
- **Google Sign-In:** If you sign in with Google, we receive your name, email, and profile picture from Google, subject to [Google's Privacy Policy](https://policies.google.com/privacy).
- **Firebase Services:** We use Firebase Authentication, Cloud Firestore, and Firebase Analytics, subject to [Google Firebase's Privacy Policy](https://firebase.google.com/support/privacy).

---

## 3. How We Use Your Information

We use the information we collect to:

| Purpose | Data Used |
|---------|-----------|
| Create and manage your account | Email, Name, Password |
| Perform news verification (OCR) | Image / Screenshot (on-device only) |
| Store and display your verification history | Verification results, timestamps |
| Enable real-time chat features | Username, Messages |
| Authenticate your identity | Firebase Auth tokens |
| Improve app functionality | Anonymized usage data |
| Send password reset emails | Email address |

We **do not** sell, trade, or rent your personal information to third parties.

---

## 4. Camera & Storage Permissions

The App requests the following device permissions:

| Permission | Purpose |
|------------|---------|
| `CAMERA` | To capture news screenshots for OCR verification |
| `READ_EXTERNAL_STORAGE` / `READ_MEDIA_IMAGES` | To pick images from your gallery for verification |
| `INTERNET` | To connect to news APIs and Firebase services |

These permissions are used solely for the features described above. You may revoke these permissions at any time via your device settings; however, doing so may limit app functionality.

---

## 5. Data Storage & Security

- Your account data is stored securely on **Google Cloud Firestore**.
- Offline cache (recent verification results) is stored locally on your device using **Hive** encrypted storage.
- Images you upload are processed **on-device** using Google ML Kit and are not permanently uploaded to any external server.
- We implement industry-standard security practices including HTTPS encryption for all data in transit.

---

## 6. Data Retention

- **Account data** is retained as long as your account is active.
- **Verification history** is stored in Firestore until you delete it or your account.
- **Local cache** (offline history) is stored on your device and can be cleared from within the App settings.
- You may request deletion of your account and associated data by contacting us (see Section 10).

---

## 7. Children's Privacy

SachDrishti is **not directed to children under the age of 13**. We do not knowingly collect personally identifiable information from children under 13. If we discover that a child under 13 has provided personal information, we will promptly delete it.

---

## 8. Third-Party Services

Our App uses the following third-party services, each governed by their own privacy policies:

| Service | Purpose | Privacy Policy |
|---------|---------|----------------|
| Google Firebase | Authentication, Database | [Link](https://firebase.google.com/support/privacy) |
| Google ML Kit | On-device OCR | [Link](https://developers.google.com/ml-kit/terms) |
| Google Sign-In | Social Authentication | [Link](https://policies.google.com/privacy) |
| NewsAPI | News source lookup | [Link](https://newsapi.org/privacy) |
| GNews API | News verification | [Link](https://gnews.io/privacy-policy) |

---

## 9. Your Rights

Depending on your location, you may have the following rights:

- **Access:** Request a copy of the personal data we hold about you.
- **Correction:** Request correction of inaccurate data.
- **Deletion:** Request deletion of your account and associated data.
- **Portability:** Request a transfer of your data.
- **Withdrawal of Consent:** Revoke app permissions at any time via device settings.

To exercise any of these rights, please contact us at the email below.

---

## 10. Contact Us

If you have any questions, concerns, or requests regarding this Privacy Policy, please contact us:

📧 **Email:** devicharandasari019@gmail.com
🌐 **GitHub:** https://github.com/Charan-Dasari/sachcheck

---

## 11. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. We will notify you of any significant changes by updating the **"Last Updated"** date at the top of this page. Continued use of the App after changes constitutes your acceptance of the revised policy.

---

## 12. Governing Law

This Privacy Policy is governed by the laws of **India**. Any disputes arising from this policy shall be subject to the jurisdiction of Indian courts.

---

*This Privacy Policy was last updated on April 9, 2025.*
