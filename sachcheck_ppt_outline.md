# 📊 SachDrishti — PowerPoint Presentation Outline

> **Suggested Total Slides:** 14–16 | **Duration:** 10–15 minutes

---

## 🎨 Design Tips for PPT
- **Color Scheme:** Dark background `#0D0D1A`, Accent `#6C63FF` (purple), Highlight `#00D4FF` (cyan)
- **Font:** Inter or Poppins (Google Fonts)
- **Style:** Glassmorphism cards, gradient headings, minimal text — more visuals
- **Icons:** Use emojis or Flaticon icons for each point

---

## SLIDE 1 — Title Slide

**Title:** SachDrishti — AI-Powered News Verification App

**Subtitle:** *"Sach" (सच) means Truth — See the truth clearly*

**Include:**
- App logo / icon
- Your name: Devicharan Dasari
- College name, Department, Date
- A background image or gradient (dark purple/blue)

---

## SLIDE 2 — Problem Statement

**Heading:** 📰 The Misinformation Crisis in India

**Points:**
- India has **900M+ internet users** — one of the largest in the world
- WhatsApp forwards, social media screenshots spread **fake news within minutes**
- In 2023, India ranked among the **top 5 countries for misinformation** (Reuters Institute)
- Existing fact-check websites require **manual searching** — too slow and difficult for everyday users
- No existing app lets you **verify a news screenshot instantly**

**Visual Suggestion:** A graphic showing a fake news WhatsApp forward or a stat infographic

---

## SLIDE 3 — Solution Overview

**Heading:** 💡 Introducing SachDrishti

**Points:**
- A **Flutter-based mobile app** for instant news screenshot verification
- **Snap / Upload / Share** a screenshot → get a verdict in seconds
- Uses **on-device OCR** to extract the headline (no image sent to any server)
- Cross-checks against **10+ trusted news sources** automatically
- Works in **Hindi & English** (multi-language OCR)
- Gives a confidence score: ✅ Verified / ⚠️ Caution / ❌ Not Verified

**Visual Suggestion:** A 3-step graphic: 📸 Screenshot → 🔍 Verify → ✅ Result

---

## SLIDE 4 — Core User Flow

**Heading:** 🔄 How It Works — Step by Step

**Steps (use a flowchart or numbered visual):**
1. 📸 **Capture** — Camera, Gallery, or Android Share Sheet
2. 🔍 **OCR Processing** — Google ML Kit extracts text on-device
3. ✏️ **Review Headline** — User can edit extracted headline
4. 📡 **Verification** — App queries 10 news sources simultaneously
5. 📊 **Result** — Verdict + confidence score + matched articles
6. 💾 **Save** — Stored in history, exportable as report

**Visual Suggestion:** Horizontal flowchart with icons for each step

---

## SLIDE 5 — Key Features

**Heading:** ✨ Features at a Glance

**Two-column layout:**

| 🧠 Core | 🌐 Smart Features |
|---------|------------------|
| On-device OCR (no image upload) | Hindi & English support |
| 10+ news source cross-checking | Absurdity & Hoax Detection |
| Confidence scoring system | Category Auto-Tagging |
| Visual Text Block Selector | Source Reliability Tiers |

| 🔐 Auth & Profile | 📜 History & Offline |
|------------------|---------------------|
| Email & Google Sign-In | Full verification history |
| Password reset via email | **Offline cache** (no internet needed) |
| User credibility score | Swipe to delete entries |

| 💬 Social | 📤 Export |
|-----------|----------|
| Real-time Chat Room | Share results via share sheet |
| Share verifications in chat | Export as PNG report card |
| Media sharing in chat | Copy to clipboard |

---

## SLIDE 6 — Tech Stack

**Heading:** 🛠️ Technology Stack

**Table or icon grid layout:**

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x + Dart |
| State Management | Riverpod 2.x |
| Navigation | go_router |
| OCR (On-Device) | Google ML Kit |
| Authentication | Firebase Auth + Google Sign-In |
| Cloud Database | Cloud Firestore |
| Local Storage | Hive (NoSQL, encrypted) |
| News APIs | NewsAPI, GNews, Wikipedia, DuckDuckGo, RSS |
| Animations | Lottie |
| Fonts | Google Fonts (Inter) |
| Sharing | share_plus |

**Visual Suggestion:** Technology logo grid (Firebase, Flutter, Google ML Kit, etc.)

---

## SLIDE 7 — System Architecture

**Heading:** 🏗️ System Architecture

**Architecture Diagram (describe or draw):**

```
📱 User Device
   └── [Flutter App]
         ├── Google ML Kit OCR (ON-DEVICE ← no image leaves phone)
         └── Verification Engine
               ├── Queries 10 APIs in parallel
               │     ├── Wikipedia, DuckDuckGo
               │     ├── Google News RSS, Bing News RSS
               │     ├── NDTV, Hindustan Times, India Today, TOI
               │     ├── AP/Reuters RSS
               │     └── NewsAPI.org (optional)
               └── Scoring → Verdict

☁️ Firebase
   ├── Firebase Auth (User sessions)
   └── Firestore (User profiles + Chat)

📦 Local (Hive)
   └── Verification history + Offline cache
```

**Key highlight box:** *"Images NEVER leave the device — Privacy First ✅"*

---

## SLIDE 8 — Verification Engine (Deep Dive)

**Heading:** ⚙️ How Verification Works

**7-step pipeline (numbered cards):**

