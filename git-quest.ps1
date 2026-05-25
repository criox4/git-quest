# PowerShell Game Launcher for Git Quest

# Styling color helpers
function Write-Color {
    param (
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::White,
        [bool]$Bold = $false,
        [bool]$NoNewLine = $false
    )
    if ($NoNewLine) {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Message -ForegroundColor $Color
    }
}

$ROOT_DIR = $PSScriptRoot
$STATE_FILE = Join-Path $ROOT_DIR ".gitquest-state.json"
$CHALLENGE_ROOT = Join-Path $ROOT_DIR "git-challenges"

$global:CompletedLevels = @()

# Load state
function Load-Completed {
    $global:CompletedLevels = @()
    if (Test-Path -Path $STATE_FILE) {
        try {
            $json = Get-Content -Path $STATE_FILE -Raw | ConvertFrom-Json
            if ($json.completed) {
                $global:CompletedLevels = $json.completed
            }
        } catch {
            # Catch parsing issues silently
        }
    }
}

# Save state
function Save-Completed {
    $listStr = $global:CompletedLevels -join ", "
    $jsonContent = @"
{
  "completed": [
    $listStr
  ]
}
"@
    Set-Content -Path $STATE_FILE -Value $jsonContent -Encoding utf8
}

function Is-Completed {
    param ([int]$id)
    return $global:CompletedLevels -contains $id
}

function Is-Unlocked {
    param ([int]$id)
    if ($id -eq 1) { return $true }
    $prev = $id - 1
    return Is-Completed -id $prev
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
    
    Write-Color -Message $topBorder -Color $Color
    foreach ($line in $Lines) {
        $spaceRight = $maxLen - $line.Length
        $padding = " " * $spaceRight
        Write-Color -Message "│ " -Color $Color -NoNewLine
        Write-Color -Message $line -Color White -NoNewLine
        Write-Color -Message "$padding │" -Color $Color
    }
    Write-Color -Message $bottomBorder -Color $Color
}

function Print-Banner {
    Clear-Host
    Write-Color "  ________.__  __     ________                       __   " -Color Cyan -Bold $true
    Write-Color " /  _____/|__|/  |_   \_____  \  __ __   ____   _____/  |_ " -Color Cyan -Bold $true
    Write-Color "/   \  ___|  \   __\   /  / \  \|  |  \_/ __ \ /  ___|   __\" -Color Cyan -Bold $true
    Write-Color "\    \_\  \  ||  |    /   \_/.  \  |  /\  ___/ \___ \ |  |  " -Color Cyan -Bold $true
    Write-Color " \______  /__||__|    \_____\ \_/____/  \___  >____  >|__|  " -Color Cyan -Bold $true
    Write-Color "        \/                   \__>           \/     \/       " -Color Cyan -Bold $true
    Write-Color "       --- Master Git Interactive Learning (POWERSHELL GAME) ---" -Color Gray
    Write-Host ""
}

