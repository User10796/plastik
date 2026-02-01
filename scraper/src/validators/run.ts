import { readFileSync, existsSync } from 'fs';
import { join } from 'path';
import { validateData } from './schemaValidator.js';
import { checkDataIntegrity } from './dataIntegrity.js';
import { logger } from '../utils/logger.js';

const DATA_FILE = join(process.cwd(), '..', 'data', 'cards.json');

function main() {
  logger.info('Running data validation...');

  if (!existsSync(DATA_FILE)) {
    logger.error(`Data file not found: ${DATA_FILE}`);
    process.exit(1);
  }

  const data = JSON.parse(readFileSync(DATA_FILE, 'utf-8'));

  // Schema validation
  const schemaResult = validateData(data);
  if (!schemaResult.valid) {
    logger.error('Schema validation FAILED:');
    schemaResult.errors.forEach(e => logger.error(`  - ${e}`));
    process.exit(1);
  }
  logger.info('Schema validation passed');

  // Integrity checks
  const integrityResult = checkDataIntegrity(data);
  if (!integrityResult.passed) {
    logger.error('Integrity check FAILED:');
    integrityResult.errors.forEach(e => logger.error(`  - ${e}`));
    process.exit(1);
  }

  if (integrityResult.warnings.length > 0) {
    logger.warn('Integrity warnings:');
    integrityResult.warnings.forEach(w => logger.warn(`  - ${w}`));
  }

  logger.info('All validation passed!');
  logger.info(`Data version: ${data.version}`);
  logger.info(`Cards: ${data.cards?.length || 0}`);
  logger.info(`Offers: ${data.offers?.length || 0}`);
  logger.info(`Churn Rules: ${data.churnRules?.length || 0}`);
  logger.info(`Transfer Partners: ${data.transferPartners?.length || 0}`);
}

main();
