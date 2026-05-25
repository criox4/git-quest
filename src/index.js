import fs from 'node:fs';
import path from 'node:path';
import readline from 'node:readline';
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
const ROOT_DIR = path.resolve(__dirname, '..');
const STATE_FILE_PATH = path.join(ROOT_DIR, '.gitquest-state.json');
const CHALLENGE_ROOT = path.join(ROOT_DIR, 'git-challenges');

// Load or initialize state
function loadState() {
  try {
    if (fs.existsSync(STATE_FILE_PATH)) {
      return JSON.parse(fs.readFileSync(STATE_FILE_PATH, 'utf8'));
    }
  } catch (e) {
    // Silently fallback if error reading
  }
  return { completed: [] };
}

// Save state
export function saveState(state) {
  try {
    fs.writeFileSync(STATE_FILE_PATH, JSON.stringify(state, null, 2), 'utf8');
  } catch (e) {
    print.error("Failed to save progress state.");
  }
}

// Print a beautiful ASCII Banner
function printBanner() {
  console.clear();
  const banner = [
    "  ________.__  __     ________                       __   ",
    " /  _____/|__|/  |_   \\_____  \\  __ __   ____   _____/  |_ ",
    "/   \\  ___|  \\   __\\   /  / \\  \\|  |  \\_/ __ \\ /  ___|   __\\",
    "\\    \\_\\  \\  ||  |    /   \\_/.  \\  |  /\\  ___/ \\___ \\ |  |  ",
    " \\______  /__||__|    \\_____\\ \\_/____/  \\___  >____  >|__|  ",
    "        \\/                   \\__>           \\/     \\/       "
  ];
  
  console.log("");
  banner.forEach(line => console.log(style(line, colors.cyan, colors.bold)));
  console.log(style("       --- Master Git Interactive Learning & Testing Suite ---", colors.gray, colors.italic));
  console.log("");
}

// Render menu and prompt user selection
function runGame() {
  const state = loadState();
  printBanner();
  
  // Header box
  drawBox([
    style("Welcome, recruit!", colors.bold, colors.white),
    "Complete the levels below in order.",
    "Solve the Git puzzles directly inside the challenge directories.",
    style(`Verify via: ${style("node ../../verify.js", colors.yellow, colors.bold)} inside the level folder!`, colors.cyan)
  ], { color: colors.magenta, padding: 1 });
  
  console.log(style("\n  === ACTIVE CHALLENGES ===", colors.bold, colors.magenta));
  
  // List levels
  levels.forEach((level, index) => {
    const isCompleted = state.completed.includes(level.id);
    const isUnlocked = level.id === 1 || state.completed.includes(level.id - 1);
    
    let statusText = '';
    let nameStyle = '';
    
    if (isCompleted) {
      statusText = style("[✓] Completed", colors.green, colors.bold);
      nameStyle = style(level.name, colors.white, colors.bold);
    } else if (isUnlocked) {
      statusText = style("[•] Unlocked ", colors.cyan, colors.bold);
      nameStyle = style(level.name, colors.cyan, colors.bold);
    } else {
      statusText = style("[🔒] Locked   ", colors.gray);
      nameStyle = style(level.name, colors.gray);
    }
    
    const levelNumber = `Level ${level.id}:`.padEnd(9);
    console.log(`  ${statusText}  ${levelNumber} ${nameStyle.padEnd(45)} - ${style(level.tagline, colors.gray)}`);
  });
  
  console.log(style("\n  Options: [1-7] Select Level  |  [c] Reset Progress  |  [q] Quit Game", colors.bold, colors.white));
  
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
  
  rl.question(style('\n 👉 Choose an option: ', colors.magenta, colors.bold), (answer) => {
    rl.close();
    const cleanAnswer = answer.trim().toLowerCase();
    
    if (cleanAnswer === 'q') {
      console.log(style("\nThanks for playing Git Quest! Happy committing! 🚀\n", colors.cyan, colors.bold));
      process.exit(0);
    }
    
    if (cleanAnswer === 'c') {
      const rlConfirm = readline.createInterface({
        input: process.stdin,
        output: process.stdout
      });
      rlConfirm.question(style('Are you sure you want to reset all progress? (y/N): ', colors.red, colors.bold), (confirm) => {
        rlConfirm.close();
        if (confirm.trim().toLowerCase() === 'y') {
          saveState({ completed: [] });
          // Optionally delete challenges folder to clean
          if (fs.existsSync(CHALLENGE_ROOT)) {
            fs.rmSync(CHALLENGE_ROOT, { recursive: true, force: true });
          }
          console.log(style("Progress reset successfully!", colors.green));
          setTimeout(runGame, 1000);
        } else {
          runGame();
        }
      });
      return;
    }
    
    const levelId = parseInt(cleanAnswer, 10);
    if (isNaN(levelId) || levelId < 1 || levelId > 7) {
      console.log(style("Invalid selection. Try again.", colors.red));
      setTimeout(runGame, 1000);
      return;
    }
    
    const selectedLevel = levels.find(l => l.id === levelId);
    const isUnlocked = levelId === 1 || state.completed.includes(levelId - 1);
    
    if (!isUnlocked) {
      console.log(style(`\n🔒 Level ${levelId} is locked! Complete the previous levels first.`, colors.red, colors.bold));
      setTimeout(runGame, 2000);
      return;
    }
    
    // Initialize challenge folder
    console.log(style(`\nInitializing Level ${levelId}: ${selectedLevel.name}...`, colors.cyan));
    const targetDir = path.join(CHALLENGE_ROOT, selectedLevel.dirName);
    
    try {
      selectedLevel.setup(targetDir);
      
      console.clear();
      printBanner();
      
      const relativePath = path.relative(ROOT_DIR, targetDir);
      
      const infoLines = [
        style(`🎯 LEVEL ${selectedLevel.id}: ${selectedLevel.name.toUpperCase()}`, colors.bold, colors.magenta),
        style(selectedLevel.tagline, colors.gray, colors.italic),
        "",
        style("OBJECTIVES:", colors.bold, colors.cyan),
        ...selectedLevel.objectives.map((obj, i) => `${i + 1}. ${obj}`),
        "",
        style("DIRECTIONS:", colors.bold, colors.cyan),
        `1. CD into the challenge folder:`,
        `   ${style(`cd ${relativePath}`, colors.yellow, colors.bold)}`,
        `2. Execute the required Git actions inside that folder.`,
        `3. To verify if your solution is correct, run:`,
        `   ${style("node ../../src/verify.js", colors.yellow, colors.bold)}`
      ];
      
      drawBox(infoLines, { color: colors.cyan, padding: 1 });
      
      console.log(style(`\n🚀 Sandbox successfully initialized! Your terminal is ready.`, colors.green, colors.bold));
      console.log(style(`👉 Run: cd ${relativePath}\n`, colors.yellow, colors.bold));
      process.exit(0);
      
    } catch (e) {
      print.error(`Failed to initialize level: ${e.message}`);
      const rlErr = readline.createInterface({
        input: process.stdin,
        output: process.stdout
      });
      rlErr.question('Press Enter to retry...', () => {
        rlErr.close();
        runGame();
      });
    }
  });
}

// Start game
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  runGame();
}
export { runGame };
