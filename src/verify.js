import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { levels } from './levels.js';
import { 
  colors, 
  style, 
  drawBox, 
  print 
} from './utils.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const SRC_DIR = path.resolve(__dirname);
const ROOT_DIR = path.resolve(SRC_DIR, '..');
const STATE_FILE_PATH = path.join(ROOT_DIR, '.gitquest-state.json');

// Load state helper
function loadState() {
  try {
    if (fs.existsSync(STATE_FILE_PATH)) {
      return JSON.parse(fs.readFileSync(STATE_FILE_PATH, 'utf8'));
    }
  } catch (e) {}
  return { completed: [] };
}

// Save state helper
function saveState(state) {
  try {
    fs.writeFileSync(STATE_FILE_PATH, JSON.stringify(state, null, 2), 'utf8');
  } catch (e) {
    print.error("Failed to update progress state.");
  }
}

// Draw a beautiful success celebration banner
function printCelebration(levelName, nextLevel) {
  const trophy = [
    "      .---.      ",
    "     /     \\     ",
    "    |___________|    ",
    "    |  🏆 SUCCESS|    ",
    "    |___________|    ",
    "     \\         /     ",
    "      `-.   .-'      ",
    "         | |         ",
    "         | |         ",
    "        /   \\        ",
    "       '-----'       "
  ];
  
  console.log("\n");
  trophy.forEach(line => console.log(style(line, colors.yellow, colors.bold)));
  console.log("\n" + style(`🌟 LEVEL PASSED: ${levelName} 🌟`, colors.green, colors.bold) + "\n");
  
  if (nextLevel) {
    drawBox([
      style("🔥 NEXT CHALLENGE UNLOCKED! 🔥", colors.bold, colors.cyan),
      `Level ${nextLevel.id}: ${nextLevel.name} is now available.`,
      "",
      `Return to the main menu with: ${style("npm start", colors.yellow, colors.bold)} (or bash/powershell launchers)`,
      `and choose Level ${nextLevel.id} to initialize your next sandbox.`
    ], { color: colors.green });
  } else {
    drawBox([
      style("🎉 CONGRATULATIONS, GIT MASTER! 🎉", colors.bold, colors.magenta),
      "You have completed all 7 levels of Git Quest!",
      "You have mastered commits, branching, merging, conflict resolution,",
      "rebasing, stashing, reverting, and cherry-picking.",
      "",
      style("Go forth and commit with absolute confidence! 🚀", colors.yellow, colors.bold)
    ], { color: colors.magenta });
  }
  console.log("\n");
}

function verify() {
  const cwd = process.cwd();
  const folderName = path.basename(cwd);
  
  // Parse level ID from folder name (e.g. "level-1-basics")
  const match = folderName.match(/^level-(\d+)-/);
  
  if (!match) {
    // If run from root or outside challenge folders
    print.warn("Verification command must be run inside a specific challenge directory!");
    console.log(style("\nExample Usage:", colors.bold, colors.white));
    console.log(`  1. ${style("cd git-challenges/level-1-basics", colors.yellow)}`);
    console.log(`  2. ${style("node ../../src/verify.js", colors.yellow)}`);
    
    // List what levels have been initialized
    const challengesPath = path.join(ROOT_DIR, 'git-challenges');
    if (fs.existsSync(challengesPath)) {
      const dirs = fs.readdirSync(challengesPath).filter(f => fs.statSync(path.join(challengesPath, f)).isDirectory());
      if (dirs.length > 0) {
        console.log(style("\nInitialized challenges found in your workspace:", colors.bold, colors.cyan));
        dirs.forEach(d => {
          console.log(`  - git-challenges/${style(d, colors.cyan)}`);
        });
      }
    }
    process.exit(1);
  }
  
  const levelId = parseInt(match[1], 10);
  const currentLevel = levels.find(l => l.id === levelId);
  
  if (!currentLevel) {
    print.error(`Unknown level folder: ${folderName}`);
    process.exit(1);
  }
  
  print.title(`Verifying Level ${levelId}: ${currentLevel.name}`);
  console.log(style("Inspecting Git repository state...\n", colors.gray));
  
  const result = currentLevel.verify(cwd);
  
  if (result.success) {
    // Update progress state
    const state = loadState();
    if (!state.completed.includes(levelId)) {
      state.completed.push(levelId);
      state.completed.sort((a, b) => a - b);
      saveState(state);
    }
    
    const nextLevel = levels.find(l => l.id === levelId + 1);
    printCelebration(currentLevel.name, nextLevel);
  } else {
    // Show failure box
    console.log(style("❌ CHALLENGE INCOMPLETE ❌", colors.red, colors.bold));
    console.log(style(`\nError: ${result.message}\n`, colors.white));
    
    if (result.hints && result.hints.length > 0) {
      const hintLines = [
        style("💡 TROUBLESHOOTING HINTS:", colors.bold, colors.yellow),
        ""
      ];
      result.hints.forEach((hint, i) => {
        hintLines.push(`${result.hints.length > 1 ? `${i+1}. ` : ''}${hint}`);
      });
      
      drawBox(hintLines, { color: colors.yellow });
    }
    
    console.log(style("\nKeep trying! Fix the errors and run verification again. 🛠️\n", colors.cyan));
  }
}

verify();
export { verify };
