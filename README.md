# ⚔️ Git Quest: Master Your Git Skills

Welcome to **Git Quest**! This is an interactive, gamified Command Line Interface (CLI) testing suite designed to take you from a Git novice to a branching and history-rewriting wizard.

You will face **7 progressive levels** that test essential real-world Git operations:

1. **The First Step** (Init & Committing)
2. **Divergent Paths** (Branching)
3. **Joining Forces** (Merging & Conflicts)
4. **Rewriting History** (Rebasing)
5. **Stashing Work** (Stash & Switch)
6. **Reverting Blunders** (Safe Undoing)
7. **Cherry-Picking** (Hand-selecting Commits)

---

## 🚀 How to Play

### 1. Launch the Game
From the root of this project, run the main interactive CLI menu:
```bash
npm start
```
This will display the **Git Quest Dashboard** where you can select your challenge.

### 2. Enter the Challenge Folder
When you select and initialize a challenge (e.g. Level 2), the game engine will automatically build a target directory inside:
```
git-challenges/level-X-name/
```
Open a separate terminal window, `cd` into that specific folder, and read the prompt instructions printed by the game.

### 3. Run Your Git Commands
Execute the requested Git actions inside that challenge folder (e.g., initializing a repo, making commits, branching, merging).

### 4. Verify Your Work
To check if you successfully passed the level, you can run the verifier.
You can run it from **anywhere** (even inside the challenge folder itself!) by calling:
```bash
node ../../verify.js
```
The game engine will automatically detect which challenge directory you are currently working in, inspect its Git repository state, and let you know if you succeeded!

If your attempt has issues, **Git Quest** will diagnose your repository and provide helpful hints to guide you to the right solution.

---

## 🛠️ Tips for Success

- **Do NOT delete the `.git` directory** in folders that are pre-setup for you (Levels 2-7), as they contain pre-packaged histories necessary for the exercises.
- **Pay attention to details**: File names, contents, and commit messages are verified exactly.
- If you get stuck, run the verification command — the diagnostics can often point out exactly what is missing!

Good luck, future Git Master! 🚀
