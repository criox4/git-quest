# PowerShell Runner for Git Quest

# Setup helper for coloring
function Write-Color {
    param (
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::White,
        [bool]$Bold = $false
    )
    Write-Host $Message -ForegroundColor $Color
}

function Draw-Box {
    param (
        [string[]]$Lines,
        [ConsoleColor]$Color = [ConsoleColor]::Cyan
    )
    $maxLen = 0
    foreach ($line in $Lines) {
        if ($line.Length -gt $maxLen) {
            $maxLen = $line.Length
        }
    }
    
    $horizontal = "─" * ($maxLen + 2)
    $topBorder = "╭" + $horizontal + "╮"
    $bottomBorder = "╰" + $horizontal + "╯"
    
    Write-Host $topBorder -ForegroundColor $Color
    foreach ($line in $Lines) {
        $spaceRight = $maxLen - $line.Length
        $padding = " " * $spaceRight
        Write-Host "│ " -ForegroundColor $Color -NoNewline
        Write-Host $line -NoNewline
        Write-Host "$padding │" -ForegroundColor $Color
    }
    Write-Host $bottomBorder -ForegroundColor $Color
}

function Print-Trophy {
    param (
        [string]$LevelName
    )
    Write-Host ""
    Write-Color "      .---.      " -Color Yellow -Bold $true
    Write-Color "     /     \     " -Color Yellow -Bold $true
    Write-Color "    |___________|    " -Color Yellow -Bold $true
    Write-Color "    |  🏆 SUCCESS|    " -Color Yellow -Bold $true
    Write-Color "    |___________|    " -Color Yellow -Bold $true
    Write-Color "     \         /     " -Color Yellow -Bold $true
    Write-Color "      `-.   .-'      " -Color Yellow -Bold $true
    Write-Color "         | |         " -Color Yellow -Bold $true
    Write-Color "         | |         " -Color Yellow -Bold $true
    Write-Color "        /   \        " -Color Yellow -Bold $true
    Write-Color "       '-----'       " -Color Yellow -Bold $true
    Write-Host ""
    Write-Color "🌟 LEVEL PASSED: $LevelName 🌟" -Color Green -Bold $true
    Write-Host ""
}

function Get-ActiveBranch {
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if ($LASTEXITCODE -eq 0) { return $branch.Trim() }
    return $null
}

function Get-BaseBranch {
    $branches = git branch --list 2>$null
    if ($branches -match "main") { return "main" }
    if ($branches -match "master") { return "master" }
    return "main"
}

function Fail-Challenge {
    param (
        [string]$ErrorMsg,
        [string[]]$Hints
    )
    Write-Color "❌ CHALLENGE INCOMPLETE ❌" -Color Red -Bold $true
    Write-Host ""
    Write-Color "Error: $ErrorMsg" -Color White
    Write-Host ""
    
    if ($Hints.Length -gt 0) {
        $boxLines = @("💡 TROUBLESHOOTING HINTS:")
        $boxLines += ""
        foreach ($hint in $Hints) {
            $boxLines += $hint
        }
        Draw-Box -Lines $boxLines -Color Yellow
    }
    Write-Host ""
    Write-Color "Keep trying! Fix the errors and run verification again. 🛠️" -Color Cyan
    Write-Host ""
    exit 1
}

# Resolve script directory and root parent
$ROOT_DIR = Split-Path $PSScriptRoot -Parent

# Detect level number from folder name
$folderName = Split-Path $pwd -Leaf
if ($folderName -notmatch "^level-(\d+)-") {
    Write-Color "⚠ Verification must be run inside a specific challenge directory!" -Color Yellow -Bold $true
    Write-Host ""
    Write-Color "Example Usage:"
    Write-Color "  1. cd git-challenges/level-1-basics" -Color Yellow
    Write-Color "  2. powershell -ExecutionPolicy Bypass -File ..\..\src\verify.ps1" -Color Yellow
    Write-Host ""
    exit 1
}

$levelId = [int]$Matches[1]
$baseBranch = Get-BaseBranch
$activeBranch = Get-ActiveBranch

Write-Host ""
Write-Color "=== VERIFYING LEVEL $levelId (POWERSHELL RUNNER) ===" -Color Magenta -Bold $true
Write-Color "Inspecting Git repository state..." -Color Gray
Write-Host ""

