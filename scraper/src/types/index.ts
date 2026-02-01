// Mirror the iOS app's data model

export interface PlastikData {
  version: string;
  lastUpdated: string;
  cards: CreditCard[];
  offers: CardOffer[];
  churnRules: ChurnRule[];
  transferPartners: TransferPartner[];
  transferRoutes: TransferRoute[];
  pointsCurrencies: PointsCurrency[];
  downgradePaths: DowngradePath[];
  historicalBonuses: HistoricalBonus[];
}

export interface CreditCard {
  id: string;
  name: string;
  issuer: Issuer;
  network: CardNetwork;
  annualFee: number;
  signupBonus: SignupBonus | null;
  earningRates: EarningRate[];
  benefits: CardBenefit[];
  transferPartners: string[];
  churnRules: ChurnRuleRef;
  referralLink: string | null;
  imageURL: string | null;
  lastUpdated: string;
}

export interface ChurnRuleRef {
  issuerRules: string[];
  cardSpecificRules: CardRule[];
}

export interface CardRule {
  cardId: string;
  rule: string;
  effectiveDate: string | null;
}

export interface SignupBonus {
  points: number;
  currency: string;
  spendRequired: number;
  timeframeDays: number;
  expirationDate: string | null;
}

export interface EarningRate {
  id: string;
  category: SpendCategory;
  multiplier: number;
  cap: number | null;
  capPeriod: CapPeriod | null;
}

export interface CardBenefit {
  id: string;
  name: string;
  value: number;
  resetPeriod: ResetPeriod;
  category: string;
}

export interface CardOffer {
  id: string;
  cardId: string;
  title: string;
  description: string;
  bonusPoints: number;
  bonusCurrency: string;
  spendRequired: number;
  timeframeDays: number;
  expirationDate: string | null;
  isTargeted: boolean;
  source: string;
}

export interface ChurnRule {
  id: string;
  issuer: Issuer;
  ruleType: ChurnRuleType;
  category: ChurnRuleCategory;
  name: string;
  description: string;
  details: string;
  windowMonths?: number;
  maxCards?: number;
  countsAllIssuers?: boolean;
  businessExempt?: boolean;
  requiresNotCurrentlyHolding?: boolean;
  cooldownMonths?: number;
  cooldownStartsFrom?: CooldownStartPoint;
  conflictingProducts?: string[];
  productFamily?: string;
}

export interface TransferPartner {
  id: string;
  name: string;
  type: LoyaltyProgramType;
  alliance: string | null;
  partnerAirlines: string[] | null;
  fromPrograms?: string[];
  transferRatio?: number;
}

export interface TransferRoute {
  id: string;
  fromCurrency: string;
  toPartner: string;
  ratio: number;
  transferTime: TransferTime;
  minimumTransfer: number;
  transferBonus: TransferBonus | null;
}

export interface TransferBonus {
  bonusPercent: number;
  startDate: string;
  endDate: string;
  description: string;
}

export interface PointsCurrency {
  id: string;
  name: string;
  earnedWith: string[];
}

export interface DowngradePath {
  fromCard: string;
  toCards: DowngradeOption[];
}

export interface DowngradeOption {
  cardId: string;
  benefits: string[];
  considerations: string[];
}

export interface HistoricalBonus {
  cardId: string;
  bonusHistory: BonusHistoryEntry[];
  typicalRange: string;
  recommendation: string;
}

export interface BonusHistoryEntry {
  date: string;
  points: number;
  spend: number;
}

// Enums
export type Issuer =
  | 'chase' | 'amex' | 'citi' | 'capitalOne' | 'barclays'
  | 'usBank' | 'wellsFargo' | 'bankOfAmerica' | 'discover';

export type CardNetwork = 'visa' | 'mastercard' | 'amex' | 'discover';

export type SpendCategory =
  | 'dining' | 'travel' | 'groceries' | 'gas' | 'streaming'
  | 'online' | 'drugstores' | 'homeImprovement' | 'entertainment' | 'utilities' | 'other';

export type CapPeriod = 'quarterly' | 'annual' | 'calendarYear' | 'monthly';

export type ResetPeriod = 'annual' | 'calendarYear' | 'quarterly' | 'monthly' | 'none';

export type ChurnRuleType = 'applicationEligibility' | 'bonusEligibility';

export type ChurnRuleCategory =
  | 'velocityLimit' | 'productFamily' | 'bonusCooldown'
  | 'lifetimeLanguage' | 'existingRelationship' | 'maxCards' | 'cooldownPeriod';

export type CooldownStartPoint = 'bonusReceived' | 'cardClosed' | 'cardOpened';

export type LoyaltyProgramType = 'airline' | 'hotel';

export type TransferTime =
  | 'instant' | 'sameDay' | 'oneToTwoDays'
  | 'twoToThreeDays' | 'threeToFiveDays' | 'oneWeekPlus';

// Scraper types
export interface ScrapeResult {
  source: string;
  url: string;
  scrapedAt: string;
  rawContent: string;
  success: boolean;
  error?: string;
}

export interface ParsedData {
  cards?: Partial<CreditCard>[];
  offers?: Partial<CardOffer>[];
  churnRules?: Partial<ChurnRule>[];
  transferBonuses?: Partial<TransferBonus>[];
}
