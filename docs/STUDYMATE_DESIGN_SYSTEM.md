# StudyMate Design System Specification
**Official Brand Identity, UI Components, and Visual Architecture**

> **Tagline:** Study. Plan. Achieve.  
> **App Name:** StudyMate  
> **Subtitle:** Student Helper  
> **Target Platforms:** Android & iOS (Production Mobile Experience)

---

## 1. Brand Identity & Philosophy

StudyMate is an all-in-one academic productivity platform engineered specifically for modern students. Its visual language balances educational authority with an approachable, modern tech aesthetic: vibrant gradients, crisp typography, generous whitespace, and focused, distraction-free interfaces.

### Core Brand Attributes:
1. **Academic Excellence:** Crisp, trustworthy typography and structured data density.
2. **Focus & Calm:** Harmonious indigo-blue palette reducing cognitive fatigue during deep study sessions.
3. **Action-Oriented:** Prominent, high-contrast primary actions guiding students towards planning, focusing, and achieving.

---

## 2. Logo & Wordmark Specification

### Logo Geometry & Symbolism
The StudyMate logo unites the two universal hallmarks of learning into a single iconic mark:
- **Rounded Squircle Base:** Modern squircle with 22.6% corner radius filled with a 45° linear gradient from Indigo (`#6258E8`) to Vibrant Blue (`#3987F5`).
- **White Graduation Mortarboard Cap:** Diamond top angled flat with a clean geometric skullcap underneath, symbolizing graduation and academic milestones.
- **Golden Tassel:** Accent tassel in Amber (`#F59E0B`) draping from the mortarboard center button to the right edge.
- **Open Book Symbol:** Gracefully curved dual pages underneath the cap, symbolizing continuous learning, knowledge discovery, and structured study.
- **Dual-Layer Contrast:** White vector silhouettes against the indigo/blue background provide instant recognition at 16×16 px up to 1024×1024 px.

```
+--------------------------------------------------------+
|                                                        |
|                   [ Graduation Cap ]                   |
|                   \                /                   |
|                    \  * Tassel *  /                    |
|                     +------------+                     |
|                                                        |
|                     /====\  /====\                     |
|                    ( Left )( Right)                    |
|                     \====/  \====/                     |
|                   [ Open Book Symbol ]                 |
|                                                        |
|          Linear Gradient: #6258E8 -> #3987F5           |
+--------------------------------------------------------+
```

### Production Asset Manifest
| Asset Path | Format | Dimensions | Purpose |
| :--- | :---: | :---: | :--- |
| `assets/branding/studymate_logo.svg` | SVG | Scalable Vector | Clean vector rendering across all display densities |
| `assets/branding/studymate_logo.png` | PNG | 512×512 | In-app brand headers, About screen, splash |
| `assets/branding/studymate_logo_transparent.png` | PNG | 512×512 | Transparent background icon for custom layouts |
| `assets/branding/studymate_wordmark.png` | PNG | 800×240 | Horizontal brand banner for marketing & headers |
| `assets/icon/app_icon.png` | PNG | 1024×1024 | Google Play Store listing & launcher base |
| `assets/icon/app_icon_background.png` | PNG | 1024×1024 | Android Adaptive Icon Background (API 26+) |
| `assets/icon/app_icon_foreground.png` | PNG | 1024×1024 | Android Adaptive Icon Foreground (66% Safe Zone) |

---

## 3. Color Palette & Design Tokens

### Primary Brand Palette
```
#6258E8    Primary Indigo      Base brand identity, active states, key CTAs
#3987F5    Secondary Blue      Complementary gradient endpoint, link accents
#10B981    Success / Emerald   Completed tasks, high quiz scores, streak counters
#2EC4B6    Teal Accent         Topic categorization, statistics highlights
#F59E0B    Warning / Amber     Tassel accent, upcoming deadlines, exam alerts
#EF4444    Error / Crimson     Overdue alerts, reset actions, destructive buttons
```

### Neutral & Surface Tokens

#### Light Theme
- **App Background:** `#F7F7FC` (Ultra-soft cool off-white)
- **Surface / Card Background:** `#FFFFFF` (Pure white)
- **Border / Divider:** `#E2E4F0` (Subtle cool grey)
- **Primary Text:** `#1E2134` (Deep charcoal navy, high readability)
- **Secondary Text:** `#6E748E` (Muted cool grey)
- **Disabled / Hint Text:** `#A1A7C4`

