# GitHub Pages Setup Guide - MediShift Game

## ✅ What's Been Done

- ✅ Game exported to HTML5/WebGL
- ✅ Web build committed to `build/web/` folder
- ✅ Files pushed to `claude/ramayana-game-project-iiel8g` branch
- ✅ .gitignore updated to include web build

## 🚀 Enable GitHub Pages (3 Steps)

### Step 1: Go to Repository Settings
1. Open your repository: https://github.com/sushritha22496-lang/MediShift
2. Click **Settings** (top navigation bar)

### Step 2: Configure Pages
1. In left sidebar, click **Pages**
2. Under "Build and deployment":
   - **Source:** Select "Deploy from a branch"
   - **Branch:** Select "main" (or your default branch)
   - **Folder:** Select `/build/web`
3. Click **Save**

### Step 3: Wait for Deployment
- GitHub will automatically build and deploy
- Watch for the checkmark (✅) next to your commit
- Takes ~1-2 minutes

## 🎮 Access Your Game

Once deployed, your game will be live at:

```
https://sushritha22496-lang.github.io/MediShift/
```

Replace `sushritha22496-lang` with your GitHub username if different.

---

## 📱 Game Details

| Feature | Details |
|---------|---------|
| **Engine** | Godot 4 (HTML5/WebGL) |
| **Character** | Full 3D Hanuman with animations |
| **Gameplay** | Chapter 1: Demon guards & boss battle |
| **Controls** | WASD move, Shift run, Click attack, Space jump |
| **Features** | PWA (offline support), responsive, auto-save |
| **Size** | 41 MB total (2.5 MB compressed game data) |

---

## 🔗 Share Your Game

Once live, you can:
- **Share the link:** `https://sushritha22496-lang.github.io/MediShift/`
- **Add to README:** Include the link in your repo's README.md
- **Share on social media:** Twitter, Discord, Reddit, etc.

---

## 📊 Verify Deployment

### Check GitHub Actions (Deployment Log)
1. Go to repository
2. Click **Actions** tab
3. Look for "pages build and deployment" workflow
4. Click to see deployment details and logs

### Manual Verification
1. Open https://sushritha22496-lang.github.io/MediShift/
2. You should see the game loading
3. Check browser console (F12) for any errors

---

## 🔄 Update the Game

When you make changes:
1. Export new build in Godot: `Project → Export → Web`
2. Commit: `git add build/web/ && git commit -m "Update web build"`
3. Push: `git push`
4. GitHub automatically redeploys (1-2 min)

---

## ⚠️ Troubleshooting

### "404 Not Found"
- Wait 2-3 minutes for deployment to complete
- Check Actions tab for deployment status
- Verify folder is `/build/web` (not `/build`)

### Game Won't Load
- Open browser console (F12) for error messages
- Check that all files are in `build/web/` folder:
  - index.html ✓
  - index.js ✓
  - index.pck ✓
  - index.wasm ✓

### Blank Screen
- Check browser console for WebGL errors
- Try refreshing (Ctrl+Shift+R)
- Ensure browser supports WebGL (most modern browsers do)

---

## 💡 Pro Tips

1. **Add to README.md:**
   ```markdown
   ## 🎮 Play Online
   [Play MediShift](https://sushritha22496-lang.github.io/MediShift/)
   ```

2. **Custom Domain:**
   If you have a custom domain, Pages can use it:
   - Settings → Pages → Custom domain
   - Update DNS records (instructions provided)

3. **Analytics:**
   Use Google Analytics to track game plays

4. **Embed in Website:**
   ```html
   <iframe src="https://sushritha22496-lang.github.io/MediShift/" 
           width="800" height="600"></iframe>
   ```

---

## 📚 More Resources

- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Godot Export Documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
- [Progressive Web Apps (PWA)](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps)

---

**Status:** Ready to deploy! Your game is live in the GitHub repository.
Follow the 3 steps above to make it publicly accessible.
