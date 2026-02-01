import { z } from 'zod';
import { logger } from '../utils/logger.js';

// Zod schemas matching our TypeScript types
const SignupBonusSchema = z.object({
  points: z.number().min(0),
  currency: z.string().min(1),
  spendRequired: z.number().min(0),
  timeframeDays: z.number().min(1),
  expirationDate: z.string().nullable(),
});

const EarningRateSchema = z.object({
  id: z.string(),
  category: z.enum(['dining', 'travel', 'groceries', 'gas', 'streaming', 'online', 'drugstores', 'homeImprovement', 'entertainment', 'utilities', 'other']),
  multiplier: z.number().min(0),
  cap: z.number().nullable(),
  capPeriod: z.enum(['quarterly', 'annual', 'calendarYear', 'monthly']).nullable(),
});

const CardBenefitSchema = z.object({
  id: z.string(),
  name: z.string().min(1),
  value: z.number().min(0),
  resetPeriod: z.enum(['annual', 'calendarYear', 'quarterly', 'monthly', 'none']),
  category: z.string(),
});

const ChurnRuleRefSchema = z.object({
  issuerRules: z.array(z.string()),
  cardSpecificRules: z.array(z.object({
    cardId: z.string(),
    rule: z.string(),
    effectiveDate: z.string().nullable(),
  })),
});

const CreditCardSchema = z.object({
  id: z.string().regex(/^[a-z0-9-]+$/),
  name: z.string().min(1),
  issuer: z.enum(['chase', 'amex', 'citi', 'capitalOne', 'barclays', 'usBank', 'wellsFargo', 'bankOfAmerica', 'discover']),
  network: z.enum(['visa', 'mastercard', 'amex', 'discover']),
  annualFee: z.number().min(0),
  signupBonus: SignupBonusSchema.nullable(),
  earningRates: z.array(EarningRateSchema),
  benefits: z.array(CardBenefitSchema),
  transferPartners: z.array(z.string()),
  churnRules: ChurnRuleRefSchema,
  referralLink: z.string().nullable(),
  imageURL: z.string().nullable(),
  lastUpdated: z.string(),
});

const ChurnRuleSchema = z.object({
  id: z.string(),
  issuer: z.string(),
  ruleType: z.enum(['applicationEligibility', 'bonusEligibility']),
  category: z.enum(['velocityLimit', 'productFamily', 'bonusCooldown', 'lifetimeLanguage', 'existingRelationship', 'maxCards', 'cooldownPeriod']),
  name: z.string(),
  description: z.string(),
  details: z.string(),
  windowMonths: z.number().optional(),
  maxCards: z.number().optional(),
  countsAllIssuers: z.boolean().optional(),
  businessExempt: z.boolean().optional(),
  cooldownMonths: z.number().optional(),
});

const PlastikDataSchema = z.object({
  version: z.string().regex(/^\d+\.\d+\.\d+$/),
  lastUpdated: z.string(),
  cards: z.array(CreditCardSchema),
  offers: z.array(z.any()), // Flexible for now
  churnRules: z.array(ChurnRuleSchema),
  transferPartners: z.array(z.any()),
  transferRoutes: z.array(z.any()).optional().default([]),
  pointsCurrencies: z.array(z.any()).optional().default([]),
  downgradePaths: z.array(z.any()).optional().default([]),
  historicalBonuses: z.array(z.any()).optional().default([]),
});

export function validateData(data: unknown): { valid: boolean; errors: string[] } {
  try {
    PlastikDataSchema.parse(data);
    logger.info('Data validation passed');
    return { valid: true, errors: [] };
  } catch (error) {
    if (error instanceof z.ZodError) {
      const errors = error.errors.map(e => `${e.path.join('.')}: ${e.message}`);
      logger.error(`Validation failed: ${errors.join(', ')}`);
      return { valid: false, errors };
    }
    throw error;
  }
}
