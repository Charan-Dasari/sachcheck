# SachCheck – Complete Project Analysis & Feature Plan

## Project Overview

SachCheck is a Flutter mobile app that lets users verify news screenshots. The flow is:
**Pick/capture image → OCR text extraction → Headline editing → Multi-source news cross-check → Verdict display**

The app uses ML Kit OCR (on-device), fetches from 6 news sources (Wikipedia, DuckDuckGo, Google News RSS, Bing News, AP/Reuters, optional NewsAPI.org), and scores articles with a Dice-coefficient + keyword-overlap algorithm.

---

## 🐛 Bugs Found

### Critical

| # | Bug | File | Details |
|---|-----|------|---------|
| 1 | **Broken widget test** | [test/widget_test.dart](file:///c:/Users/devic/AndroidStudioProjects/sachcheck/test/widget_test.dart) | References `MyApp` which doesn't exist (class is [SachCheckApp](file:///c:/Users/devic/AndroidStudioProjects/sachcheck/lib/core/router.dart#67-84)). Test will never pass. |
| 2 | **Hardcoded dark-mode colors in ProcessingScreen** | `processing_screen.dart:78,122-176` | Uses `AppColors.background`, `AppColors.textPrimary`, `AppColors.textSecondary` directly instead of theme-aware variants. Looks broken in light mode. |
| 3 | **Hardcoded dark colors in invalid image dialog** | `processing_screen.dart:78-107` | Dialog uses `AppColors.surface`/`AppColors.textPrimary` hardcoded — ignores light mode. |
| 4 | **HistoryItem doesn't store matched articles** | [history_item.dart](file:///c:/Users/devic/AndroidStudioProjects/sachcheck/lib/models/history_item.dart) | When viewing history detail, there's no way to display matched articles because [HistoryItem](file:///c:/Users/devic/AndroidStudioProjects/sachcheck/lib/models/history_item.dart#5-34) only stores headline, verdict, score, and imagePath — not the `matchedArticles` list. |

### Medium

| # | Bug | File | Details |
|---|-----|------|---------|
| 5 | **`OcrService.extractText()` creates a new recognizer but also has a class-level `_recognizer`** | `ocr_service.dart:4,7-11` | The [extractText](file:///c:/Users/devic/AndroidStudioProjects/sachcheck/lib/services/ocr_service.dart#6-13) method uses the class-level `_recognizer` and closes it, but [extractWithHeadline](file:///c:/Users/devic/AndroidStudioProjects/sachcheck/lib/services/ocr_service.dart#14-52) creates a new one. If [extractText](file:///c:/Users/devic/AndroidStudioProjects/sachcheck/lib/services/ocr_service.dart#6-13) is called first, the class recognizer is closed and can't be reused. |
| 6 | **No error handling for image file not found** | [processing_screen.dart](file:///c:/Users/devic/AndroidStudioProjects/sachcheck/lib/screens/processing/processing_screen.dart), [headline_editor_screen.dart](file:///c:/Users/devic/AndroidStudioProjects/sachcheck/lib/screens/editor/headline_editor_screen.dart) | `Image.file(File(widget.imagePath))` will crash if the file was deleted (e.g., temp cache cleared). |
| 7 | **History image files use temp cache paths** | [history_item.dart](file:///c:/Users/devic/AndroidStudioProjects/sachcheck/lib/models/history_item.dart) | The `imagePath` stored is the original picker temp path which can be cleaned up by the OS. Old history items may show broken images. |
| 8 | **Onboarding "Skip" text color hardcoded to dark palette** | `onboarding_screen.dart:54` | Uses `AppColors.textSecondary` (dark palette) — nearly invisible on light backgrounds. |
| 9 | **Empty state in history uses hardcoded dark color** | `history_screen.dart:203` | `AppColors.textSecondary` used directly — doesn't adapt to light mode. |

### Low

| # | Bug | File | Details |
|---|-----|------|---------|
| 10 | **47 analyzer issues** | [analyze_output.txt](file:///c:/Users/devic/AndroidStudioProjects/sachcheck/analyze_output.txt) | 1 error (CardTheme type), 6 unused imports, ~20 deprecated `withOpacity` calls, multiple missing `const`. |
| 11 | **`adaptive_icon_foreground` set but no `adaptive_icon_background`** | `pubspec.yaml:89` | Missing background color for Android adaptive icon — may show transparent/black on some launchers. |

---

## 🔧 Improvements to Fix

### Code Quality
1. **Fix all 47 analyzer issues** — unused imports, deprecated APIs, const constructors
2. **Fix or delete the broken widget test** — write a proper smoke test
3. **Make all screens fully theme-aware** — replace hardcoded `AppColors.background`/`AppColors.surface` references with `Theme.of(context)` values
4. **Copy picked images to app storage** — so history items don't break when temp cache is cleared

### UX/Design
5. **Add loading/error states for network failures** — currently silently returns "Not Verified" on network errors; user gets no feedback
6. **Add pull-to-refresh or retry button** when verification fails due to network
7. **History detail is incomplete** — doesn't show matched articles since they aren't persisted
8. **No search/filter in history** — hard to find old verifications

### Architecture
9. **Store matched articles in Hive** — either as a JSON field or a separate Hive box, so history details are complete
10. **Add connectivity check** — show "No internet" warning before attempting verification

---

## ✨ Unique Feature Suggestions

### 1. 🔴 **Credibility Score Dashboard** (Unique)
A personal stats screen showing:
- Total verifications done
- Ratio of Verified / Caution / Not Verified
- Weekly/monthly verification trends chart
- "Misinformation exposure score" — how often the user encounters unverified news

### 2. 📋 **Text-Only Verification Mode** (Unique)
Let users paste/type a headline directly (without needing a screenshot) and verify it. Many users receive text-only forwards on WhatsApp. This makes the app useful beyond just screenshots.

### 3. 🔗 **URL Verification Mode** (Unique)
Let users paste a news article URL. The app fetches the page title, then cross-checks it the same way. Useful for verifying links shared on social media.

### 4. 📊 **Source Reliability Indicators**
Show each matched source with a trust badge:
- 🟢 Established news agency (AP, Reuters, BBC, etc.)
- 🟡 Aggregator (Google News, Bing)
- 🔵 Reference (Wikipedia)
- ⚪ User-added (NewsAPI.org results)

### 5. 🌐 **Multi-Language OCR Support**
Currently only supports Latin script. Add Hindi (Devanagari), Bengali, Tamil, and other Indian scripts — critical since much misinformation in India spreads in regional languages.

### 6. 📱 **Share Sheet Integration** (Android Intent Filter)
Register a share target so users can share screenshots directly from WhatsApp/Gallery/Chrome to SachCheck without opening the app first. This is a major UX improvement.

### 7. 🔔 **Trending Misinformation Feed**
A screen showing currently-trending fact-check topics from sources like Google Fact Check API or IFCN (International Fact-Checking Network). Helps users proactively check common misinformation.

### 8. 🏷️ **Category Tags on Results**
Auto-tag verified news by category: Politics, Health, Science, Finance, Sports. This helps in the history view and adds analytical value.

### 9. 📤 **Export/Report Feature**
Let users generate a shareable verification report (as an image card) that shows the headline, verdict badge, match score, and sources — designed for sharing on social media to combat misinformation.

### 10. 🔒 **Offline Cache for Recent Verifications**
Cache the last N verification results so users can review them even without internet.

---

## Recommended Priority Order

Based on impact and effort, here's my suggested implementation order:

### Phase 1 — Bug Fixes & Polish (Do first)
- [ ] Fix all 47 analyzer issues (unused imports, deprecated APIs, const)
- [ ] Fix hardcoded dark-mode colors in [ProcessingScreen](file:///c:/Users/devic/AndroidStudioProjects/sachcheck/lib/screens/processing/processing_screen.dart#8-15) and [OnboardingScreen](file:///c:/Users/devic/AndroidStudioProjects/sachcheck/lib/screens/onboarding/onboarding_screen.dart#6-12)
- [ ] Fix/rewrite the broken widget test
- [ ] Add `adaptive_icon_background` to pubspec.yaml
- [ ] Copy picked images to app-local storage so history images survive cache clearing

### Phase 2 — Missing Core Features
- [ ] **Text-Only Verification Mode** — paste/type a headline to verify without a screenshot
- [ ] **Store matched articles in history** — update [HistoryItem](file:///c:/Users/devic/AndroidStudioProjects/sachcheck/lib/models/history_item.dart#5-34) model + Hive migration
- [ ] **Network error handling** — show retry button, connectivity detection
- [ ] **Search & filter in History** — filter by verdict, search by keyword

### Phase 3 — Unique/Standout Features
- [ ] **Share Sheet Integration** — register as Android share target for images
- [ ] **Credibility Score Dashboard** — personal stats and trends
- [ ] **Export Verification Report** — shareable image card with verdict
- [ ] **Multi-Language OCR** — Hindi, Bengali scripts support
- [ ] **URL Verification Mode** — verify by pasting a news article URL

---

## Verification Plan

### Automated Tests
- Fix [test/widget_test.dart](file:///c:/Users/devic/AndroidStudioProjects/sachcheck/test/widget_test.dart) to reference [SachCheckApp](file:///c:/Users/devic/AndroidStudioProjects/sachcheck/lib/core/router.dart#67-84) with a `ProviderScope` and Hive initialization mock
- Run `flutter analyze` — must report 0 errors, 0 warnings
- Run `flutter test` — all tests must pass

### Manual Verification
- Test in both light and dark mode on emulator to verify theme-awareness
- Test processing screen with valid news screenshots
- Test processing screen with non-news images (cat photos, blank pages)
- Test history image persistence after clearing app cache
- Test with airplane mode to verify network error UI
- Test on tablet-sized emulator to verify responsive layouts

---

> [!IMPORTANT]
> Please review this analysis and tell me **which features from the list you'd like to implement first**. I can start working on any Phase or individual item immediately. Also let me know if you have your own feature ideas you want to add!
