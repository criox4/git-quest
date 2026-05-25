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

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="${ROOT_DIR}/../.gitquest-state.json"
CHALLENGE_ROOT="${ROOT_DIR}/../git-challenges"

# Load completed levels
load_completed() {
  COMPLETED=()
  if [ -f "$STATE_FILE" ]; then
    # Simple JSON parser to extract numbers from "completed": [ 1, 2 ]
    local content
    content=$(cat "$STATE_FILE" 2>/dev/null)
    # Extract digit arrays
    local matches
    matches=$(echo "$content" | grep -oE '[0-7]')
    for m in $matches; do
      COMPLETED+=("$m")
    done
  fi
}

# Save completed levels
save_completed() {
  local list=""
  for c in "${COMPLETED[@]}"; do
    if [ -n "$list" ]; then
      list="${list}, ${c}"
    else
      list="${c}"
    fi
  done
  echo -e "{\n  \"completed\": [\n    ${list}\n  ]\n}" > "$STATE_FILE"
}

is_completed() {
  local id="$1"
  for c in "${COMPLETED[@]}"; do
    if [ "$c" -eq "$id" ]; then
      return 0
    fi
  done
  return 1
}

is_unlocked() {
  local id="$1"
  if [ "$id" -eq 1 ]; then
    return 0
  fi
  local prev=$((id - 1))
  if is_completed "$prev"; then
    return 0
  fi
  return 1
}

