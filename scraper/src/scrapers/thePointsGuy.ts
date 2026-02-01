import { BaseScraper } from './base.js';

export class ThePointsGuyScraper extends BaseScraper {
  constructor() {
    super('ThePointsGuy', 'https://thepointsguy.com');
  }

  getUrls(): string[] {
    return [
      // Card valuations
      `${this.baseUrl}/guide/monthly-valuations/`,

      // Transfer partners - Chase
      `${this.baseUrl}/guide/chase-ultimate-rewards-transfer-partners/`,

      // Transfer partners - Amex
      `${this.baseUrl}/guide/amex-membership-rewards-transfer-partners/`,

      // Transfer partners - Citi
      `${this.baseUrl}/guide/citi-thankyou-transfer-partners/`,

      // Transfer partners - Capital One
      `${this.baseUrl}/guide/capital-one-transfer-partners/`,

      // Best offers roundup
      `${this.baseUrl}/guide/best-credit-card-offers/`,
    ];
  }
}