function Init-LevelGit {
    param ([string]$dir)
    if (Test-Path -Path $dir) {
        Remove-Item -Path $dir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    
    $currentLocation = Get-Location
    Set-Location -Path $dir
    
    git init -q
    git config user.name "Git Student"
    git config user.email "student@gitquest.edu"
    git config commit.gpgSign false
    git config core.defaultBranch main
    
    Set-Location -Path $currentLocation
}

function Setup-Level {
    param (
        [int]$id,
        [string]$dirName
    )
    $dir = Join-Path $CHALLENGE_ROOT $dirName
    
    switch ($id) {
        1 {
            if (Test-Path -Path $dir) { Remove-Item -Path $dir -Recurse -Force }
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            $readmeText = "Welcome to Level 1!`n`nRead the objectives in your terminal and complete the tasks in this folder."
            Set-Content -Path (Join-Path $dir "README.txt") -Value $readmeText
        }
        2 {
            Init-LevelGit -dir $dir
            $html = "<!DOCTYPE html>`n<html>`n<head><title>My Awesome Site</title></head>`n<body><h1>Under Construction</h1></body>`n</html>"
            Set-Content -Path (Join-Path $dir "index.html") -Value $html
            
            $curr = Get-Location
            Set-Location -Path $dir
            git add index.html
            git commit -m "Initial commit on main" -q
            Set-Location -Path $curr
        }
        3 {
            Init-LevelGit -dir $dir
            $html1 = "<!DOCTYPE html>`n<html>`n<head><title>Git Quest Portal</title></head>`n<body>`n  <h1>Welcome to Git Quest</h1>`n  <!-- WELCOME_MESSAGE -->`n  <!-- ABOUT_SECTION -->`n</body>`n</html>"
            Set-Content -Path (Join-Path $dir "index.html") -Value $html1
            
            $curr = Get-Location
            Set-Location -Path $dir
            git add index.html
            git commit -m "Initial commit on main" -q
            
            git checkout -b feature-about -q
            $html2 = "<!DOCTYPE html>`n<html>`n<head><title>Git Quest Portal</title></head>`n<body>`n  <h1>Welcome to Git Quest</h1>`n  <!-- WELCOME_MESSAGE -->`n  <h2>About Git Quest</h2>`n  <p>This is a simulated portal to test Git merge conflicts.</p>`n</body>`n</html>"
            Set-Content -Path (Join-Path $dir "index.html") -Value $html2
            git add index.html
            git commit -m "Add about section to index" -q
            
            git checkout main -q 2>$null
            if ($LASTEXITCODE -ne 0) { git checkout master -q }
            
            $html3 = "<!DOCTYPE html>`n<html>`n<head><title>Git Quest Portal</title></head>`n<body>`n  <h1>Welcome to Git Quest</h1>`n  <p>Enjoy your training session today!</p>`n  <!-- ABOUT_SECTION -->`n</body>`n</html>"
            Set-Content -Path (Join-Path $dir "index.html") -Value $html3
            git add index.html
            git commit -m "Update welcome message on main" -q
            
            Set-Location -Path $curr
        }
        4 {
            Init-LevelGit -dir $dir
            Set-Content -Path (Join-Path $dir "app.js") -Value "console.log(`"Starting server...`");`n"
            
            $curr = Get-Location
            Set-Location -Path $dir
            git add app.js
            git commit -m "Initial skeleton" -q
            
            git checkout -b feature-payment -q
            Set-Content -Path (Join-Path $dir "app.js") -Value "console.log(`"Starting server...`");`nconsole.log(`"Payment module activated!`");`n"
            git add app.js
            git commit -m "Add payment feature" -q
            
            git checkout main -q 2>$null
            if ($LASTEXITCODE -ne 0) { git checkout master -q }
            
            $config = "{`n  `"port`": 3000,`n  `"env`": `"production`"`n}`n"
            Set-Content -Path (Join-Path $dir "config.json") -Value $config
            git add config.json
            git commit -m "Add system configuration" -q
            
            git checkout feature-payment -q
            Set-Location -Path $curr
        }
        5 {
            Init-LevelGit -dir $dir
            Set-Content -Path (Join-Path $dir "server.js") -Value "console.log(`"Server listening...`");`n"
            
            $curr = Get-Location
            Set-Location -Path $dir
            git add server.js
            git commit -m "Initialize server file" -q
            
            $dirty = "// TODO: Implement API endpoints`nconsole.log(`"API active`");`n"
            Add-Content -Path (Join-Path $dir "server.js") -Value $dirty
            Set-Location -Path $curr
        }
        6 {
            Init-LevelGit -dir $dir
            Set-Content -Path (Join-Path $dir "calculator.js") -Value "function add(a, b) {`n  return a + b;`n}`n`nmodule.exports = { add };`n"
            
            $curr = Get-Location
            Set-Location -Path $dir
            git add calculator.js
            git commit -m "Initial calculator release" -q
            
            Set-Content -Path (Join-Path $dir "calculator.js") -Value "function add(a, b) {`n  throw new Error(`"Critical performance error!`"); // BUGGY`n}`n`nmodule.exports = { add };`n"
            git add calculator.js
            git commit -m "Optimize calculator operations (BUGGY)" -q
            
            Set-Content -Path (Join-Path $dir "README.md") -Value "# Calculator Project`nA high-performance calculator.`n"
            git add README.md
            git commit -m "Update README documentation" -q
            Set-Location -Path $curr
        }
        7 {
            Init-LevelGit -dir $dir
            Set-Content -Path (Join-Path $dir "index.js") -Value "console.log(`"App booting...`");`n"
            
            $curr = Get-Location
            Set-Location -Path $dir
            git add index.js
            git commit -m "Initial commit" -q
            
            git checkout -b development -q
            Set-Content -Path (Join-Path $dir "logger.js") -Value "console.log(`"[DEBUG] Dev logger loaded`");`n"
            git add logger.js
            git commit -m "Add developer debug log" -q
            
            Set-Content -Path (Join-Path $dir "auth.js") -Value "function authenticate(user, pass) {`n  if (!user || !pass) return false;`n  // SECURE CRYPTO FIX IMPLEMENTED HERE`n  return true;`n}`n`nmodule.exports = { authenticate };`n"
            git add auth.js
            git commit -m "Fix security exploit in auth" -q
            
            Set-Content -Path (Join-Path $dir "dashboard.js") -Value "console.log(`"WIP Dashboard UI elements...`");`n"
            git add dashboard.js
            git commit -m "WIP unfinished dashboard" -q
            
            git checkout main -q 2>$null
            if ($LASTEXITCODE -ne 0) { git checkout master -q }
            Set-Location -Path $curr
        }
    }
}

