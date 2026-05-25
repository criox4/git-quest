import { execSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

// ANSI escape codes for styling
export const colors = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  dim: '\x1b[2m',
  italic: '\x1b[3m',
  underline: '\x1b[4m',
  
  // Foreground colors
  black: '\x1b[30m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  white: '\x1b[37m',
  gray: '\x1b[90m',
  
  // Background colors
  bgBlack: '\x1b[40m',
  bgRed: '\x1b[41m',
  bgGreen: '\x1b[42m',
  bgYellow: '\x1b[43m',
  bgBlue: '\x1b[44m',
  bgMagenta: '\x1b[45m',
  bgCyan: '\x1b[46m',
  bgWhite: '\x1b[47m'
};

// Styling helper functions
export const style = (text, ...styles) => {
  const prefix = styles.join('');
  return `${prefix}${text}${colors.reset}`;
};

export const print = {
  info: (msg) => console.log(style('ℹ ' + msg, colors.cyan)),
  success: (msg) => console.log(style('✔ ' + msg, colors.green, colors.bold)),
  warn: (msg) => console.log(style('⚠ ' + msg, colors.yellow, colors.bold)),
  error: (msg) => console.log(style('✘ ' + msg, colors.red, colors.bold)),
  title: (msg) => console.log('\n' + style(` === ${msg.toUpperCase()} === `, colors.magenta, colors.bold) + '\n'),
  muted: (msg) => console.log(style(msg, colors.gray))
};

// Draws a beautiful ASCII box around an array of strings
export function drawBox(lines, options = {}) {
  const borderColor = options.color || colors.cyan;
  const padding = options.padding !== undefined ? options.padding : 1;
  const maxWidth = Math.max(...lines.map(line => line.replace(/\x1b\[\d+m/g, '').length));
  
  const borderChar = {
    topLeft: '╭',
    topRight: '╮',
    bottomLeft: '╰',
    bottomRight: '╯',
    horizontal: '─',
    vertical: '│'
  };

  const topBorder = borderChar.topLeft + borderChar.horizontal.repeat(maxWidth + padding * 2) + borderChar.topRight;
  const bottomBorder = borderChar.bottomLeft + borderChar.horizontal.repeat(maxWidth + padding * 2) + borderChar.bottomRight;
  
  console.log(style(topBorder, borderColor));
  
  // Top padding
  for (let i = 0; i < padding; i++) {
    console.log(style(borderChar.vertical, borderColor) + ' '.repeat(maxWidth + padding * 2) + style(borderChar.vertical, borderColor));
  }
  
  for (const line of lines) {
    const rawLength = line.replace(/\x1b\[\d+m/g, '').length;
    const spaceRight = maxWidth - rawLength;
    const paddedLine = ' '.repeat(padding) + line + ' '.repeat(spaceRight + padding);
    console.log(style(borderChar.vertical, borderColor) + paddedLine + style(borderChar.vertical, borderColor));
  }

  // Bottom padding
  for (let i = 0; i < padding; i++) {
    console.log(style(borderChar.vertical, borderColor) + ' '.repeat(maxWidth + padding * 2) + style(borderChar.vertical, borderColor));
  }
  
  console.log(style(bottomBorder, borderColor));
}

// Git command runner with working directory context
export function runGitCommand(cmd, cwd) {
  try {
    return execSync(`git ${cmd}`, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();
  } catch (error) {
    // Return standard error output if command failed
    return {
      failed: true,
      stdout: error.stdout ? error.stdout.toString().trim() : '',
      stderr: error.stderr ? error.stderr.toString().trim() : error.message
    };
  }
}

// Safely execute shell command
export function runShellCommand(cmd, cwd) {
  try {
    return execSync(cmd, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();
  } catch (error) {
    return {
      failed: true,
      stdout: error.stdout ? error.stdout.toString().trim() : '',
      stderr: error.stderr ? error.stderr.toString().trim() : error.message
    };
  }
}

// Helper to check if a directory is a Git repository
export function isGitRepo(dir) {
  if (!fs.existsSync(dir)) return false;
  // Ensure the local folder has its own .git directory directly
  const dotGitPath = path.join(dir, '.git');
  return fs.existsSync(dotGitPath) && fs.statSync(dotGitPath).isDirectory();
}

// Helper to get active branch name
export function getActiveBranch(dir) {
  const result = runGitCommand('rev-parse --abbrev-ref HEAD', dir);
  if (result.failed) return null;
  return result;
}

// Read file helper
export function readFileContent(filePath) {
  try {
    return fs.readFileSync(filePath, 'utf8');
  } catch (e) {
    return null;
  }
}

// Write file helper
export function writeFileContent(filePath, content) {
  try {
    const dir = path.dirname(filePath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(filePath, content, 'utf8');
    return true;
  } catch (e) {
    return false;
  }
}
