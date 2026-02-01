import { BaseScraper } from './base.js';

export class DoctorOfCreditScraper extends BaseScraper {
  constructor() {
    super('DoctorOfCredit', 'https://www.doctorofcredit.com');
  }

  getUrls(): string[] {
    return [
      // Churn rules
      `${this.baseUrl}/credit-card-application-restrictions/`,

      // Best current offers
      `${this.baseUrl}/best-current-credit-card-sign-bonuses/`,

      // Historical bonuses tracker
      `${this.baseUrl}/best-current-credit-card-sign-bonuses/historical/`,

      // Transfer partner bonuses
      `${this.baseUrl}/airline-hotel-transfer-bonus-history/`,
    ];
  }
}