switch ($levelId) {
    1 {
        # Level 1: Basics
        if (!(Test-Path -Path ".git")) {
            Fail-Challenge -ErrorMsg "The folder is not a Git repository yet." -Hints @("Run 'git init' inside the folder to initialize it.")
        }
        
        if (!(Test-Path -Path "hello.txt")) {
            Fail-Challenge -ErrorMsg "The file 'hello.txt' could not be found." -Hints @("Create a file named exactly 'hello.txt' in the level-1-basics folder.")
        }
        
        $content = (Get-Content -Path "hello.txt" -Raw).Trim()
        if ($content -ne "Hello, Git!") {
            Fail-Challenge -ErrorMsg "The content of 'hello.txt' is incorrect." -Hints @("Open 'hello.txt' and make sure it has exactly: Hello, Git!")
        }
        
        git log --oneline >$null 2>&1
        if ($LASTEXITCODE -ne 0) {
            Fail-Challenge -ErrorMsg "No commits found in the repository." -Hints @("Stage 'hello.txt' and commit it using 'git commit'.")
        }
        
        $filesInHead = git ls-tree --name-only -r HEAD 2>$null
        if ($filesInHead -notmatch "hello.txt") {
            Fail-Challenge -ErrorMsg "The file 'hello.txt' is not committed." -Hints @("Stage hello.txt with 'git add hello.txt' and run 'git commit'.")
        }
        
        Print-Trophy -LevelName "The First Step"
    }
    
    2 {
        # Level 2: Branching
        if (!(Test-Path -Path ".git")) {
            Fail-Challenge -ErrorMsg "Git repository not found. Did you delete .git?" -Hints @("Reset the level from the npm start menu.")
        }
        
        $branches = git branch --list 2>$null
        if ($branches -notmatch "feature-login") {
            Fail-Challenge -ErrorMsg "The branch 'feature-login' could not be found." -Hints @("Create the branch using 'git branch feature-login' or 'git checkout -b feature-login'.")
        }
        
        if ($activeBranch -ne "feature-login") {
            Fail-Challenge -ErrorMsg "You are currently on branch '$activeBranch'. You should be on 'feature-login'." -Hints @("Switch branch with 'git checkout feature-login'.")
        }
        
        if (!(Test-Path -Path "login.js")) {
            Fail-Challenge -ErrorMsg "The file 'login.js' is missing on branch 'feature-login'." -Hints @("Create 'login.js' with: console.log('Login initialized');")
        }
        
        $filesInHead = git ls-tree --name-only -r HEAD 2>$null
        if ($filesInHead -notmatch "login.js") {
            Fail-Challenge -ErrorMsg "'login.js' is not committed on feature-login." -Hints @("Stage 'login.js' and commit it on the feature-login branch.")
        }
        
        $filesInBase = git ls-tree --name-only -r $baseBranch 2>$null
        if ($filesInBase -match "login.js") {
            Fail-Challenge -ErrorMsg "The file 'login.js' was committed on '$baseBranch' branch." -Hints @("It should only exist in 'feature-login'. Switch to main, remove login.js, and commit again.")
        }
        
        Print-Trophy -LevelName "Divergent Paths"
    }
    
    3 {
        # Level 3: Merging
        if (!(Test-Path -Path ".git")) { Fail-Challenge -ErrorMsg "Git repository not found." }
        
        if ($activeBranch -ne $baseBranch) {
            Fail-Challenge -ErrorMsg "You are on branch '$activeBranch'. You should merge 'feature-about' INTO '$baseBranch'." -Hints @("Switch back to main with 'git checkout $baseBranch' and try again.")
        }
        
        if (Test-Path -Path ".git/MERGE_HEAD") {
            Fail-Challenge -ErrorMsg "You are currently in the middle of a merge conflict. The merge is not completed." -Hints @("Open index.html, resolve conflict, remove markers, run 'git add index.html', and 'git commit'.")
        }
        
        git merge-base --is-ancestor refs/heads/feature-about HEAD 2>$null
        if ($LASTEXITCODE -ne 0) {
            Fail-Challenge -ErrorMsg "Branch 'feature-about' has not been merged." -Hints @("Run 'git merge feature-about' on the $baseBranch branch.")
        }
        
        git rev-parse --verify HEAD^2 >$null 2>&1
        if ($LASTEXITCODE -ne 0) {
            Fail-Challenge -ErrorMsg "The latest commit is not a merge commit." -Hints @("Ensure you merge using standard merge, not fast-forward if it skips merge commit.")
        }
        
        $htmlContent = Get-Content -Path "index.html" -Raw
        if ($htmlContent -match "<<<<<<<" -or $htmlContent -match "=======" -or $htmlContent -match ">>>>>>>") {
            Fail-Challenge -ErrorMsg "The file 'index.html' still contains Git conflict markers." -Hints @("Remove all conflict markers line-by-line, keeping only the final code.")
        }
        
        if ($htmlContent -notmatch "Enjoy your training session today!" -or $htmlContent -notmatch "This is a simulated portal to test Git merge conflicts.") {
            Fail-Challenge -ErrorMsg "The resolved 'index.html' does not contain both branch changes." -Hints @("Make sure you keep both the Welcome message (from main) and the About section (from feature-about).")
        }
        
        Print-Trophy -LevelName "Joining Forces"
    }
    
    4 {
        # Level 4: Rebasing
        if (!(Test-Path -Path ".git")) { Fail-Challenge -ErrorMsg "Git repository not found." }
        
        if ($activeBranch -ne "feature-payment") {
            Fail-Challenge -ErrorMsg "You are currently on branch '$activeBranch'. You should be on 'feature-payment'." -Hints @("Switch to the branch with 'git checkout feature-payment'.")
        }
        
        if (!(Test-Path -Path "config.json")) {
            Fail-Challenge -ErrorMsg "The commit from 'main' (which added 'config.json') is not in your current branch." -Hints @("Rebase 'feature-payment' onto '$baseBranch' with 'git rebase $baseBranch'.")
        }
        
        $merges = git log --merges --oneline 2>$null
        if ($merges) {
            Fail-Challenge -ErrorMsg "We detected merge commits in your history. You used 'git merge' instead of 'git rebase'!" -Hints @("Rebase leaves a clean linear history. Reset the level and rebase.")
        }
        
        Print-Trophy -LevelName "Rewriting History"
    }
    
    5 {
        # Level 5: Stashing
        if (!(Test-Path -Path ".git")) { Fail-Challenge -ErrorMsg "Git repository not found." }
        
        $branches = git branch --list 2>$null
        if ($branches -notmatch "hotfix") {
            Fail-Challenge -ErrorMsg "The 'hotfix' branch was not found." -Hints @("Create the hotfix branch (after stashing changes!) and commit hotfix.txt.")
        }
        
        $hotfixFiles = git ls-tree --name-only -r refs/heads/hotfix 2>$null
        if ($hotfixFiles -notmatch "hotfix.txt") {
            Fail-Challenge -ErrorMsg "'hotfix.txt' was not committed on hotfix."
        }
        
        if ($activeBranch -ne $baseBranch) {
            Fail-Challenge -ErrorMsg "You are on branch '$activeBranch'. Switch back to '$baseBranch'." -Hints @("Run 'git checkout $baseBranch'.")
        }
        
        $serverContent = Get-Content -Path "server.js" -Raw
        if ($serverContent -notmatch "TODO: Implement API endpoints") {
            Fail-Challenge -ErrorMsg "Your uncommitted changes in 'server.js' are missing." -Hints @("Run 'git stash pop' to restore your dirty edits onto main.")
        }
        
        Print-Trophy -LevelName "Stashing Work"
    }
    
    6 {
        # Level 6: Reverting
        if (!(Test-Path -Path ".git")) { Fail-Challenge -ErrorMsg "Git repository not found." }
        
        $log = git log --oneline 2>$null
        if ($log -notmatch "BUGGY") {
            Fail-Challenge -ErrorMsg "The buggy commit is missing from history. Did you use 'git reset'?" -Hints @("You must preserve the history of other commits. Reset level and use 'git revert <hash>'.")
        }
        
        if ($log -notmatch "README") {
            Fail-Challenge -ErrorMsg "The README commit is missing. Did you wipe recent history?" -Hints @("Revert the buggy commit only. Do not delete other commits.")
        }
        
        $latest = git log -1 --pretty=%B 2>$null
        if ($latest -notmatch "revert") {
            Fail-Challenge -ErrorMsg "We couldn't find a revert commit on top of your history." -Hints @("Run 'git revert <buggy-commit-hash>'.")
        }
        
        $calcContent = Get-Content -Path "calculator.js" -Raw
        if ($calcContent -match "Critical performance error!") {
            Fail-Challenge -ErrorMsg "'calculator.js' still contains the buggy lines of code." -Hints @("Make sure the revert completed successfully.")
        }
        
        Print-Trophy -LevelName "Reverting Blunders"
    }
    
    7 {
        # Level 7: Cherry-Picking
        if (!(Test-Path -Path ".git")) { Fail-Challenge -ErrorMsg "Git repository not found." }
        
        if ($activeBranch -ne $baseBranch) {
            Fail-Challenge -ErrorMsg "You should be on branch '$baseBranch' to cherry-pick." -Hints @("Switch with 'git checkout $baseBranch'.")
        }
        
        if (!(Test-Path -Path "auth.js")) {
            Fail-Challenge -ErrorMsg "The security fix file 'auth.js' is missing from $baseBranch." -Hints @("Cherry pick the fix commit from the 'development' branch using 'git cherry-pick <hash>'.")
        }
        
        if ((Test-Path -Path "logger.js") -or (Test-Path -Path "dashboard.js")) {
            Fail-Challenge -ErrorMsg "We found other development commits (logger/dashboard) on $baseBranch." -Hints @("You merged the entire branch instead of cherry-picking just the single fix. Reset and try again.")
        }
        
        $log = git log --oneline 2>$null
        if ($log -notmatch "Fix security exploit in auth") {
            Fail-Challenge -ErrorMsg "We couldn't verify the cherry-picked commit in history."
        }
        
        Print-Trophy -LevelName "Cherry-Picking"
    }
}

# Centralized State Persistence Handler
$stateFile = Join-Path $ROOT_DIR "..\.gitquest-state.json"
$completed = @()

if (Test-Path -Path $stateFile) {
    try {
        $json = Get-Content -Path $stateFile -Raw | ConvertFrom-Json
        if ($json.completed) {
            $completed = $json.completed
        }
    } catch {}
}

if ($completed -notcontains $levelId) {
    $completed += $levelId
}

# Re-sort
$completed = $completed | Sort-Object

$listStr = $completed -join ", "
$jsonContent = @"
{
  "completed": [
    $listStr
  ]
}
"@
Set-Content -Path $stateFile -Value $jsonContent -Encoding utf8