draw_box() {
  local lines=("$@")
  local max_len=0
  for line in "${lines[@]}"; do
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

print_banner() {
  clear
  echo -e "${CYAN}${BOLD}  ________.__  __     ________                       __   ${RESET}"
  echo -e "${CYAN}${BOLD} /  _____/|__|/  |_   \\_____  \\  __ __   ____   _____/  |_ ${RESET}"
  echo -e "${CYAN}${BOLD}/   \\  ___|  \\   __\\   /  / \\  \\|  |  \\_/ __ \\ /  ___|   __\\${RESET}"
  echo -e "${CYAN}${BOLD}\\    \\_\\  \\  ||  |    /   \\_/.  \\  |  /\\  ___/ \\___ \\ |  |  ${RESET}"
  echo -e "${CYAN}${BOLD} \\______  /__||__|    \\_____\\ \\_/____/  \\___  >____  >|__|  ${RESET}"
  echo -e "${CYAN}${BOLD}        \\/                   \\__>           \\/     \\/       ${RESET}"
  echo -e "       ${GRAY}${BOLD}--- Master Git Interactive Learning (BASH GAME) ---${RESET}\n"
}

init_level_git() {
  local dir="$1"
  rm -rf "$dir"
  mkdir -p "$dir"
  cd "$dir" || exit 1
  git init -q
  git config user.name "Git Student"
  git config user.email "student@gitquest.edu"
  git config commit.gpgSign false
  git config core.defaultBranch main
}

setup_level() {
  local id="$1"
  local dir="${CHALLENGE_ROOT}/$2"
  
  case "$id" in
    1)
      rm -rf "$dir"
      mkdir -p "$dir"
      echo -e "Welcome to Level 1!\n\nRead the objectives in your terminal and complete the tasks in this folder." > "${dir}/README.txt"
      ;;
    2)
      init_level_git "$dir"
      echo -e "<!DOCTYPE html>\n<html>\n<head><title>My Awesome Site</title></head>\n<body><h1>Under Construction</h1></body>\n</html>" > index.html
      git add index.html
      git commit -m "Initial commit on main" -q
      cd "${ROOT_DIR}/.." || exit 1
      ;;
    3)
      init_level_git "$dir"
      echo -e "<!DOCTYPE html>\n<html>\n<head><title>Git Quest Portal</title></head>\n<body>\n  <h1>Welcome to Git Quest</h1>\n  <!-- WELCOME_MESSAGE -->\n  <!-- ABOUT_SECTION -->\n</body>\n</html>" > index.html
      git add index.html
      git commit -m "Initial commit on main" -q
      
      git checkout -b feature-about -q
      echo -e "<!DOCTYPE html>\n<html>\n<head><title>Git Quest Portal</title></head>\n<body>\n  <h1>Welcome to Git Quest</h1>\n  <!-- WELCOME_MESSAGE -->\n  <h2>About Git Quest</h2>\n  <p>This is a simulated portal to test Git merge conflicts.</p>\n</body>\n</html>" > index.html
      git add index.html
      git commit -m "Add about section to index" -q
      
      git checkout main -q 2>/dev/null || git checkout master -q
      echo -e "<!DOCTYPE html>\n<html>\n<head><title>Git Quest Portal</title></head>\n<body>\n  <h1>Welcome to Git Quest</h1>\n  <p>Enjoy your training session today!</p>\n  <!-- ABOUT_SECTION -->\n</body>\n</html>" > index.html
      git add index.html
      git commit -m "Update welcome message on main" -q
      cd "${ROOT_DIR}/.." || exit 1
      ;;
    4)
      init_level_git "$dir"
      echo -e 'console.log("Starting server...");\n' > app.js
      git add app.js
      git commit -m "Initial skeleton" -q
      
      git checkout -b feature-payment -q
      echo -e 'console.log("Starting server...");\nconsole.log("Payment module activated!");\n' > app.js
      git add app.js
      git commit -m "Add payment feature" -q
      
      git checkout main -q 2>/dev/null || git checkout master -q
      echo -e '{\n  "port": 3000,\n  "env": "production"\n}\n' > config.json
      git add config.json
      git commit -m "Add system configuration" -q
      
      git checkout feature-payment -q
      cd "${ROOT_DIR}/.." || exit 1
      ;;
    5)
      init_level_git "$dir"
      echo -e 'console.log("Server listening...");\n' > server.js
      git add server.js
      git commit -m "Initialize server file" -q
      echo -e '// TODO: Implement API endpoints\nconsole.log("API active");\n' >> server.js
      cd "${ROOT_DIR}/.." || exit 1
      ;;
    6)
      init_level_git "$dir"
      echo -e 'function add(a, b) {\n  return a + b;\n}\n\nmodule.exports = { add };\n' > calculator.js
      git add calculator.js
      git commit -m "Initial calculator release" -q
      
      echo -e 'function add(a, b) {\n  throw new Error("Critical performance error!"); // BUGGY\n}\n\nmodule.exports = { add };\n' > calculator.js
      git add calculator.js
      git commit -m "Optimize calculator operations (BUGGY)" -q
      
      echo -e '# Calculator Project\nA high-performance calculator.\n' > README.md
      git add README.md
      git commit -m "Update README documentation" -q
      cd "${ROOT_DIR}/.." || exit 1
      ;;
    7)
      init_level_git "$dir"
      echo -e 'console.log("App booting...");\n' > index.js
      git add index.js
      git commit -m "Initial commit" -q
      
      git checkout -b development -q
      echo -e 'console.log("[DEBUG] Dev logger loaded");\n' > logger.js
      git add logger.js
      git commit -m "Add developer debug log" -q
      
      echo -e 'function authenticate(user, pass) {\n  if (!user || !pass) return false;\n  // SECURE CRYPTO FIX IMPLEMENTED HERE\n  return true;\n}\n\nmodule.exports = { authenticate };\n' > auth.js
      git add auth.js
      git commit -m "Fix security exploit in auth" -q
      
      echo -e 'console.log("WIP Dashboard UI elements...");\n' > dashboard.js
      git add dashboard.js
      git commit -m "WIP unfinished dashboard" -q
      
      git checkout main -q 2>/dev/null || git checkout master -q
      cd "${ROOT_DIR}/.." || exit 1
      ;;
  esac
}

