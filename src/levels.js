import fs from 'node:fs';
import path from 'node:path';
import { 
  runGitCommand, 
  isGitRepo, 
  getActiveBranch, 
  readFileContent, 
  writeFileContent,
  colors,
  style
} from './utils.js';

// Setup basic git configuration in a directory to prevent config errors
function initAndConfigureGit(dir) {
  if (fs.existsSync(dir)) {
    fs.rmSync(dir, { recursive: true, force: true });
  }
  fs.mkdirSync(dir, { recursive: true });
  
  runGitCommand('init', dir);
  runGitCommand('config user.name "Git Student"', dir);
  runGitCommand('config user.email "student@gitquest.edu"', dir);
  runGitCommand('config commit.gpgSign false', dir);
  
  // Set default branch name to 'main' locally to ensure consistency
  runGitCommand('config core.defaultBranch main', dir);
}

// Find default branch name (usually main or master)
function getBaseBranch(dir) {
  const branches = runGitCommand('branch --list', dir);
  if (branches.failed) return 'main';
  
  // Check if main exists
  if (branches.includes('main') || branches.includes('* main')) return 'main';
  if (branches.includes('master') || branches.includes('* master')) return 'master';
  
  // Return current branch
  const active = getActiveBranch(dir);
  return active || 'main';
}