1. **Absurdity Detection** — Flags hoaxes, death rumors, fake events using regex patterns
2. **Fetch Articles** — 10 sources queried simultaneously via `Future.wait()`
3. **Dice Coefficient** — Character bigram similarity (fuzzy matching)
4. **Keyword Overlap** — Weighted match of significant words (longer = higher weight)
5. **Subject Filter** — If article is about wrong subject → score penalized 75%
6. **Source Tier Weighting** — Established sources (NDTV, Reuters) score 1.0×, Wikipedia 0.55×
7. **Verdict** — Score ≥ 0.55 → ✅ Verified | 0.30–0.55 → ⚠️ Caution | < 0.30 → ❌ Not Verified

**Visual Suggestion:** Funnel diagram or numbered step cards

---

## SLIDE 9 — OCR Engine

**Heading:** 🔍 On-Device OCR — Multi-Language Support

**Points:**
- Powered by **Google ML Kit Text Recognition**
- All processing happens **on-device** — image never uploaded
- Supports **5 scripts in parallel:**

| Script | Languages |
|--------|-----------|
| Latin | English & all Latin-script languages |
| Devanagari | Hindi, Marathi, Nepal |
| Chinese | Simplified & Traditional |
| Korean | Korean |
| Japanese | Hiragana, Katakana, Kanji |

- **Headline Extraction:** Scores text blocks by size + position — picks the most prominent headline
- Filters out newspaper mastheads (NDTV logo text, TOI headers, etc.)

---

## SLIDE 10 — Database Design

**Heading:** 💾 Data Architecture

**Two sections:**

### Hive (Local — On Device)
- Stores verification history as `HistoryItem` objects
- Fields: ID, Headline, Verdict, Score, Timestamp, Image Path, Matched Articles (JSON cached)
- Enables **offline access** to past verifications

### Firebase Firestore (Cloud)
- `users/{uid}` → User profile + verification stats (totalVerifications, verifiedCount, etc.)
- `messages/{id}` → Real-time chat messages (text / image / verification share types)
- Stats updated with **atomic `FieldValue.increment()`** — no race conditions

**Visual Suggestion:** Two-box diagram showing Local (Hive) vs Cloud (Firestore)

---

## SLIDE 11 — Security & Privacy

**Heading:** 🔒 Privacy-First Design

**Key Points:**
- ✅ **Images never leave the device** — OCR runs locally via Google ML Kit
- ✅ Only the **extracted text headline** is sent to public news APIs as a search query
- ✅ Firebase Auth secures all user accounts with **email + Google OAuth**
- ✅ All API calls use **HTTPS** (end-to-end encrypted)
- ✅ Local Hive storage is **encrypted on-device**
- ✅ Sensitive files (`google-services.json`, `.env`) excluded from source code
- ✅ Full **Privacy Policy** included (required for Google Play Store)

**Visual Suggestion:** Shield icon with checklist or lock icon graphic

---

## SLIDE 12 — Screenshots / Demo

**Heading:** 📱 App Screenshots

**Include actual screenshots of:**
1. Splash / Onboarding screen
2. Home screen (Scan Now button)
3. OCR processing screen
4. Result screen (showing verdict + score)
5. History screen
6. Chat Room screen
7. Profile screen (credibility score)

> 💡 *Add a short screen recording / GIF if allowed in your presentation tool (PowerPoint supports videos)*

---

## SLIDE 13 — Development Phases

**Heading:** 🚀 Development Journey

**Timeline / 3-phase cards:**

### Phase 1 — Core Foundation ✅
Firebase Auth, OCR, Verification Engine, History, Navigation

### Phase 2 — Social & Intelligence ✅
Chat Room, Export Reports, Hoax Detection, Source Tiers, Category Tagging, Credibility Score

### Phase 3 — Offline & Accessibility ✅
Offline Cache, Android Share Sheet, Multi-language OCR, Visual Text Scanner

---

## SLIDE 14 — Future Scope

**Heading:** 🔮 Future Enhancements

**Points (use icon cards):**
- 🌐 **iOS Support** — Extend to iPhone users
- 🤖 **AI/LLM Integration** — Use Gemini API for deeper semantic analysis
- 🗣️ **Voice Input** — Speak a headline to verify
- 📊 **Trending Misinformation Dashboard** — Show what's being fact-checked most
- 🔔 **Push Notifications** — Alert when a shared article is debunked
- 🌍 **More Regional Languages** — Tamil, Telugu, Bengali, Kannada
- 🌐 **Web Extension** — Browser plugin to verify news while browsing
- 📰 **URL Verification** — Paste a news article link to verify

---

## SLIDE 15 — Conclusion

**Heading:** 🎯 Summary

**Points:**
- SachDrishti solves a **real-world problem** — fake news in India
- **Privacy-first**, on-device OCR — no image leaves the phone
- Verifies against **10 trusted news sources** with intelligent scoring
- Built with **production-grade technology** (Flutter, Firebase, Riverpod)
- Features **offline access**, multi-language support, and social sharing
- Ready for **Google Play Store** deployment

**Closing line:**
> *"In a world full of noise, SachDrishti helps you find the signal — the Sach (Truth)."*

---

## SLIDE 16 — Thank You / Q&A

**Heading:** 🙏 Thank You!

**Include:**
- Name: **Devicharan Dasari**
- GitHub: `github.com/your-username/sachcheck`
- Email: `your-email@example.com`
- App Name: **SachDrishti**
- Tagline: *"See the Truth Clearly"*
- QR Code (optional — link to your GitHub repo)

---

## 📝 Presentation Tips

| Tip | Details |
|-----|---------|
| ⏱️ Time | 10–15 min for full presentation |
| 🖼️ Visuals | Add real app screenshots to every slide possible |
| 🎬 Demo | Live demo or screen recording is very impactful on Slide 12 |
| 📌 Keep it short | Max 5–6 bullet points per slide |
| 🎯 Focus | Emphasize privacy (no image upload) + accuracy (10-source verification) |
| 💡 Differentiator | "Most fact-check tools require manual search — we automate it" |