#### Dark Theme
- **App Background:** `#111827` (Deep dark slate navy)
- **Surface / Card Background:** `#1F2937` (Dark navy card)
- **Border / Divider:** `#374151` (Dark subtle outline)
- **Primary Text:** `#F3F4FB` (Crisp off-white)
- **Secondary Text:** `#A1A7C4` (Soft silver grey)
- **Disabled / Hint Text:** `#6E748E`

### Gradient Tokens
- **Primary Action Gradient:** `LinearGradient(begin: topLeft, end: bottomRight, colors: [#6258E8, #3987F5])`
- **Primary Glow Shadow:** `BoxShadow(color: Color(0x406258E8), blurRadius: 14, offset: Offset(0, 4))`
- **Dark Surface Gradient:** `LinearGradient(begin: topLeft, end: bottomRight, colors: [#1F2937, #111827])`

---

## 4. Typography Scale (Inter Font Family)

StudyMate uses Google Fonts **Inter** throughout all screens. Inter offers optical sizing, tall x-height, and neutral clarity for dense academic data.

| Style Role | Font Size | Line Height | Weight | Letter Spacing | Usage |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Heading 1 (`displayLarge`)** | 32 px | 40 px | Bold (700) | -0.5 px | Splash screen, major milestone counters |
| **Heading 2 (`displayMedium`)** | 24 px | 32 px | Semibold (600) | -0.3 px | Screen titles (Login, Onboarding, Timetable) |
| **Heading 3 (`titleLarge`)** | 20 px | 28 px | Medium (500) | -0.2 px | Section headers, card titles, modal titles |
| **Title Medium (`titleMedium`)** | 16 px | 22 px | Semibold (600) | 0.0 px | List item titles, card headings |
| **Body Large (`bodyLarge`)** | 16 px | 24 px | Regular (400) | 0.1 px | Primary paragraph text, form input values |
| **Body Medium (`bodyMedium`)** | 14 px | 20 px | Regular (400) | 0.0 px | Secondary explanations, list descriptions |
| **Caption (`bodySmall`)** | 14 px | 20 px | Regular (400) | 0.2 px | Timestamps, tags, category labels, hints |
| **Button Label (`labelLarge`)** | 15 px | 20 px | Semibold (600) | 0.2 px | Interactive buttons, chips, tabs |

---

## 5. Spacing System & Grid

A strict 4px/8px incremental grid is enforced across all padding, margins, and component alignments:

- `space4`: 4 px — Inline micro-spacing (icon to text)
- `space8`: 8 px — Chip internal padding, compact gaps
- `space12`: 12 px — Medium horizontal spacing, sub-card gaps
- `space16`: 16 px — Standard card internal padding, list item gaps
- `space20`: 20 px — Card external spacing, section vertical spacing
- `space24`: 24 px — Screen horizontal margins (safe reading gutter)
- `space32`: 32 px — Section dividers, hero margins
- `space40`: 40 px — Onboarding hero spacing
- `space48`: 48 px — Large banner spacing

---

## 6. Shape & Corner Radii

- **Radius Small (`8 px`):** Category tags, subject color chips, form helper badges.
- **Radius Medium (`14 px`):** Standard cards (`AppCard`), form inputs (`AppTextField`), primary action buttons (`AppButton`).
- **Radius Large (`22–26 px`):** App logo containers, hero dialogs, floating quick-action buttons.
- **Radius Full (`999 px`):** Circular progress rings, avatar badges, status pill indicators.

---

## 7. Component Library Guidelines

### 1. AppButton
- **Primary Variant:** Full-width or auto-width filled with `AppColors.primaryGradient`, 14 px radius, subtle indigo glow shadow (`blurRadius: 12`, `alpha: 0.25`), white semibold text.
- **Outline Variant:** Transparent background, 1.5 px border matching theme border (`#E2E4F0` / `#374151`), primary or text color.
- **Secondary Variant:** Soft tinted background (`#E7F0FE` in light, `#1F2937` in dark), secondary blue text.
- **Danger Variant:** Crimson red fill (`#EF4444`), white text.

### 2. AppTextField
- **Border:** 1 px solid `#E2E4F0` (light) or `#374151` (dark).
- **Focused State:** 2 px solid `#6258E8` (primary indigo).
- **Background Fill:** Pure white in light theme, `#1F2937` in dark theme.
- **Iconography:** Leading icon in muted grey, trailing toggle (e.g. password eye) with tap feedback.

