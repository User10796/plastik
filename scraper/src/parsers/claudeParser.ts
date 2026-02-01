import Anthropic from '@anthropic-ai/sdk';
import { CreditCard, CardOffer, ChurnRule, TransferBonus } from '../types/index.js';
import { logger } from '../utils/logger.js';

const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

export class ClaudeParser {
  private model = 'claude-sonnet-4-20250514';
  private maxTokens = 4096;

  async parseSignupBonuses(html: string, source: string): Promise<Partial<CardOffer>[]> {
    const prompt = `You are a data extraction assistant. Extract credit card signup bonus information from the following HTML content.

Return a JSON array of objects with this structure:
{
  "cardId": "lowercase-hyphenated-card-name (e.g., chase-sapphire-preferred)",
  "cardName": "Full Card Name",
  "issuer": "chase|amex|citi|capitalOne|barclays|usBank|wellsFargo|bankOfAmerica|discover",
  "bonusPoints": number,
  "bonusCurrency": "Points currency name",
  "spendRequired": number,
  "timeframeDays": number,
  "expirationDate": "YYYY-MM-DD or null",
  "isTargeted": boolean,
  "source": "${source}"
}

Only extract clearly stated bonus offers. If information is unclear or missing, omit that offer.

HTML Content:
${this.truncateContent(html, 50000)}

Return ONLY the JSON array, no other text.`;

    try {
      const response = await anthropic.messages.create({
        model: this.model,
        max_tokens: this.maxTokens,
        messages: [{ role: 'user', content: prompt }],
      });

      const content = response.content[0];
      if (content.type !== 'text') {
        throw new Error('Unexpected response type');
      }

      const parsed = JSON.parse(content.text);
      logger.info(`Parsed ${parsed.length} bonus offers from ${source}`);
      return parsed;

    } catch (error) {
      logger.error(`Failed to parse bonuses: ${error}`);
      return [];
    }
  }

  async parseChurnRules(html: string, source: string): Promise<Partial<ChurnRule>[]> {
    const prompt = `You are a data extraction assistant. Extract credit card application rules and restrictions from the following HTML content.

Return a JSON array of objects with this structure:
{
  "id": "issuer-rule-name-lowercase-hyphenated",
  "issuer": "chase|amex|citi|capitalOne|barclays|usBank|wellsFargo|bankOfAmerica|discover",
  "ruleType": "applicationEligibility|bonusEligibility",
  "category": "velocityLimit|productFamily|bonusCooldown|lifetimeLanguage|existingRelationship|maxCards|cooldownPeriod",
  "name": "Short Rule Name (e.g., 5/24 Rule)",
  "description": "One sentence description",
  "details": "Full explanation with specific numbers and conditions",
  "windowMonths": number or null,
  "maxCards": number or null,
  "countsAllIssuers": boolean or null,
  "businessExempt": boolean or null,
  "cooldownMonths": number or null
}

Focus on extracting:
1. Velocity limits (X cards in Y months)
2. Product family restrictions (can't hold both cards)
3. Bonus cooldown periods
4. Lifetime language restrictions
5. Application spacing rules

HTML Content:
${this.truncateContent(html, 50000)}

Return ONLY the JSON array, no other text.`;

    try {
      const response = await anthropic.messages.create({
        model: this.model,
        max_tokens: this.maxTokens,
        messages: [{ role: 'user', content: prompt }],
      });

      const content = response.content[0];
      if (content.type !== 'text') {
        throw new Error('Unexpected response type');
      }

      const parsed = JSON.parse(content.text);
      logger.info(`Parsed ${parsed.length} churn rules from ${source}`);
      return parsed;

    } catch (error) {
      logger.error(`Failed to parse churn rules: ${error}`);
      return [];
    }
  }