export const levels = [
  {
    id: 1,
    name: "The First Step",
    dirName: "level-1-basics",
    tagline: "Initialization and Committing",
    objectives: [
      "Initialize a new Git repository in this folder.",
      "Create a file named hello.txt containing the exact text 'Hello, Git!'.",
      "Stage the hello.txt file.",
      "Commit the file with the message 'Initial commit'."
    ],
    setup: (dir) => {
      // Just ensure directory is empty
      if (fs.existsSync(dir)) {
        fs.rmSync(dir, { recursive: true, force: true });
      }
      fs.mkdirSync(dir, { recursive: true });
      
      writeFileContent(
        path.join(dir, 'README.txt'),
        "Welcome to Level 1!\n\nRead the objectives in your terminal and complete the tasks in this folder."
      );
    },
    verify: (dir) => {
      const hints = [];
      
      if (!isGitRepo(dir)) {
        return {
          success: false,
          message: "The folder is not a Git repository yet.",
          hints: ["Run 'git init' inside the folder to initialize it."]
        };
      }
      
      const helloPath = path.join(dir, 'hello.txt');
      if (!fs.existsSync(helloPath)) {
        return {
          success: false,
          message: "The file 'hello.txt' could not be found.",
          hints: ["Create a file named exactly 'hello.txt' in the level-1-basics folder."]
        };
      }
      
      const content = readFileContent(helloPath)?.trim();
      if (content !== 'Hello, Git!') {
        return {
          success: false,
          message: `The content of 'hello.txt' is incorrect. Expected 'Hello, Git!' but got '${content || ''}'.`,
          hints: ["Open 'hello.txt' in an editor and make sure it has exactly: Hello, Git!"]
        };
      }
      
      // Check for commits
      const logResult = runGitCommand('log --oneline', dir);
      if (logResult.failed) {
        return {
          success: false,
          message: "No commits found in the repository.",
          hints: [
            "Use 'git add hello.txt' to stage the file.",
            "Use 'git commit -m \"Initial commit\"' to make your first commit."
          ]
        };
      }
      
      const commitMsg = runGitCommand('log -1 --pretty=%B', dir).toLowerCase();
      if (!commitMsg.includes('initial commit')) {
        hints.push("While not strictly breaking, it's good practice to use the requested commit message: 'Initial commit'. Try renaming the commit with 'git commit --amend -m \"Initial commit\"'.");
      }
      
      // Verify hello.txt is committed
      const showFiles = runGitCommand('ls-tree --name-only -r HEAD', dir);
      if (!showFiles.includes('hello.txt')) {
        return {
          success: false,
          message: "The file 'hello.txt' is created but has not been committed.",
          hints: [
            "Stage hello.txt with 'git add hello.txt'.",
            "Commit it with 'git commit -m \"Initial commit\"' or amend your previous commit with 'git commit --amend --no-edit' if you already committed."
          ]
        };
      }
      
      return {
        success: true,
        message: "Congratulations! You successfully initialized a repository, created a file, staged it, and committed it!",
        hints
      };
    }
  },
  {
    id: 2,
    name: "Divergent Paths",
    dirName: "level-2-branching",
    tagline: "Branching Out",
    objectives: [
      "Create a new branch named 'feature-login'.",
      "Switch to the 'feature-login' branch.",
      "Create a file named 'login.js' containing: console.log('Login initialized');",
      "Stage and commit 'login.js' with the message 'Implement authentication logic'.",
      "Do NOT merge it back to the main branch yet!"
    ],
    setup: (dir) => {
      initAndConfigureGit(dir);
      
      // Create initial main commit
      writeFileContent(
        path.join(dir, 'index.html'),
        `<!DOCTYPE html>
<html>
<head><title>My Awesome Site</title></head>
<body><h1>Under Construction</h1></body>
</html>`
      );
      
      runGitCommand('add index.html', dir);
      runGitCommand('commit -m "Initial commit on main"', dir);
    },
    verify: (dir) => {
      if (!isGitRepo(dir)) {
        return {
          success: false,
          message: "Git repository not found. Did you delete the .git folder?",
          hints: ["Please restart the level from the Git Quest main menu to reset the setup."]
        };
      }
      
      const baseBranch = getBaseBranch(dir);
      const activeBranch = getActiveBranch(dir);
      
      // Verify branch 'feature-login' exists
      const branches = runGitCommand('branch --list', dir);
      if (!branches.includes('feature-login')) {
        return {
          success: false,
          message: "The branch 'feature-login' could not be found.",
          hints: [
            "Create the branch using 'git branch feature-login' or 'git checkout -b feature-login'."
          ]
        };
      }
      
      // Verify user is on feature-login
      if (activeBranch !== 'feature-login') {
        return {
          success: false,
          message: `You are currently on branch '${activeBranch}'. You should be on 'feature-login'.`,
          hints: [
            "Switch to the branch using 'git checkout feature-login' or 'git switch feature-login'."
          ]
        };
      }
      
      // Verify login.js exists
      const loginPath = path.join(dir, 'login.js');
      if (!fs.existsSync(loginPath)) {
        return {
          success: false,
          message: "The file 'login.js' is missing on the 'feature-login' branch.",
          hints: ["Create 'login.js' with: console.log('Login initialized');"]
        };
      }
      
      // Verify content of login.js
      const content = readFileContent(loginPath)?.trim();
      if (!content.includes("Login initialized")) {
        return {
          success: false,
          message: "The content of 'login.js' does not contain: console.log('Login initialized');",
          hints: ["Open 'login.js' and write: console.log('Login initialized');"]
        };
      }
      
      // Verify committed on feature-login
      const showFiles = runGitCommand('ls-tree --name-only -r HEAD', dir);
      if (!showFiles.includes('login.js')) {
        return {
          success: false,
          message: "'login.js' is created but not committed on the 'feature-login' branch.",
          hints: [
            "Stage with 'git add login.js'.",
            "Commit with 'git commit -m \"Implement authentication logic\"'."
          ]
        };
      }
      
      // Verify login.js is NOT on baseBranch (meaning they didn't merge early or do the work on main)
      const baseFiles = runGitCommand(`ls-tree --name-only -r ${baseBranch}`, dir);
      if (baseFiles.includes('login.js')) {
        return {
          success: false,
          message: `The file 'login.js' was committed on the '${baseBranch}' branch. It should only be committed on 'feature-login'.`,
          hints: [
            "You might have committed on the main branch first.",
            "Try checking out main, resetting the commit, and then committing on feature-login.",
            "If it gets too messy, reset the level from the Git Quest main menu."
          ]
        };
      }
      
      return {
        success: true,
        message: "Excellent branching skills! You created, isolated, and committed work on a feature branch successfully.",
        hints: []
      };
    }
  },
  {
    id: 3,
    name: "Joining Forces",
    dirName: "level-3-merging",
    tagline: "Merging & Conflict Resolution",
    objectives: [
      "Merge the branch 'feature-about' into your current branch (main/master).",
      "You will encounter a merge conflict in 'index.html' — do not panic!",
      "Manually open 'index.html', resolve the conflict so that BOTH changes (the welcome message and the about section) are preserved.",
      "Remove all Git conflict markers (<<<<<<<, =======, >>>>>>>).",
      "Stage the resolved 'index.html' file.",
      "Commit the merge to complete the task."
    ],
    setup: (dir) => {
      initAndConfigureGit(dir);
      
      // 1. Create index.html on main
      const originalHtml = `<!DOCTYPE html>
<html>
<head><title>Git Quest Portal</title></head>
<body>
  <h1>Welcome to Git Quest</h1>
  <!-- WELCOME_MESSAGE -->
  <!-- ABOUT_SECTION -->
</body>
</html>`;
      writeFileContent(path.join(dir, 'index.html'), originalHtml);
      runGitCommand('add index.html', dir);
      runGitCommand('commit -m "Initial commit on main"', dir);
      
      // 2. Create feature-about branch and make commit
      runGitCommand('checkout -b feature-about', dir);
      const featureHtml = `<!DOCTYPE html>
<html>
<head><title>Git Quest Portal</title></head>
<body>
  <h1>Welcome to Git Quest</h1>
  <!-- WELCOME_MESSAGE -->
  <h2>About Git Quest</h2>
  <p>This is a simulated portal to test Git merge conflicts.</p>
</body>
</html>`;
      writeFileContent(path.join(dir, 'index.html'), featureHtml);
      runGitCommand('add index.html', dir);
      runGitCommand('commit -m "Add about section to index"', dir);
      
      // 3. Switch back to main and make conflicting commit
      const baseBranch = getBaseBranch(dir);
      runGitCommand(`checkout ${baseBranch}`, dir);
      
      const conflictingHtml = `<!DOCTYPE html>
<html>
<head><title>Git Quest Portal</title></head>
<body>
  <h1>Welcome to Git Quest</h1>
  <p>Enjoy your training session today!</p>
  <!-- ABOUT_SECTION -->
</body>
</html>`;
      writeFileContent(path.join(dir, 'index.html'), conflictingHtml);
      runGitCommand('add index.html', dir);
      runGitCommand('commit -m "Update welcome message on main"', dir);
    },
    verify: (dir) => {
      if (!isGitRepo(dir)) {
        return {
          success: false,
          message: "Git repository not found.",
          hints: ["Please reset the level in the main menu."]
        };
      }
      
      const activeBranch = getActiveBranch(dir);
      
      // Check if they are still on main/master
      const baseBranch = getBaseBranch(dir);
      if (activeBranch !== baseBranch) {
        return {
          success: false,
          message: `You are on branch '${activeBranch}'. You should merge 'feature-about' INTO '${baseBranch}'.`,
          hints: [`Switch back to ${baseBranch} using 'git checkout ${baseBranch}' and then try the merge.`]
        };
      }
      
      // Check if merge is in progress (if they haven't committed yet)
      const mergeHeadExists = fs.existsSync(path.join(dir, '.git', 'MERGE_HEAD'));
      if (mergeHeadExists) {
        return {
          success: false,
          message: "You are currently in the middle of a merge conflict. The merge is not completed.",
          hints: [
            "Open 'index.html' and resolve the conflicts manually.",
            "Remove all conflict markers (<<<<<<<, =======, >>>>>>>).",
            "Stage the file with 'git add index.html'.",
            "Finish the merge by running 'git commit' with no arguments."
          ]
        };
      }
      
      // Verify feature-about is an ancestor of main (which proves they merged it)
      const isAncestor = runGitCommand('merge-base --is-ancestor refs/heads/feature-about HEAD', dir);
      if (isAncestor.failed) {
        return {
          success: false,
          message: "Branch 'feature-about' has not been merged into the active branch.",
          hints: [`Run 'git merge feature-about' on the ${baseBranch} branch.`]
        };
      }
      
      // Verify it was a merge commit (has 2 parents)
      const parents = runGitCommand('rev-parse HEAD^2', dir);
      if (parents.failed) {
        return {
          success: false,
          message: "The latest commit is not a merge commit.",
          hints: [
            "Did you delete commits or fast-forward?",
            "Make sure you run 'git merge feature-about' and complete it as a merge commit."
          ]
        };
      }
      
      // Verify conflict markers are gone
      const htmlContent = readFileContent(path.join(dir, 'index.html'));
      if (htmlContent.includes('<<<<<<<') || htmlContent.includes('=======') || htmlContent.includes('>>>>>>>')) {
        return {
          success: false,
          message: "The file 'index.html' still contains Git conflict markers.",
          hints: ["Open 'index.html' and remove the conflict markers line-by-line, keeping only the final code."]
        };
      }
      
      // Verify both contents are preserved
      if (!htmlContent.includes('Enjoy your training session today!') || !htmlContent.includes('This is a simulated portal to test Git merge conflicts.')) {
        return {
          success: false,
          message: "The resolved 'index.html' does not contain both branch changes.",
          hints: [
            "Make sure you keep the Welcome Message (from main) AND the About Section (from feature-about).",
            "You can reset the challenge and start over if you accidentally lost the changes."
          ]
        };
      }
      
      return {
        success: true,
        message: "Spectacular! You successfully initiated a merge, resolved a tricky conflict, and committed the result!",
        hints: []
      };
    }
  },
  {
    id: 4,
    name: "Rewriting History",
    dirName: "level-4-rebasing",
    tagline: "Linearizing with Rebasing",
    objectives: [
      "Ensure you are on the branch 'feature-payment'.",
      "Rebase 'feature-payment' onto the 'main' (or 'master') branch.",
      "Verify that the history is linear (no merge commits) and that your payment feature commits sit on top of the main commits."
    ],
    setup: (dir) => {
      initAndConfigureGit(dir);
      
      // 1. Main initial
      writeFileContent(path.join(dir, 'app.js'), 'console.log("Starting server...");\n');
      runGitCommand('add app.js', dir);
      runGitCommand('commit -m "Initial skeleton"', dir);
      
      // 2. Branch feature-payment
      runGitCommand('checkout -b feature-payment', dir);
      writeFileContent(path.join(dir, 'app.js'), 'console.log("Starting server...");\nconsole.log("Payment module activated!");\n');
      runGitCommand('add app.js', dir);
      runGitCommand('commit -m "Add payment feature"', dir);
      
      // 3. Main new commit
      const baseBranch = getBaseBranch(dir);
      runGitCommand(`checkout ${baseBranch}`, dir);
      writeFileContent(path.join(dir, 'config.json'), '{\n  "port": 3000,\n  "env": "production"\n}\n');
      runGitCommand('add config.json', dir);
      runGitCommand('commit -m "Add system configuration"', dir);
      
      // 4. Return to feature-payment
      runGitCommand('checkout feature-payment', dir);
    },
    verify: (dir) => {
      if (!isGitRepo(dir)) {
        return { success: false, message: "Git repository not found.", hints: [] };
      }
      
      const activeBranch = getActiveBranch(dir);
      if (activeBranch !== 'feature-payment') {
        return {
          success: false,
          message: `You are currently on branch '${activeBranch}'. You should be on 'feature-payment'.`,
          hints: ["Switch to 'feature-payment' using 'git checkout feature-payment'."]
        };
      }
      
      const baseBranch = getBaseBranch(dir);
      
      // Check if config.json exists on feature-payment (which means they rebased/merged)
      const configExists = fs.existsSync(path.join(dir, 'config.json'));
      if (!configExists) {
        return {
          success: false,
          message: "The commit from 'main' (which added 'config.json') is not in your current branch.",
          hints: [`Rebase 'feature-payment' onto '${baseBranch}' with 'git rebase ${baseBranch}'.`]
        };
      }
      
      // Check if they merged instead of rebased
      // We check for merge commits in feature-payment's history since splitting from the base initial commit
      const historyLog = runGitCommand('log --merges --oneline', dir);
      if (historyLog && historyLog.length > 0) {
        return {
          success: false,
          message: "We detected merge commits in your history. You used 'git merge' instead of 'git rebase'!",
          hints: [
            "Rebasing leaves a clean, linear history. Merging creates a merge commit.",
            "Please reset the level in the main menu and perform 'git rebase' instead."
          ]
        };
      }
      
      // Check that the rebase sits on top of config.json commit
      // The parent of the "Add payment feature" commit should contain the "Add system configuration" changes
      const commitsOnPayment = runGitCommand('log --oneline', dir).split('\n');
      if (commitsOnPayment.length < 3) {
        return {
          success: false,
          message: "The commit history has fewer commits than expected.",
          hints: ["Did you accidentally delete your commits? Reset the level and try again."]
        };
      }
      
      return {
        success: true,
        message: "Outstanding! You rebased your feature branch cleanly, resulting in a beautiful, linear history.",
        hints: []
      };
    }
  },
  {
    id: 5,
    name: "Stashing Work",
    dirName: "level-5-stashing",
    tagline: "The Secret Pocket",
    objectives: [
      "Notice that 'server.js' has dirty, uncommitted changes.",
      "Stash your changes safely using Git stash.",
      "Create and switch to a new branch named 'hotfix'.",
      "Create a file named 'hotfix.txt' with content: URGENT FIX",
      "Stage and commit 'hotfix.txt' as 'Apply emergency hotfix'.",
      "Switch back to the main (or master) branch.",
      "Restore (pop) your stashed changes to resume your work on 'server.js'!"
    ],
    setup: (dir) => {
      initAndConfigureGit(dir);
      
      // 1. Initial commit
      writeFileContent(path.join(dir, 'server.js'), 'console.log("Server listening...");\n');
      runGitCommand('add server.js', dir);
      runGitCommand('commit -m "Initialize server file"', dir);
      
      // 2. Add dirty changes
      fs.appendFileSync(path.join(dir, 'server.js'), '// TODO: Implement API endpoints\nconsole.log("API active");\n');
    },
    verify: (dir) => {
      if (!isGitRepo(dir)) {
        return { success: false, message: "Git repository not found.", hints: [] };
      }
      
      const activeBranch = getActiveBranch(dir);
      const baseBranch = getBaseBranch(dir);
      
      // Verify hotfix branch exists
      const branchList = runGitCommand('branch --list', dir);
      if (!branchList.includes('hotfix')) {
        return {
          success: false,
          message: "The 'hotfix' branch was not found.",
          hints: ["Create it with 'git checkout -b hotfix' (after stashing your changes on main!)."]
        };
      }
      
      // Verify hotfix has the commit
      const hotfixFiles = runGitCommand('ls-tree --name-only -r refs/heads/hotfix', dir);
      if (!hotfixFiles.includes('hotfix.txt')) {
        return {
          success: false,
          message: "'hotfix.txt' was not committed on the 'hotfix' branch.",
          hints: [
            "Switch to the hotfix branch, create hotfix.txt, stage it, and commit it.",
            "Then checkout main/master again."
          ]
        };
      }
      
      // Verify active branch is main/master
      if (activeBranch !== baseBranch) {
        return {
          success: false,
          message: `You are on branch '${activeBranch}'. You should switch back to '${baseBranch}'.`,
          hints: [`Run 'git checkout ${baseBranch}' to return to main.`]
        };
      }
      
      // Verify server.js has the dirty work back (popped)
      const serverContent = readFileContent(path.join(dir, 'server.js'));
      if (!serverContent.includes('TODO: Implement API endpoints')) {
        return {
          success: false,
          message: "Your uncommitted changes in 'server.js' are missing.",
          hints: [
            "Did you forget to pop your stash?",
            "Run 'git stash pop' to restore your dirty edits onto the main branch."
          ]
        };
      }
      
      // Verify stash is popped (stash list should be empty or have decreased)
      const stashList = runGitCommand('stash list', dir);
      if (stashList && stashList.length > 0) {
        // If they did git stash apply, it leaves the stash in the list.
        // We will accept it, but warn them to clean it up.
        return {
          success: true,
          message: "Nice! You stashed, created a hotfix branch, committed, and restored your work successfully!",
          hints: ["Tip: You used 'git stash apply' which kept the stash in history. Use 'git stash pop' next time, or run 'git stash clear' now to clean up!"]
        };
      }
      
      return {
        success: true,
        message: "Brilliant stashing! You safely stashed uncommitted edits, resolved a hotfix on another branch, returned, and restored your work cleanly.",
        hints: []
      };
    }
  },
  {
    id: 6,
    name: "Reverting Blunders",
    dirName: "level-6-reverting",
    tagline: "Safe History Rollbacks",
    objectives: [
      "Examine your commit history with 'git log'.",
      "Find the buggy commit: 'Optimize calculator operations (BUGGY)'.",
      "Revert ONLY that buggy commit using 'git revert'.",
      "Do NOT use 'git reset' because we want to preserve the history of other commits (like the README update)!"
    ],
    setup: (dir) => {
      initAndConfigureGit(dir);
      
      // 1. First commit
      writeFileContent(
        path.join(dir, 'calculator.js'), 
        'function add(a, b) {\n  return a + b;\n}\n\nmodule.exports = { add };\n'
      );
      runGitCommand('add calculator.js', dir);
      runGitCommand('commit -m "Initial calculator release"', dir);
      
      // 2. Second buggy commit
      writeFileContent(
        path.join(dir, 'calculator.js'), 
        'function add(a, b) {\n  throw new Error("Critical performance error!"); // BUGGY\n}\n\nmodule.exports = { add };\n'
      );
      runGitCommand('add calculator.js', dir);
      runGitCommand('commit -m "Optimize calculator operations (BUGGY)"', dir);
      
      // 3. Third unrelated commit
      writeFileContent(
        path.join(dir, 'README.md'),
        '# Calculator Project\nA high-performance calculator.\n'
      );
      runGitCommand('add README.md', dir);
      runGitCommand('commit -m "Update README documentation"', dir);
    },
    verify: (dir) => {
      if (!isGitRepo(dir)) {
        return { success: false, message: "Git repository not found.", hints: [] };
      }
      
      const commits = runGitCommand('log --oneline', dir);
      
      // Verify "Optimize calculator operations (BUGGY)" still exists in history (meaning they didn't reset)
      if (!commits.includes("Optimize calculator operations (BUGGY)")) {
        return {
          success: false,
          message: "The buggy commit is missing from history. Did you use 'git reset'?",
          hints: [
            "In collaborative environments, deleting shared commits with 'git reset' is dangerous.",
            "You must keep the buggy commit in history and use 'git revert' instead.",
            "Reset the level and try 'git revert <commit-hash>'."
          ]
        };
      }
      
      // Verify "Update README documentation" still exists in history (meaning they didn't wipe recent commits)
      if (!commits.includes("Update README documentation")) {
        return {
          success: false,
          message: "The README commit is missing. Did you roll back the history?",
          hints: [
            "We want to keep the README changes!",
            "Reset the level and use 'git revert' to undo ONLY the buggy commit."
          ]
        };
      }
      
      // Verify latest commit contains "Revert"
      const latestCommit = runGitCommand('log -1 --pretty=%B', dir);
      if (!latestCommit.toLowerCase().includes('revert')) {
        return {
          success: false,
          message: "We couldn't find a revert commit on top of your history.",
          hints: [
            "Run 'git log' to find the commit hash of the buggy commit.",
            "Run 'git revert <buggy-commit-hash>'."
          ]
        };
      }
      
      // Verify calculator.js doesn't contain buggy line
      const calcContent = readFileContent(path.join(dir, 'calculator.js'));
      if (calcContent.includes('Critical performance error!')) {
        return {
          success: false,
          message: "'calculator.js' still contains the buggy lines of code.",
          hints: [
            "Make sure your revert completed successfully and resolved the bug.",
            "Check 'calculator.js' content."
          ]
        };
      }
      
      return {
        success: true,
        message: "Outstanding! You reverted the bug cleanly, preserving all subsequent work and maintaining a clear history trail.",
        hints: []
      };
    }
  },
  {
    id: 7,
    name: "Cherry-Picking",
    dirName: "level-7-cherrypick",
    tagline: "Hand-Selecting Commits",
    objectives: [
      "Switch to the branch 'development' and run 'git log' to find the commits.",
      "Locate the commit message: 'Fix security exploit in auth'. Copy its commit hash.",
      "Switch back to your 'main' (or 'master') branch.",
      "Cherry-pick ONLY that specific commit onto 'main'.",
      "Do NOT merge the rest of the development commits ('Add developer debug log', 'WIP unfinished dashboard') into main."
    ],
    setup: (dir) => {
      initAndConfigureGit(dir);
      
      // 1. Main initial
      writeFileContent(
        path.join(dir, 'index.js'),
        'console.log("App booting...");\n'
      );
      runGitCommand('add index.js', dir);
      runGitCommand('commit -m "Initial commit"', dir);
      
      // 2. Development branch
      runGitCommand('checkout -b development', dir);
      
      // Dev Commit 1: Add log
      writeFileContent(path.join(dir, 'logger.js'), 'console.log("[DEBUG] Dev logger loaded");\n');
      runGitCommand('add logger.js', dir);
      runGitCommand('commit -m "Add developer debug log"', dir);
      
      // Dev Commit 2: Security exploit fix
      writeFileContent(
        path.join(dir, 'auth.js'),
        'function authenticate(user, pass) {\n  if (!user || !pass) return false;\n  // SECURE CRYPTO FIX IMPLEMENTED HERE\n  return true;\n}\n\nmodule.exports = { authenticate };\n'
      );
      runGitCommand('add auth.js', dir);
      runGitCommand('commit -m "Fix security exploit in auth"', dir);
      
      // Dev Commit 3: WIP dashboard
      writeFileContent(path.join(dir, 'dashboard.js'), 'console.log("WIP Dashboard UI elements...");\n');
      runGitCommand('add dashboard.js', dir);
      runGitCommand('commit -m "WIP unfinished dashboard"', dir);
      
      // Return to main
      const baseBranch = getBaseBranch(dir);
      runGitCommand(`checkout ${baseBranch}`, dir);
    },
    verify: (dir) => {
      if (!isGitRepo(dir)) {
        return { success: false, message: "Git repository not found.", hints: [] };
      }
      
      const activeBranch = getActiveBranch(dir);
      const baseBranch = getBaseBranch(dir);
      
      if (activeBranch !== baseBranch) {
        return {
          success: false,
          message: `You are on branch '${activeBranch}'. You should be on '${baseBranch}' to cherry-pick onto it.`,
          hints: [`Switch back to ${baseBranch} using 'git checkout ${baseBranch}'.`]
        };
      }
      
      // Check that auth.js exists on main
      const authPath = path.join(dir, 'auth.js');
      if (!fs.existsSync(authPath)) {
        return {
          success: false,
          message: "The security fix file 'auth.js' is missing from the main branch.",
          hints: [
            "Switch to the 'development' branch.",
            "Run 'git log' to find the commit hash for 'Fix security exploit in auth'.",
            `Switch back to '${baseBranch}' and run 'git cherry-pick <hash>'.`
          ]
        };
      }
      
      // Verify that logger.js and dashboard.js do NOT exist on main (which means they didn't do git merge)
      const loggerExists = fs.existsSync(path.join(dir, 'logger.js'));
      const dashboardExists = fs.existsSync(path.join(dir, 'dashboard.js'));
      
      if (loggerExists || dashboardExists) {
        return {
          success: false,
          message: "We found other development commits (logger or dashboard files) on the main branch.",
          hints: [
            "It looks like you merged the entire 'development' branch instead of cherry-picking just the single commit.",
            "Reset the level and cherry-pick ONLY the security fix commit."
          ]
        };
      }
      
      // Verify the cherry-picked commit message exists in main history
      const mainCommits = runGitCommand('log --oneline', dir);
      if (!mainCommits.includes("Fix security exploit in auth")) {
        return {
          success: false,
          message: "We couldn't verify the cherry-picked commit in history.",
          hints: ["Make sure the cherry-picked commit message matches: 'Fix security exploit in auth'."]
        };
      }
      
      return {
        success: true,
        message: "Masterful cherry-picking! You cleanly hand-selected a critical fix from development to production without merging unfinished work.",
        hints: []
      };
    }
  }
];
