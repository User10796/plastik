import { PlastikData, CreditCard, ChurnRule } from '../types/index.js';
import { logger } from './logger.js';

export class DataMerger {

  /**
   * Merge new scraped data into existing data, preserving manual edits
   * and only updating fields that have changed.
   */
  merge(existing: PlastikData, scraped: Partial<PlastikData>): PlastikData {
    const merged: PlastikData = {
      ...existing,
      version: this.incrementVersion(existing.version),
      lastUpdated: new Date().toISOString(),
    };

    // Merge cards
    if (scraped.cards) {
      merged.cards = this.mergeArray(
        existing.cards,
        scraped.cards as CreditCard[],
        'id',
        this.mergeCard.bind(this)
      );
    }

    // Merge offers (replace entirely - offers are time-sensitive)
    if (scraped.offers) {
      merged.offers = scraped.offers as any[];
    }

    // Merge churn rules
    if (scraped.churnRules) {
      merged.churnRules = this.mergeArray(
        existing.churnRules,
        scraped.churnRules as ChurnRule[],
        'id',
        this.mergeChurnRule.bind(this)
      );
    }

    // Merge transfer partners (additive)
    if (scraped.transferPartners) {
      merged.transferPartners = this.mergeArray(
        existing.transferPartners,
        scraped.transferPartners as any[],
        'id',
        (existing: any, scraped: any) => ({ ...existing, ...scraped })
      );
    }

    // Merge transfer routes
    if (scraped.transferRoutes) {
      merged.transferRoutes = this.mergeArray(
        existing.transferRoutes,
        scraped.transferRoutes as any[],
        'id',
        (existing: any, scraped: any) => ({ ...existing, ...scraped })
      );
    }

    return merged;
  }

  private mergeArray<T extends Record<string, any>>(
    existing: T[],
    scraped: T[],
    idField: keyof T,
    mergeFn: (existing: T, scraped: T) => T
  ): T[] {
    const existingMap = new Map(existing.map(item => [item[idField], item]));
    const result: T[] = [];

    // Update existing items and add new ones
    for (const scrapedItem of scraped) {
      const id = scrapedItem[idField];
      const existingItem = existingMap.get(id);

      if (existingItem) {
        result.push(mergeFn(existingItem, scrapedItem));
        existingMap.delete(id);
      } else {
        result.push(scrapedItem);
        logger.info(`Added new item: ${String(id)}`);
      }
    }

    // Keep items that weren't in scraped data (manual additions)
    for (const [, item] of existingMap) {
      result.push(item);
    }

    return result;
  }

  private mergeCard(existing: CreditCard, scraped: CreditCard): CreditCard {
    // Only update fields that have actually changed
    const merged: CreditCard = { ...existing };

    // Always update these fields if scraped
    if (scraped.annualFee !== undefined) merged.annualFee = scraped.annualFee;
    if (scraped.signupBonus) merged.signupBonus = scraped.signupBonus;
    if (scraped.earningRates?.length) merged.earningRates = scraped.earningRates;
    if (scraped.benefits?.length) merged.benefits = scraped.benefits;

    // Preserve manual fields
    // (referralLink, imageURL are manually maintained)

    merged.lastUpdated = new Date().toISOString();

    return merged;
  }

  private mergeChurnRule(existing: ChurnRule, scraped: ChurnRule): ChurnRule {
    // For churn rules, prefer scraped data but keep existing details if richer
    return {
      ...existing,
      ...scraped,
      details: (scraped.details?.length || 0) > (existing.details?.length || 0)
        ? scraped.details
        : existing.details,
    };
  }

  private incrementVersion(version: string): string {
    const parts = version.split('.').map(Number);
    parts[2] = (parts[2] || 0) + 1; // Increment patch version
    return parts.join('.');
  }
}

export const dataMerger = new DataMerger();
