# StudyMate Deployment Guide (Render & Vercel)

Yeh guide aapko StudyMate web application ko **Render** ya **Vercel** par 100% free live host karne ke simple steps batati hai.

---

## 🚀 Pre-requisite: GitHub par Code Push Karein

Aapka repository remote configure hai:
`origin: https://github.com/amansharma1235/Study_mate.git`

Apne terminal me run karein:
```bash
git push origin main
```

---

## 🌐 Option 1: Render par Live Karein (Recommended)

Render par humne pehle se hi Blueprint (`render.yaml`) aur Build script (`render_build.sh`) configure kar di hai.

### Steps:
1. **Render Dashboard** par login karein: [dashboard.render.com](https://dashboard.render.com/)
2. Click karein **"New +"** -> **"Static Site"** (ya **"Blueprint"**).
3. Apna GitHub account connect karein aur repository select karein: `amansharma1235/Study_mate`.
4. Settings me verify karein (agar blueprint select kiya hai to automatic pick ho jayega):
   - **Name**: `studymate`
   - **Branch**: `main`
   - **Build Command**: `bash ./render_build.sh`
   - **Publish Directory**: `./build/web`
5. Click **"Create Static Site"**.
6. Render Flutter SDK download karega, web bundle compile karega aur aapko ek live URL dega (e.g., `https://studymate.onrender.com`).

---

## ⚡ Option 2: Vercel par Live Karein

Vercel par bhi humne zero-config `vercel.json` aur `vercel_build.sh` setup kar diya hai.

### Steps via Vercel Dashboard (GitHub):
1. **Vercel Dashboard** par login karein: [vercel.com](https://vercel.com/)
2. Click karein **"Add New..."** -> **"Project"**.
3. Apni GitHub repository `amansharma1235/Study_mate` ko **Import** karein.
4. **Build & Development Settings** me:
   - **Framework Preset**: `Other`
   - **Build Command**: `bash ./vercel_build.sh`
   - **Output Directory**: `build/web`
5. Click **"Deploy"**.
6. Vercel automatically web release create karke aapko live URL provide karega (e.g., `https://study-mate.vercel.app`).

### Direct CLI Instant Deploy (Local machine se 1-minute):
Aap pre-built web folder ko bina cloud build delay ke direct publish kar sakte hain:
```powershell
npx.cmd vercel build/web --prod
```
Aapko CLI me login prompt aayega, approve karte hi 10 seconds me live URL mil jayega!

---

## 🔍 Code Validation Summary
- `flutter analyze`: **0 issues found** (Clean)
- `flutter build web --release`: **Successfully built in 28.6s**
- Web metadata, caching rules, single-page routing, aur fallback rewrites fully tested.
