import { BaseScraper } from './base.js';

export class IssuerSitesScraper extends BaseScraper {
  constructor() {
    super('IssuerSites', '');
  }

  getUrls(): string[] {
    return [
      // Chase
      'https://creditcards.chase.com/rewards-credit-cards/sapphire/preferred',
      'https://creditcards.chase.com/rewards-credit-cards/sapphire/reserve',
      'https://creditcards.chase.com/cash-back-credit-cards/freedom/unlimited',
      'https://creditcards.chase.com/cash-back-credit-cards/freedom/flex',

      // Amex
      'https://www.americanexpress.com/us/credit-cards/card/gold-card/',
      'https://www.americanexpress.com/us/credit-cards/card/platinum-card/',

      // Citi
      'https://www.citi.com/credit-cards/citi-premier-credit-card',

      // Capital One
      'https://www.capitalone.com/credit-cards/venture-x/',
      'https://www.capitalone.com/credit-cards/venture/',
    ];
  }
}
