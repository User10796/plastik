import { PlastikData } from '../types/index.js';
import { logger } from '../utils/logger.js';

export interface IntegrityCheckResult {
  passed: boolean;
  warnings: string[];
  errors: string[];
}

export function checkDataIntegrity(data: PlastikData): IntegrityCheckResult {
  const warnings: string[] = [];
  const errors: string[] = [];

  // Check 1: All cards have required fields
  for (const card of data.cards) {
    if (!card.earningRates?.length) {
      warnings.push(`Card ${card.id} has no earning rates`);
    }
    if (card.annualFee > 0 && !card.benefits?.length) {
      warnings.push(`Card ${card.id} has annual fee but no benefits listed`);
    }
  }

  // Check 2: Churn rules reference valid issuers
  const validIssuers = new Set(['chase', 'amex', 'citi', 'capitalOne', 'barclays', 'usBank', 'wellsFargo', 'bankOfAmerica', 'discover']);
  for (const rule of data.churnRules) {
    if (!validIssuers.has(rule.issuer)) {
      errors.push(`Churn rule ${rule.id} has invalid issuer: ${rule.issuer}`);
    }
  }

  // Check 3: Transfer routes reference valid currencies and partners
  const currencyIds = new Set(data.pointsCurrencies?.map(c => c.id) || []);
  const partnerIds = new Set(data.transferPartners?.map(p => p.id) || []);

  for (const route of data.transferRoutes || []) {
    if (currencyIds.size > 0 && !currencyIds.has(route.fromCurrency)) {
      warnings.push(`Transfer route ${route.id} references unknown currency: ${route.fromCurrency}`);
    }
    if (partnerIds.size > 0 && !partnerIds.has(route.toPartner)) {
      warnings.push(`Transfer route ${route.id} references unknown partner: ${route.toPartner}`);
    }
  }

  // Check 4: No duplicate IDs
  const cardIds = data.cards.map(c => c.id);
  const duplicateCards = cardIds.filter((id, i) => cardIds.indexOf(id) !== i);
  if (duplicateCards.length > 0) {
    errors.push(`Duplicate card IDs: ${duplicateCards.join(', ')}`);
  }

  // Check 5: Offers reference valid cards
  const cardIdSet = new Set(cardIds);
  for (const offer of data.offers) {
    if (!cardIdSet.has(offer.cardId)) {
      warnings.push(`Offer ${offer.id} references unknown card: ${offer.cardId}`);
    }
  }

  // Check 6: Data freshness
  const lastUpdated = new Date(data.lastUpdated);
  const daysSinceUpdate = (Date.now() - lastUpdated.getTime()) / (1000 * 60 * 60 * 24);
  if (daysSinceUpdate > 14) {
    warnings.push(`Data is ${Math.floor(daysSinceUpdate)} days old`);
  }

  // Log results
  if (errors.length > 0) {
    logger.error(`Integrity check failed with ${errors.length} errors`);
  }
  if (warnings.length > 0) {
    logger.warn(`Integrity check has ${warnings.length} warnings`);
  }

  return {
    passed: errors.length === 0,
    warnings,
    errors,
  };
}
