#!/usr/bin/env node
/**
 * Prevue: Cross-platform .env.production Generator & Base64 Encoder/Decoder
 *
 * Usage:
 *   Decode:
 *     node scripts/generate-env.js --decode [base64_string]
 *     ENV_PRODUCTION_BASE64="<base64>" node scripts/generate-env.js
 *
 *   Encode:
 *     node scripts/generate-env.js --encode [path_to_env]
 */

const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
const rootDir = path.resolve(__dirname, '..');
const defaultTarget = path.join(rootDir, '.env.production');

let mode = 'decode';
let inputB64 = process.env.ENV_PRODUCTION_BASE64 || '';
let targetPath = defaultTarget;
let sourcePath = defaultTarget;

for (let i = 0; i < args.length; i++) {
  const arg = args[i];
  if (arg === '--decode' || arg === '-d') {
    mode = 'decode';
    if (args[i + 1] && !args[i + 1].startsWith('-')) {
      inputB64 = args[++i];
    }
  } else if (arg === '--encode' || arg === '-e') {
    mode = 'encode';
    if (args[i + 1] && !args[i + 1].startsWith('-')) {
      sourcePath = path.resolve(process.cwd(), args[++i]);
    }
  } else if (arg === '--out' || arg === '-o') {
    if (args[i + 1]) {
      targetPath = path.resolve(process.cwd(), args[++i]);
    }
  } else if (arg === '--help' || arg === '-h') {
    console.log(`
Prevue CI/CD .env.production generator (Node.js)

Commands:
  --decode [b64_string]   Decode Base64 to .env.production (default)
  --encode [file_path]    Encode .env file to Base64 string for CI/CD secrets
  --out [output_path]     Specify custom output file path
`);
    process.exit(0);
  } else if (!inputB64 && mode === 'decode') {
    inputB64 = arg;
  }
}

if (mode === 'encode') {
  if (!fs.existsSync(sourcePath)) {
    // Try fallback locations
    const candidates = [
      path.join(rootDir, '.env.production'),
      path.join(rootDir, '.env'),
      path.join(process.cwd(), '.env.production'),
      path.join(process.cwd(), '.env'),
    ];
    const found = candidates.find(c => fs.existsSync(c));
    if (found) {
      sourcePath = found;
    } else {
      console.error(`❌ Error: Source file not found: ${sourcePath}`);
      process.exit(1);
    }
  }

  const content = fs.readFileSync(sourcePath, 'utf8');
  const base64 = Buffer.from(content, 'utf8').toString('base64');
  console.log('\n🔒 Encoded .env file to Base64 for CI/CD secrets:');
  console.log('==================== BASE64 STRING (COPY BELOW) ====================');
  console.log(base64);
  console.log('====================================================================\n');
  console.log('💡 Save this in GitHub Secrets as: ENV_PRODUCTION_BASE64\n');
  process.exit(0);
}

if (mode === 'decode') {
  if (!inputB64) {
    if (fs.existsSync(targetPath)) {
      console.log(`ℹ️ Target file '${targetPath}' already exists. Skipping decode.`);
      process.exit(0);
    }
    console.error('❌ Error: No Base64 string provided via ENV_PRODUCTION_BASE64 or argument.');
    console.error('Usage: node scripts/generate-env.js --decode <base64_string>');
    process.exit(1);
  }

  try {
    const cleanB64 = inputB64.trim().replace(/\r?\n|\r/g, '');
    const decoded = Buffer.from(cleanB64, 'base64').toString('utf8');

    if (!decoded || decoded.length === 0) {
      throw new Error('Decoded output is empty.');
    }

    fs.mkdirSync(path.dirname(targetPath), { recursive: true });
    fs.writeFileSync(targetPath, decoded, { mode: 0o600 });

    // Also write to .env as fallback
    const envFallback = path.join(path.dirname(targetPath), '.env');
    fs.writeFileSync(envFallback, decoded, { mode: 0o600 });

    console.log(`✅ Successfully generated production environment configuration:`);
    console.log(`   - Output: ${targetPath}`);
    console.log(`   - Fallback: ${envFallback}`);
    console.log(`   - Size: ${decoded.length} bytes`);
  } catch (err) {
    console.error(`❌ Failed to decode Base64 string:`, err.message);
    process.exit(1);
  }
}