### 3. AppCard
- **Light Theme:** `#FFFFFF` fill, 1 px border `#E2E4F0`, soft ambient drop shadow (`blurRadius: 10, offset: (0, 3), alpha: 0.05`).
- **Dark Theme:** `#1F2937` fill, 1 px border `#374151`, clean flat finish without harsh glows.
- **Material Ancestry:** Clip anti-alias with transparent Material ancestor supporting ripple ink splashes.

---

## 8. Screen-by-Screen Layout Specifications

Based directly on the 30-screen Master Design Reference:

### Screen 1: Splash Screen
- **Background:** Rich full-bleed gradient `#5B4FE0` -> `#3987F5`.
- **Centerpiece:** Official StudyMate 104×104 px squircle logo with soft drop shadow.
- **Typography:** White "StudyMate" (34 px, bold) + "Student Helper" (16 px, opacity 0.88).
- **Footer:** "Study . Plan . Achieve." in spaced uppercase tracking (13 px, opacity 0.72).

### Screens 2–4: Onboarding Flow
- **Top:** Mini StudyMate brand mark (44 px).
- **Center:** Circular stylized illustration badge with dual icons (study, checklist, trophy).
- **Indicator:** 3-dot tracker; active page expands to a 26 px rounded gradient pill.
- **Action:** Full-width gradient "Next" / "Get Started" button with "Skip" text link below.

### Screens 5–6: Login & Registration
- **Header:** StudyMate logo icon + wordmark + subtitle.
- **Form:** Rounded input cards with leading iconography.
- **Social Action:** "or" divider with clean "Continue with Google" social card button.
- **Footer:** Seamless transition toggle between Login and Sign Up.

### Screens 7–9: Account Recovery & Email Verification
- **Visuals:** Circular halo badges (Mail with green checkmark, Shield/Lock with purple glow).
- **Action:** Immediate feedback and clear primary action leading back to login or dashboard.

### Screen 10: Home Dashboard
- **Header Card:** Greeting `Hello, Aman! 👋` with daily streak badge and study progress bar (e.g., `3/6 Tasks Completed - 50%`).
- **Quick Tools:** 4×2 grid of 8 rounded color-coded tool icons (Notes, Tasks, Timetable, Timer, Exams, Quiz, Calculator, Tips).
- **Widgets:** Weekly study focus chart (`fl_chart`), upcoming classes timeline, and exam countdown cards.

### Screens 11–14: Notes & Tasks
- **Categories:** Horizontal pill filter (All, Study, Personal, Other) with active indigo pill.
- **Task List:** Filterable by Today / Upcoming / Completed with priority tags (High in Red, Medium in Amber, Low in Teal).

### Screens 15–16: Timetable
- **Day Selector:** Horizontal day selector (Mon–Sun) with active day highlighted.
- **Conflict Engine:** Automatic warning dialog upon overlapping time slots.

### Screen 17: Pomodoro Focus Timer
- **Center Ring:** High-contrast 260 px circular countdown timer with gradient progress indicator.
- **Session Indicators:** 4 round indicators `( 1 ) ( 2 ) ( 3 ) ( 4 )` tracking completed rounds.
- **Controls:** Central glowing gradient Play/Pause button with secondary Reset and Skip buttons.

### Screens 18–20: Exam Countdown & Quizzes
- **Exams:** Days-remaining badge counter, nearest-date sorting.
- **Quizzes:** 4 categories (Programming, Data Structures, Algorithms, Networks) with instant score review and explanation dialogs.

### Screens 21–22: Grade Calculator & Study Tips
- **Calculator:** Percentage and multi-subject weighted average calculation with division-by-zero protection.
- **Study Tips:** 8 scientific learning methods (Feynman, Spaced Repetition, Leitner) with bookmark/favorite persistence.

### Screens 23–30: Profile, Settings, & Dark Mode
- **Theme Support:** Instant transition between Light, Dark, and System Theme.
- **Data Privacy:** Local SQLite database with per-user UID isolation, cloud sync toggle, JSON data export, and full account deletion.

---

## 9. Android System Integration & Launcher Configuration

### Package & Manifest Identity
- **Application Label:** `StudyMate`
- **Application ID:** `com.studymate.app`
- **Android Manifest:** Configured with `android:label="StudyMate"` and `@mipmap/ic_launcher`.
- **Adaptive Icon XML:** Generated in `res/mipmap-anydpi-v26/ic_launcher.xml` with solid gradient background and vector-derived foreground.
- **Permissions:** Internet, Vibrate, Notification, Exact Alarm.

---
*StudyMate Design System v1.0.0 — Production Ready*