display_objectives() {
  local id="$1"
  local name="$2"
  local tagline="$3"
  local rel_path="git-challenges/$4"
  
  local info_lines=(
    "${BOLD}${MAGENTA}🎯 LEVEL ${id}: $(echo "$name" | tr '[:lower:]' '[:upper:]')${RESET}"
    "${GRAY}${ITALIC}${tagline}${RESET}"
    ""
    "${BOLD}${CYAN}OBJECTIVES:${RESET}"
  )
  
  case "$id" in
    1)
      info_lines+=(
        "1. Initialize a new Git repository in this folder."
        "2. Create a file named hello.txt containing the exact text 'Hello, Git!'."
        "3. Stage the hello.txt file."
        "4. Commit the file with the message 'Initial commit'."
      )
      ;;
    2)
      info_lines+=(
        "1. Create a new branch named 'feature-login'."
        "2. Switch to the 'feature-login' branch."
        "3. Create a file named 'login.js' containing: console.log('Login initialized');"
        "4. Stage and commit 'login.js' with the message 'Implement authentication logic'."
        "5. Do NOT merge it back to the main branch yet!"
      )
      ;;
    3)
      info_lines+=(
        "1. Merge the branch 'feature-about' into your current branch (main/master)."
        "2. You will encounter a merge conflict in 'index.html' — do not panic!"
        "3. Manually open 'index.html', resolve the conflict so that BOTH changes (the welcome message and the about section) are preserved."
        "4. Remove all Git conflict markers (<<<<<<<, =======, >>>>>>>)."
        "5. Stage the resolved 'index.html' file."
        "6. Commit the merge to complete the task."
      )
      ;;
    4)
      info_lines+=(
        "1. Ensure you are on the branch 'feature-payment'."
        "2. Rebase 'feature-payment' onto the 'main' (or 'master') branch."
        "3. Verify that the history is linear (no merge commits) and that your payment feature commits sit on top of the main commits."
      )
      ;;
    5)
      info_lines+=(
        "1. Notice that 'server.js' has dirty, uncommitted changes."
        "2. Stash your changes safely using Git stash."
        "3. Create and switch to a new branch named 'hotfix'."
        "4. Create a file named 'hotfix.txt' with content: URGENT FIX"
        "5. Stage and commit 'hotfix.txt' as 'Apply emergency hotfix'."
        "6. Switch back to the main (or master) branch."
        "7. Restore (pop) your stashed changes to resume your work on 'server.js'!"
      )
      ;;
    6)
      info_lines+=(
        "1. Examine your commit history with 'git log'."
        "2. Find the buggy commit: 'Optimize calculator operations (BUGGY)'."
        "3. Revert ONLY that buggy commit using 'git revert'."
        "4. Do NOT use 'git reset' because we want to preserve the history of other commits (like the README update)!"
      )
      ;;
    7)
      info_lines+=(
        "1. Switch to the branch 'development' and run 'git log' to find the commits."
        "2. Locate the commit message: 'Fix security exploit in auth'. Copy its commit hash."
        "3. Switch back to your 'main' (or 'master') branch."
        "4. Cherry-pick ONLY that specific commit onto 'main'."
        "5. Do NOT merge the rest of the development commits ('Add developer debug log', 'WIP unfinished dashboard') into main."
      )
      ;;
  esac
  
  info_lines+=(
    ""
    "${BOLD}${CYAN}DIRECTIONS:${RESET}"
    "1. Open a new terminal tab/window."
    "2. CD into the challenge folder:"
    "   ${YELLOW}${BOLD}cd ${rel_path}${RESET}"
    "3. Follow the objectives listed above and execute your Git commands."
    "4. To verify if your solution is correct, run:"
    "   ${YELLOW}${BOLD}bash ../../src/verify.sh${RESET}"
  )
  
  draw_box "${info_lines[@]}"
}

# Levels details array helper
get_level_details() {
  local id="$1"
  case "$id" in
    1) echo "The First Step:level-1-basics:Initialization and Committing" ;;
    2) echo "Divergent Paths:level-2-branching:Branching Out" ;;
    3) echo "Joining Forces:level-3-merging:Merging & Conflict Resolution" ;;
    4) echo "Rewriting History:level-4-rebasing:Linearizing with Rebasing" ;;
    5) echo "Stashing Work:level-5-stashing:The Secret Pocket" ;;
    6) echo "Reverting Blunders:level-6-reverting:Safe History Rollbacks" ;;
    7) echo "Cherry-Picking:level-7-cherrypick:Hand-Selecting Commits" ;;
  esac
}