function Display-Objectives {
    param (
        [int]$id,
        [string]$name,
        [string]$tagline,
        [string]$dirName
    )
    
    $lines = @(
        "🎯 LEVEL $id : $($name.ToUpper())",
        "$tagline",
        "",
        "OBJECTIVES:"
    )
    
    switch ($id) {
        1 {
            $lines += "1. Initialize a new Git repository in this folder."
            $lines += "2. Create a file named hello.txt containing the exact text 'Hello, Git!'."
            $lines += "3. Stage the hello.txt file."
            $lines += "4. Commit the file with the message 'Initial commit'."
        }
        2 {
            $lines += "1. Create a new branch named 'feature-login'."
            $lines += "2. Switch to the 'feature-login' branch."
            $lines += "3. Create a file named 'login.js' containing: console.log('Login initialized');"
            $lines += "4. Stage and commit 'login.js' with the message 'Implement authentication logic'."
            $lines += "5. Do NOT merge it back to the main branch yet!"
        }
        3 {
            $lines += "1. Merge the branch 'feature-about' into your current branch (main/master)."
            $lines += "2. You will encounter a merge conflict in 'index.html' — do not panic!"
            $lines += "3. Manually open 'index.html', resolve the conflict so that BOTH changes (the welcome message and the about section) are preserved."
            $lines += "4. Remove all Git conflict markers (<<<<<<<, =======, >>>>>>>)."
            $lines += "5. Stage the resolved 'index.html' file."
            $lines += "6. Commit the merge to complete the task."
        }
        4 {
            $lines += "1. Ensure you are on the branch 'feature-payment'."
            $lines += "2. Rebase 'feature-payment' onto the 'main' (or 'master') branch."
            $lines += "3. Verify that the history is linear (no merge commits) and that your payment feature commits sit on top of the main commits."
        }
        5 {
            $lines += "1. Notice that 'server.js' has dirty, uncommitted changes."
            $lines += "2. Stash your changes safely using Git stash."
            $lines += "3. Create and switch to a new branch named 'hotfix'."
            $lines += "4. Create a file named 'hotfix.txt' with content: URGENT FIX"
            $lines += "5. Stage and commit 'hotfix.txt' as 'Apply emergency hotfix'."
            $lines += "6. Switch back to the main (or master) branch."
            $lines += "7. Restore (pop) your stashed changes to resume your work on 'server.js'!"
        }
        6 {
            $lines += "1. Examine your commit history with 'git log'."
            $lines += "2. Find the buggy commit: 'Optimize calculator operations (BUGGY)'."
            $lines += "3. Revert ONLY that buggy commit using 'git revert'."
            $lines += "4. Do NOT use 'git reset' because we want to preserve the history of other commits (like the README update)!"
        }
        7 {
            $lines += "1. Switch to the branch 'development' and run 'git log' to find the commits."
            $lines += "2. Locate the commit message: 'Fix security exploit in auth'. Copy its commit hash."
            $lines += "3. Switch back to your 'main' (or 'master') branch."
            $lines += "4. Cherry-pick ONLY that specific commit onto 'main'."
            $lines += "5. Do NOT merge the rest of the development commits ('Add developer debug log', 'WIP unfinished dashboard') into main."
        }
    }
    
    $lines += ""
    $lines += "DIRECTIONS:"
    $lines += "1. Open a new terminal tab/window."
    $lines += "2. CD into the challenge folder:"
    $lines += "   cd git-challenges/$dirName"
    $lines += "3. Follow the objectives listed above and execute your Git commands."
    $lines += "4. To verify if your solution is correct, run:"
    $lines += "   powershell -ExecutionPolicy Bypass -File ..\..\verify.ps1"
    
    Draw-Box -Lines $lines -Color Cyan
}

