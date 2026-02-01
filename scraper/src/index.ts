import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join } from 'path';
import {
  DoctorOfCreditScraper,
  ThePointsGuyScraper,
  IssuerSitesScraper,
} from './scrapers/index.js';
import { claudeParser } from './parsers/claudeParser.js';
import { dataMerger } from './utils/dataMerger.js';
import { validateData } from './validators/schemaValidator.js';
import { checkDataIntegrity } from './validators/dataIntegrity.js';
import { logger } from './utils/logger.js';
import { PlastikData, CreditCard, ScrapeResult } from './types/index.js';

const DATA_FILE = join(process.cwd(), '..', 'data', 'cards.json');

async function main() {
  logger.info('Starting Plastik data scraper');

  const forceUpdate = process.env.FORCE_UPDATE === 'true';
  const dryRun = process.env.DRY_RUN === 'true';

  if (dryRun) {
    logger.info('Running in DRY RUN mode - no changes will be saved');
  }

  // Load existing data
  let existingData: PlastikData;
  if (existsSync(DATA_FILE)) {
    existingData = JSON.parse(readFileSync(DATA_FILE, 'utf-8'));
    logger.info(`Loaded existing data: version ${existingData.version}`);
  } else {
    logger.error('No existing data file found');
    process.exit(1);
  }

  // Initialize scrapers
  const scrapers = [
    new DoctorOfCreditScraper(),
    new ThePointsGuyScraper(),
    new IssuerSitesScraper(),
  ];

  // Scrape all sources
  const allResults: ScrapeResult[] = [];

  for (const scraper of scrapers) {
    logger.info(`Running ${scraper.constructor.name}`);
    const results = await scraper.scrape();
    allResults.push(...results);
  }

  const successCount = allResults.filter(r => r.success).length;
  logger.info(`Scraped ${successCount}/${allResults.length} URLs successfully`);

  if (successCount === 0) {
    logger.error('All scraping failed. Aborting.');
    process.exit(1);
  }

  // Parse with Claude API
  const parsedData: Partial<PlastikData> = {
    offers: [],
    churnRules: [],
    transferPartners: [],
    transferRoutes: [],
  };

  for (const result of allResults.filter(r => r.success)) {
    // Parse based on URL/source
    if (result.url.includes('sign-bonuses') || result.url.includes('best-credit-card-offers')) {
      const offers = await claudeParser.parseSignupBonuses(result.rawContent, result.source);
      parsedData.offers!.push(...offers as any[]);
    }

    if (result.url.includes('application-restrictions')) {
      const rules = await claudeParser.parseChurnRules(result.rawContent, result.source);
      parsedData.churnRules!.push(...rules as any[]);
    }

    if (result.url.includes('transfer-partner')) {
      const { partners, routes } = await claudeParser.parseTransferPartners(result.rawContent, result.source);
      parsedData.transferPartners!.push(...partners as any[]);
      parsedData.transferRoutes!.push(...routes as any[]);
    }

    // Parse individual card pages from issuer sites
    if (result.source === 'IssuerSites') {
      const cardId = inferCardId(result.url);
      if (cardId) {
        const cardDetails = await claudeParser.parseCardDetails(result.rawContent, cardId);
        if (cardDetails) {
          if (!parsedData.cards) parsedData.cards = [];
          parsedData.cards.push(cardDetails as CreditCard);
        }
      }
    }
  }

  // Merge with existing data
  const mergedData = dataMerger.merge(existingData, parsedData);

  // Validate
  const schemaValidation = validateData(mergedData);
  if (!schemaValidation.valid) {
    logger.error('Schema validation failed');
    schemaValidation.errors.forEach(e => logger.error(e));
    process.exit(1);
  }

  const integrityCheck = checkDataIntegrity(mergedData);
  if (!integrityCheck.passed) {
    logger.error('Integrity check failed');
    integrityCheck.errors.forEach(e => logger.error(e));
    process.exit(1);
  }

  integrityCheck.warnings.forEach(w => logger.warn(w));

  // Save (unless dry run)
  if (dryRun) {
    logger.info('Dry run - not saving changes');
    logger.info(`Would update to version ${mergedData.version}`);
    logger.info(`Cards: ${mergedData.cards.length}, Offers: ${mergedData.offers.length}, Rules: ${mergedData.churnRules.length}`);
  } else {
    writeFileSync(DATA_FILE, JSON.stringify(mergedData, null, 2));
    logger.info(`Saved updated data: version ${mergedData.version}`);
  }

  logger.info('Scraper completed successfully');
}

/**
 * Infer a card ID from an issuer URL.
 */
function inferCardId(url: string): string | null {
  const urlCardMap: Record<string, string> = {
    'sapphire/preferred': 'chase-sapphire-preferred',
    'sapphire/reserve': 'chase-sapphire-reserve',
    'freedom/unlimited': 'chase-freedom-unlimited',
    'freedom/flex': 'chase-freedom-flex',
    'gold-card': 'amex-gold',
    'platinum-card': 'amex-platinum',
    'citi-premier': 'citi-premier',
    'venture-x': 'capital-one-venture-x',
    'credit-cards/venture': 'capital-one-venture',
  };

  for (const [pattern, cardId] of Object.entries(urlCardMap)) {
    if (url.includes(pattern)) {
      return cardId;
    }
  }

  return null;
}

main().catch(error => {
  logger.error(`Fatal error: ${error.message}`);
  process.exit(1);
});