  async parseTransferPartners(html: string, source: string): Promise<{
    partners: Partial<any>[],
    routes: Partial<any>[],
    bonuses: Partial<TransferBonus>[]
  }> {
    const prompt = `You are a data extraction assistant. Extract transfer partner information from the following HTML content.

Return a JSON object with three arrays:

1. "partners": Array of transfer partner programs
{
  "id": "lowercase-hyphenated-name",
  "name": "Full Program Name",
  "type": "airline|hotel",
  "alliance": "Star Alliance|OneWorld|SkyTeam|null"
}

2. "routes": Array of transfer routes
{
  "id": "from-currency-to-partner",
  "fromCurrency": "chase-ur|amex-mr|citi-typ|capital-one|bilt",
  "toPartner": "partner-id",
  "ratio": number (1.0 means 1:1),
  "transferTime": "instant|sameDay|oneToTwoDays|twoToThreeDays|threeToFiveDays|oneWeekPlus",
  "minimumTransfer": number
}

3. "bonuses": Array of current transfer bonuses (if any mentioned)
{
  "fromCurrency": "currency-id",
  "toPartner": "partner-id",
  "bonusPercent": number,
  "endDate": "YYYY-MM-DD or null",
  "description": "Brief description"
}

HTML Content:
${this.truncateContent(html, 50000)}

Return ONLY the JSON object with partners, routes, and bonuses arrays.`;

    try {
      const response = await anthropic.messages.create({
        model: this.model,
        max_tokens: this.maxTokens,
        messages: [{ role: 'user', content: prompt }],
      });

      const content = response.content[0];
      if (content.type !== 'text') {
        throw new Error('Unexpected response type');
      }

      const parsed = JSON.parse(content.text);
      logger.info(`Parsed ${parsed.partners?.length || 0} partners, ${parsed.routes?.length || 0} routes, ${parsed.bonuses?.length || 0} bonuses from ${source}`);
      return parsed;

    } catch (error) {
      logger.error(`Failed to parse transfer partners: ${error}`);
      return { partners: [], routes: [], bonuses: [] };
    }
  }

  async parseCardDetails(html: string, cardId: string): Promise<Partial<CreditCard> | null> {
    const prompt = `You are a data extraction assistant. Extract credit card details from the following issuer webpage.

Return a JSON object with this structure:
{
  "id": "${cardId}",
  "name": "Full Card Name",
  "issuer": "chase|amex|citi|capitalOne|barclays|usBank|wellsFargo|bankOfAmerica|discover",
  "network": "visa|mastercard|amex|discover",
  "annualFee": number,
  "signupBonus": {
    "points": number,
    "currency": "Points currency name",
    "spendRequired": number,
    "timeframeDays": number,
    "expirationDate": null
  } or null,
  "earningRates": [
    {
      "category": "dining|travel|groceries|gas|streaming|online|drugstores|entertainment|other",
      "multiplier": number,
      "cap": number or null,
      "capPeriod": "quarterly|annual|calendarYear|monthly" or null
    }
  ],
  "benefits": [
    {
      "name": "Benefit name",
      "value": number (dollar value, 0 if not quantifiable),
      "resetPeriod": "annual|calendarYear|quarterly|monthly|none",
      "category": "travel|dining|entertainment|other"
    }
  ]
}

Extract all information visible on the page. For earning rates, include all bonus categories mentioned.

HTML Content:
${this.truncateContent(html, 50000)}

Return ONLY the JSON object, no other text.`;

    try {
      const response = await anthropic.messages.create({
        model: this.model,
        max_tokens: this.maxTokens,
        messages: [{ role: 'user', content: prompt }],
      });

      const content = response.content[0];
      if (content.type !== 'text') {
        throw new Error('Unexpected response type');
      }

      const parsed = JSON.parse(content.text);
      logger.info(`Parsed card details for ${cardId}`);
      return parsed;

    } catch (error) {
      logger.error(`Failed to parse card details for ${cardId}: ${error}`);
      return null;
    }
  }

  private truncateContent(content: string, maxChars: number): string {
    if (content.length <= maxChars) return content;

    // Try to truncate at a reasonable point
    const truncated = content.slice(0, maxChars);
    const lastParagraph = truncated.lastIndexOf('</p>');
    const lastDiv = truncated.lastIndexOf('</div>');
    const cutPoint = Math.max(lastParagraph, lastDiv, maxChars - 1000);

    return content.slice(0, cutPoint) + '\n[Content truncated...]';
  }
}

export const claudeParser = new ClaudeParser();