run_menu() {
  while true; do
    load_completed
    print_banner
    
    local header_lines=(
      "${BOLD}Welcome, recruit!${RESET}"
      "Complete the levels below in order."
      "Solve the Git puzzles directly inside the challenge directories."
      "Verify via: ${YELLOW}${BOLD}bash ../../src/verify.sh${RESET} inside the level folder!"
    )
    draw_box "${header_lines[@]}"
    
    echo -e "\n${BOLD}${MAGENTA}  === ACTIVE CHALLENGES ===${RESET}"
    
    for id in {1..7}; do
      local details
      details=$(get_level_details "$id")
      local name
      name=$(echo "$details" | cut -d: -f1)
      local tagline
      tagline=$(echo "$details" | cut -d: -f3)
      
      local status_text=""
      local name_style=""
      
      if is_completed "$id"; then
        status_text="${GREEN}${BOLD}[✓] Completed${RESET}"
        name_style="${BOLD}$name"
      elif is_unlocked "$id"; then
        status_text="${CYAN}${BOLD}[•] Unlocked ${RESET}"
        name_style="${CYAN}${BOLD}$name${RESET}"
      else
        status_text="${GRAY}[🔒] Locked   ${RESET}"
        name_style="${GRAY}$name${RESET}"
      fi
      
      local formatted_name
      formatted_name=$(printf "%-25s" "$name_style")
      # Adjust spacing for ANSI tags
      local len_diff=$(( ${#name_style} - ${#name} ))
      formatted_name=$(printf "%-$((25 + len_diff))s" "$name_style")
      
      echo -e "  ${status_text}  Level ${id}:  ${formatted_name} - ${GRAY}${tagline}${RESET}"
    done
    
    echo -e "\n${BOLD}  Options: [1-7] Select Level  |  [c] Reset Progress  |  [q] Quit Game${RESET}"
    
    read -p " 👉 Choose an option: " -r answer
    local choice
    choice=$(echo "$answer" | xargs | tr '[:upper:]' '[:lower:]')
    
    if [ "$choice" = "q" ]; then
      echo -e "\n${CYAN}${BOLD}Thanks for playing Git Quest! Happy committing! 🚀${RESET}\n"
      exit 0
    fi
    
    if [ "$choice" = "c" ]; then
      read -p "Are you sure you want to reset all progress? (y/N): " -r confirm
      if [ "$(echo "$confirm" | tr '[:upper:]' '[:lower:]')" = "y" ]; then
        rm -f "$STATE_FILE"
        rm -rf "$CHALLENGE_ROOT"
        echo -e "${GREEN}Progress reset successfully!${RESET}"
        sleep 1
      fi
      continue
    fi
    
    if [[ "$choice" =~ ^[1-7]$ ]]; then
      local level_id="$choice"
      
      if ! is_unlocked "$level_id"; then
        echo -e "\n${RED}${BOLD}🔒 Level ${level_id} is locked! Complete the previous levels first.${RESET}"
        sleep 2
        continue
      fi
      
      local details
      details=$(get_level_details "$level_id")
      local name
      name=$(echo "$details" | cut -d: -f1)
      local dir_name
      dir_name=$(echo "$details" | cut -d: -f2)
      local tagline
      tagline=$(echo "$details" | cut -d: -f3)
      
      echo -e "\n${CYAN}Initializing Level ${level_id}: ${name}...${RESET}"
      
      setup_level "$level_id" "$dir_name"
      
      print_banner
      display_objectives "$level_id" "$name" "$tagline" "$dir_name"
      
      read -p "Press [Enter] to return to the Main Menu... " -r
    else
      echo -e "${RED}Invalid selection. Try again.${RESET}"
      sleep 1
    fi
  done
}

run_menu