$levelDetails = @{
    1 = @{ name = "The First Step"; dir = "level-1-basics"; tagline = "Initialization and Committing" }
    2 = @{ name = "Divergent Paths"; dir = "level-2-branching"; tagline = "Branching Out" }
    3 = @{ name = "Joining Forces"; dir = "level-3-merging"; tagline = "Merging & Conflict Resolution" }
    4 = @{ name = "Rewriting History"; dir = "level-4-rebasing"; tagline = "Linearizing with Rebasing" }
    5 = @{ name = "Stashing Work"; dir = "level-5-stashing"; tagline = "The Secret Pocket" }
    6 = @{ name = "Reverting Blunders"; dir = "level-6-reverting"; tagline = "Safe History Rollbacks" }
    7 = @{ name = "Cherry-Picking"; dir = "level-7-cherrypick"; tagline = "Hand-Selecting Commits" }
}

function Run-Menu {
    while ($true) {
        Load-Completed
        Print-Banner
        
        $welcomeLines = @(
            "Welcome, recruit!",
            "Complete the levels below in order.",
            "Solve the Git puzzles directly inside the challenge directories.",
            "Verify via: powershell -ExecutionPolicy Bypass -File ..\..\verify.ps1 inside the level folder!"
        )
        Draw-Box -Lines $welcomeLines -Color Magenta
        
        Write-Host ""
        Write-Color "  === ACTIVE CHALLENGES ===" -Color Magenta -Bold $true
        
        for ($id = 1; $id -le 7; $id++) {
            $ld = $levelDetails[$id]
            $name = $ld.name
            $tagline = $ld.tagline
            
            if (Is-Completed -id $id) {
                Write-Color -Message "  [✓] Completed  " -Color Green -NoNewLine -Bold $true
                Write-Color -Message "Level $id:  $($name.PadRight(25))" -Color White -NoNewLine -Bold $true
                Write-Color -Message " - $tagline" -Color Gray
            }
            elseif (Is-Unlocked -id $id) {
                Write-Color -Message "  [•] Unlocked   " -Color Cyan -NoNewLine -Bold $true
                Write-Color -Message "Level $id:  $($name.PadRight(25))" -Color Cyan -NoNewLine -Bold $true
                Write-Color -Message " - $tagline" -Color Gray
            }
            else {
                Write-Color -Message "  [🔒] Locked     " -Color Gray -NoNewLine
                Write-Color -Message "Level $id:  $($name.PadRight(25))" -Color Gray -NoNewLine
                Write-Color -Message " - $tagline" -Color Gray
            }
        }
        
        Write-Host ""
        Write-Color "  Options: [1-7] Select Level  |  [c] Reset Progress  |  [q] Quit Game" -Color White -Bold $true
        
        $opt = Read-Host " 👉 Choose an option"
        $opt = $opt.Trim().ToLower()
        
        if ($opt -eq "q") {
            Write-Host ""
            Write-Color "Thanks for playing Git Quest! Happy committing! 🚀" -Color Cyan -Bold $true
            Write-Host ""
            break
        }
        
        if ($opt -eq "c") {
            $confirm = Read-Host "Are you sure you want to reset all progress? (y/N)"
            if ($confirm.Trim().ToLower() -eq "y") {
                if (Test-Path -Path $STATE_FILE) { Remove-Item -Path $STATE_FILE -Force }
                if (Test-Path -Path $CHALLENGE_ROOT) { Remove-Item -Path $CHALLENGE_ROOT -Recurse -Force }
                Write-Color "Progress reset successfully!" -Color Green
                Start-Sleep -Seconds 1
            }
            continue
        }
        
        if ($opt -match "^[1-7]$") {
            $levelId = [int]$opt
            
            if (!(Is-Unlocked -id $levelId)) {
                Write-Host ""
                Write-Color "🔒 Level $levelId is locked! Complete the previous levels first." -Color Red -Bold $true
                Start-Sleep -Seconds 2
                continue
            }
            
            $ld = $levelDetails[$levelId]
            $name = $ld.name
            $dirName = $ld.dir
            $tagline = $ld.tagline
            
            Write-Host ""
            Write-Color "Initializing Level $levelId: $name..." -Color Cyan
            
            Setup-Level -id $levelId -dirName $dirName
            
            Print-Banner
            Display-Objectives -id $levelId -name $name -tagline $tagline -dirName $dirName
            
            Read-Host "Press [Enter] to return to the Main Menu..." | Out-Null
        }
        else {
            Write-Color "Invalid selection. Try again." -Color Red
            Start-Sleep -Seconds 1
        }
    }
}

Run-Menu
