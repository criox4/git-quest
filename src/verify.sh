#!/usr/bin/env bash

# ANSI Escape colors for styling
RESET='\033[0m'
BOLD='\033[1m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
GRAY='\033[90m'

# Box printer
draw_box() {
  local lines=("$@")
  local max_len=0
  for line in "${lines[@]}"; do
    # Remove ANSI escape codes to calculate raw length
    local raw_line
    raw_line=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
    if [ ${#raw_line} -gt $max_len ]; then
      max_len=${#raw_line}
    fi
  done

  local border_color=$CYAN
  local top_border="╭$(printf '─%.0s' $(seq 1 $((max_len + 2))))╮"
  local bottom_border="╰$(printf '─%.0s' $(seq 1 $((max_len + 2))))╯"

  echo -e "${border_color}${top_border}${RESET}"
  for line in "${lines[@]}"; do
    local raw_line
    raw_line=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
    local space_right=$((max_len - ${#raw_line}))
    local padding=$(printf ' %.0s' $(seq 1 $space_right))
    echo -e "${border_color}│${RESET} $line${padding} ${border_color}│${RESET}"
  done
  echo -e "${border_color}${bottom_border}${RESET}"
}

print_trophy() {
  echo -e "\n"
  echo -e "${YELLOW}${BOLD}      .---.      ${RESET}"
  echo -e "${YELLOW}${BOLD}     /     \\\\     ${RESET}"
  echo -e "${YELLOW}${BOLD}    |___________|    ${RESET}"
  echo -e "${YELLOW}${BOLD}    |  🏆 SUCCESS|    ${RESET}"
  echo -e "${YELLOW}${BOLD}    |___________|    ${RESET}"
  echo -e "${YELLOW}${BOLD}     \\\\         /     ${RESET}"
  echo -e "${YELLOW}${BOLD}      \`-.   .-'      ${RESET}"
  echo -e "${YELLOW}${BOLD}         | |         ${RESET}"
  echo -e "${YELLOW}${BOLD}         | |         ${RESET}"
  echo -e "${YELLOW}${BOLD}        /   \\\\        ${RESET}"
  echo -e "${YELLOW}${BOLD}       '-----'       ${RESET}"
  echo -e "\n${GREEN}${BOLD}🌟 LEVEL PASSED: $1 🌟${RESET}\n"
}

get_active_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null
}

get_base_branch() {
  if git branch --list | grep -q "main"; then
    echo "main"
  elif git branch --list | grep -q "master"; then
    echo "master"
  else
    echo "main"
  fi
}

# Detect Level ID from directory name
FOLDER_NAME=$(basename "$PWD")
if [[ ! $FOLDER_NAME =~ ^level-([0-9]+)- ]]; then
  echo -e "${YELLOW}${BOLD}⚠ Verification must be run inside a specific challenge directory!${RESET}"
  echo -e "\nExample Usage:"
  echo -e "  1. ${YELLOW}cd git-challenges/level-1-basics${RESET}"
  echo -e "  2. ${YELLOW}bash ../../src/verify.sh${RESET}\n"
  exit 1
fi

LEVEL_ID="${BASH_REMATCH[1]}"
BASE_BRANCH=$(get_base_branch)
ACTIVE_BRANCH=$(get_active_branch)

echo -e "\n${MAGENTA}${BOLD}=== VERIFYING LEVEL ${LEVEL_ID} (BASH RUNNER) ===${RESET}"
echo -e "${GRAY}Inspecting Git repository state...${RESET}\n"

fail() {
  local error_msg="$1"
  shift
  local hints=("$@")
  
  echo -e "${RED}${BOLD}❌ CHALLENGE INCOMPLETE ❌${RESET}"
  echo -e "\nError: ${error_msg}\n"
  
  if [ ${#hints[@]} -gt 0 ]; then
    local hint_lines=("${YELLOW}${BOLD}💡 TROUBLESHOOTING HINTS:${RESET}" "")
    for hint in "${hints[@]}"; do
      hint_lines+=("$hint")
    done
    draw_box "${hint_lines[@]}"
  fi
  echo -e "\n${CYAN}Keep trying! Fix the errors and run verification again. 🛠️${RESET}\n"
  exit 1
}

# Run verification based on level
case "$LEVEL_ID" in
  1)
    # Level 1: Basics
    [ -d .git ] || fail "The folder is not a Git repository yet." \
      "Run 'git init' inside the folder to initialize it."
      
    [ -f hello.txt ] || fail "The file 'hello.txt' could not be found." \
      "Create a file named exactly 'hello.txt' in the level-1-basics folder."
      
    CONTENT=$(cat hello.txt 2>/dev/null | xargs)
    [ "$CONTENT" = "Hello, Git!" ] || fail "The content of 'hello.txt' is incorrect." \
      "Open 'hello.txt' and make sure it has exactly: Hello, Git!"
      
    git log --oneline &>/dev/null || fail "No commits found in the repository." \
      "Stage 'hello.txt' and commit it using 'git commit'."
      
    git ls-tree --name-only -r HEAD | grep -q "hello.txt" || fail "The file 'hello.txt' is not committed." \
      "Stage hello.txt with 'git add hello.txt' and run 'git commit'."
      
    print_trophy "The First Step"
    ;;
    
  2)
    # Level 2: Branching
    [ -d .git ] || fail "Git repository not found. Did you delete .git?" \
      "Reset the level from the npm start menu."
      
    git show-ref refs/heads/feature-login &>/dev/null || fail "The branch 'feature-login' could not be found." \
      "Create the branch using 'git branch feature-login' or 'git checkout -b feature-login'."
      
    [ "$ACTIVE_BRANCH" = "feature-login" ] || fail "You are currently on branch '${ACTIVE_BRANCH}'. You should be on 'feature-login'." \
      "Switch branch with 'git checkout feature-login'."
      
    [ -f login.js ] || fail "The file 'login.js' is missing on branch 'feature-login'." \
      "Create 'login.js' with: console.log('Login initialized');"
      
    git ls-tree --name-only -r HEAD | grep -q "login.js" || fail "'login.js' is not committed on feature-login." \
      "Stage 'login.js' and commit it on the feature-login branch."
      
    git ls-tree --name-only -r "$BASE_BRANCH" | grep -q "login.js" && fail "The file 'login.js' was committed on '${BASE_BRANCH}' branch." \
      "It should only exist in 'feature-login'. Switch to main, remove login.js, and commit again."
      
    print_trophy "Divergent Paths"
    ;;
    
  3)
    # Level 3: Merging & Conflicts
    [ -d .git ] || fail "Git repository not found."
    
    [ "$ACTIVE_BRANCH" = "$BASE_BRANCH" ] || fail "You are on branch '${ACTIVE_BRANCH}'. You should merge 'feature-about' INTO '${BASE_BRANCH}'." \
      "Switch back to main with 'git checkout ${BASE_BRANCH}' and try again."
      
    [ -f .git/MERGE_HEAD ] && fail "You are currently in the middle of a merge conflict. The merge is not completed." \
      "Open index.html, resolve conflict, remove markers, run 'git add index.html', and 'git commit'."
      
    git merge-base --is-ancestor refs/heads/feature-about HEAD 2>/dev/null || fail "Branch 'feature-about' has not been merged." \
      "Run 'git merge feature-about' on the ${BASE_BRANCH} branch."
      
    git rev-parse --verify HEAD^2 &>/dev/null || fail "The latest commit is not a merge commit." \
      "Ensure you merge using standard merge, not fast-forward if it skips merge commit."
      
    grep -qE "<<<<<<<|=======|>>>>>>>" index.html && fail "The file 'index.html' still contains Git conflict markers." \
      "Remove all conflict markers line-by-line, keeping only the final code."
      
    grep -q "Enjoy your training session today!" index.html && grep -q "This is a simulated portal to test Git merge conflicts." index.html || \
      fail "The resolved 'index.html' does not contain both branch changes." \
      "Make sure you keep both the Welcome message (from main) and the About section (from feature-about)."
      
    print_trophy "Joining Forces"
    ;;
    
  4)
    # Level 4: Rebasing
    [ -d .git ] || fail "Git repository not found."
    
    [ "$ACTIVE_BRANCH" = "feature-payment" ] || fail "You are currently on branch '${ACTIVE_BRANCH}'. You should be on 'feature-payment'." \
      "Switch to the branch with 'git checkout feature-payment'."
      
    [ -f config.json ] || fail "The commit from 'main' (which added 'config.json') is not in your current branch." \
      "Rebase 'feature-payment' onto '${BASE_BRANCH}' with 'git rebase ${BASE_BRANCH}'."
      
    MERGES=$(git log --merges --oneline)
    [ -n "$MERGES" ] && fail "We detected merge commits in your history. You used 'git merge' instead of 'git rebase'!" \
      "Rebase leaves a clean linear history. Reset the level and rebase."
      
    print_trophy "Rewriting History"
    ;;
    
  5)
    # Level 5: Stashing
    [ -d .git ] || fail "Git repository not found."
    
    git show-ref refs/heads/hotfix &>/dev/null || fail "The 'hotfix' branch was not found." \
      "Create the hotfix branch (after stashing changes!) and commit hotfix.txt."
      
    git ls-tree --name-only -r refs/heads/hotfix | grep -q "hotfix.txt" || fail "'hotfix.txt' was not committed on hotfix."
    
    [ "$ACTIVE_BRANCH" = "$BASE_BRANCH" ] || fail "You are on branch '${ACTIVE_BRANCH}'. Switch back to '${BASE_BRANCH}'." \
      "Run 'git checkout ${BASE_BRANCH}'."
      
    grep -q "TODO: Implement API endpoints" server.js || fail "Your uncommitted changes in 'server.js' are missing." \
      "Run 'git stash pop' to restore your dirty edits onto main."
      
    print_trophy "Stashing Work"
    ;;
    
  6)
    # Level 6: Reverting
    [ -d .git ] || fail "Git repository not found."
    
    git log --oneline | grep -q "BUGGY" || fail "The buggy commit is missing from history. Did you use 'git reset'?" \
      "You must preserve the history of other commits. Reset level and use 'git revert <hash>'."
      
    git log --oneline | grep -q "README" || fail "The README commit is missing. Did you wipe recent history?" \
      "Revert the buggy commit only. Do not delete other commits."
      
    git log -1 --pretty=%B | grep -iq "revert" || fail "We couldn't find a revert commit on top of your history." \
      "Run 'git revert <buggy-commit-hash>'."
      
    grep -q "Critical performance error!" calculator.js && fail "'calculator.js' still contains the buggy lines of code." \
      "Make sure the revert completed successfully."
      
    print_trophy "Reverting Blunders"
    ;;
    
  7)
    # Level 7: Cherry-Picking
    [ -d .git ] || fail "Git repository not found."
    
    [ "$ACTIVE_BRANCH" = "$BASE_BRANCH" ] || fail "You should be on branch '${BASE_BRANCH}' to cherry-pick." \
      "Switch with 'git checkout ${BASE_BRANCH}'."
      
    [ -f auth.js ] || fail "The security fix file 'auth.js' is missing from ${BASE_BRANCH}." \
      "Cherry pick the fix commit from the 'development' branch using 'git cherry-pick <hash>'."
      
    [ -f logger.js ] || [ -f dashboard.js ] && fail "We found other development commits (logger/dashboard) on ${BASE_BRANCH}." \
      "You merged the entire branch instead of cherry-picking just the single fix. Reset and try again."
      
    git log --oneline | grep -q "Fix security exploit in auth" || fail "We couldn't verify the cherry-picked commit in history."
    
    print_trophy "Cherry-Picking"
    ;;
esac
