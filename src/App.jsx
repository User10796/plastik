import React, { useState, useEffect } from 'react';
import Anthropic from '@anthropic-ai/sdk';

// Logo component
function PlastikLogo({ size = 40 }) {
  return (
    <svg viewBox="0 0 200 200" width={size} height={size} style={{ marginRight: '12px' }}>
      <defs>
        <linearGradient id="cardGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" style={{ stopColor: '#f59e0b' }} />
          <stop offset="100%" style={{ stopColor: '#d97706' }} />
        </linearGradient>
      </defs>
      <circle cx="100" cy="100" r="95" fill="#1e293b" stroke="#334155" strokeWidth="2" />
      <rect x="45" y="65" width="90" height="56" rx="6" fill="#475569" transform="rotate(-8, 90, 93)" />
      <rect x="50" y="62" width="90" height="56" rx="6" fill="#64748b" transform="rotate(-4, 95, 90)" />
      <rect x="55" y="60" width="90" height="56" rx="6" fill="url(#cardGrad)" />
      <rect x="65" y="72" width="18" height="14" rx="2" fill="#fbbf24" opacity="0.9" />
      <line x1="65" y1="79" x2="83" y2="79" stroke="#d97706" strokeWidth="1" />
      <line x1="74" y1="72" x2="74" y2="86" stroke="#d97706" strokeWidth="1" />
      <path d="M 60 130 Q 100 145 140 130" stroke="#22c55e" strokeWidth="3" fill="none" strokeLinecap="round" />
      <path d="M 70 142 Q 100 155 130 142" stroke="#3b82f6" strokeWidth="2.5" fill="none" strokeLinecap="round" opacity="0.8" />
      <path d="M 80 152 Q 100 162 120 152" stroke="#f59e0b" strokeWidth="2" fill="none" strokeLinecap="round" opacity="0.6" />
      <circle cx="60" cy="130" r="4" fill="#22c55e" />
      <circle cx="140" cy="130" r="4" fill="#22c55e" />
      <circle cx="100" cy="148" r="3" fill="#3b82f6" />
    </svg>
  );
}

// Utility functions
const formatCurrency = (amount) => {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount);
};

const formatDate = (dateStr) => {
  if (!dateStr) return 'N/A';
  return new Date(dateStr).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
};

const daysUntil = (dateStr) => {
  if (!dateStr) return null;
  const diff = new Date(dateStr) - new Date();
  return Math.ceil(diff / (1000 * 60 * 60 * 24));
};

// Initial card data
const initialCards = [
  {
    id: 1,
    name: 'Delta SkyMiles Platinum',
    issuer: 'Amex',
    holder: 'Sterling',
    annualFee: 350,
    apr: 21.99,
    currentBalance: 0,
    openDate: '2023-01-15',
    anniversaryDate: '2025-01-15',
    signupBonus: { target: 3000, current: 3000, reward: 90000, rewardType: 'Delta Miles', deadline: null, completed: true },
    spendingCaps: [],
    churnEligible: '2027-01-15',
    pointsType: 'Delta SkyMiles',
    notes: 'Companion Certificate annually'
  },
  {
    id: 2,
    name: 'Sapphire Preferred',
    issuer: 'Chase',
    holder: 'Sterling',
    annualFee: 95,
    apr: 22.49,
    currentBalance: 0,
    openDate: '2022-06-01',
    anniversaryDate: '2025-06-01',
    signupBonus: { target: 4000, current: 4000, reward: 60000, rewardType: 'Ultimate Rewards', deadline: null, completed: true },
    spendingCaps: [],
    churnEligible: '2026-06-01',
    pointsType: 'Chase Ultimate Rewards',
    notes: ''
  },
  {
    id: 3,
    name: 'Sapphire Preferred',
    issuer: 'Chase',
    holder: 'Spouse',
    annualFee: 95,
    apr: 22.49,
    currentBalance: 0,
    openDate: '2023-03-15',
    anniversaryDate: '2025-03-15',
    signupBonus: { target: 4000, current: 4000, reward: 60000, rewardType: 'Ultimate Rewards', deadline: null, completed: true },
    spendingCaps: [],
    churnEligible: '2027-03-15',
    pointsType: 'Chase Ultimate Rewards',
    notes: ''
  },
  {
    id: 4,
    name: 'Apple Card',
    issuer: 'Goldman Sachs',
    holder: 'Sterling',
    annualFee: 0,
    apr: 19.24,
    currentBalance: 0,
    openDate: '2020-08-01',
    anniversaryDate: '2025-08-01',
    signupBonus: null,
    spendingCaps: [],
    churnEligible: null,
    pointsType: 'Apple Cash',
    notes: '3% on Apple, 2% Apple Pay, 1% other'
  },
  {
    id: 5,
    name: 'Blue Cash Preferred',
    issuer: 'Amex',
    holder: 'Sterling',
    annualFee: 95,
    apr: 20.49,
    currentBalance: 0,
    openDate: '2021-04-01',
    anniversaryDate: '2025-04-01',
    signupBonus: { target: 3000, current: 3000, reward: 350, rewardType: 'Statement Credit', deadline: null, completed: true },
    spendingCaps: [
      { category: 'Groceries', rate: 6, cap: 6000, currentSpend: 0, resetDate: '2025-04-01' },
      { category: 'Streaming', rate: 6, cap: 6000, currentSpend: 0, resetDate: '2025-04-01' }
    ],
    churnEligible: '2028-04-01',
    pointsType: 'Cash Back',
    notes: '6% groceries up to $6k/yr, 6% streaming, 3% gas'
  },
  {
    id: 6,
    name: 'EveryDay',
    issuer: 'Amex',
    holder: 'Sterling',
    annualFee: 0,
    apr: 18.49,
    currentBalance: 0,
    openDate: '2019-02-01',
    anniversaryDate: '2025-02-01',
    signupBonus: null,
    spendingCaps: [],
    churnEligible: null,
    pointsType: 'Membership Rewards',
    notes: '2x groceries, 20% bonus at 20+ transactions/month'
  },
  {
    id: 7,
    name: 'United Quest',
    issuer: 'Chase',
    holder: 'Sterling',
    annualFee: 250,
    apr: 22.49,
    currentBalance: 0,
    openDate: '2023-09-01',
    anniversaryDate: '2025-09-01',
    signupBonus: { target: 4000, current: 4000, reward: 70000, rewardType: 'United Miles', deadline: null, completed: true },
    spendingCaps: [],
    churnEligible: '2027-09-01',
    pointsType: 'United MileagePlus',
    notes: '2 free checked bags, $125 United credit'
  },
  {
    id: 8,
    name: 'Slate',
    issuer: 'Chase',
    holder: 'Sterling',
    annualFee: 0,
    apr: 21.49,
    currentBalance: 0,
    openDate: '2018-01-01',
    anniversaryDate: '2025-01-01',
    signupBonus: null,
    spendingCaps: [],
    churnEligible: null,
    pointsType: null,
    notes: 'Balance transfer card'
  },
  {
    id: 9,
    name: 'Southwest Rapid Rewards',
    issuer: 'Chase',
    holder: 'Sterling',
    annualFee: 69,
    apr: 21.49,
    currentBalance: 0,
    openDate: '2022-11-01',
    anniversaryDate: '2025-11-01',
    signupBonus: { target: 3000, current: 3000, reward: 50000, rewardType: 'Rapid Rewards', deadline: null, completed: true },
    spendingCaps: [],
    churnEligible: '2026-11-01',
    pointsType: 'Southwest Rapid Rewards',
    notes: ''
  },
  {
    id: 10,
    name: 'Amazon Prime Visa',
    issuer: 'Chase',
    holder: 'Sterling',
    annualFee: 0,
    apr: 20.49,
    currentBalance: 0,
    openDate: '2020-03-01',
    anniversaryDate: '2025-03-01',
    signupBonus: null,
    spendingCaps: [],
    churnEligible: null,
    pointsType: 'Amazon Rewards',
    notes: '5% Amazon/Whole Foods, 2% restaurants/gas/drugstores'
  },
  {
    id: 11,
    name: 'Platinum',
    issuer: 'Bank of America',
    holder: 'Sterling',
    annualFee: 0,
    apr: 23.49,
    currentBalance: 0,
    openDate: '2017-06-01',
    anniversaryDate: '2025-06-01',
    signupBonus: null,
    spendingCaps: [],
    churnEligible: null,
    pointsType: null,
    notes: 'Low APR card'
  }
];

const initialPointsBalances = {
  'Chase Ultimate Rewards': 125000,
  'Southwest Rapid Rewards': 45000,
  'Amazon Rewards': 15000,
  'United MileagePlus': 82000,
  'Delta SkyMiles': 110000,
  'Membership Rewards': 25000,
  'Cash Back': 0,
  'Apple Cash': 0
};

const initialCompanionPasses = [
  { type: 'Southwest Companion Pass', earned: false, expiresDate: null, progress: 45000, target: 135000 },
  { type: 'Delta Companion Certificate', earned: true, expiresDate: '2025-01-15', holder: 'Sterling' }
];

// Application history tracking
const initialApplications = [];

// Credit pull tracking (separate from applications)
const initialCreditPulls = [];

// Issuer velocity rules database
const issuerRules = {
  'Chase': {
    rules: [
      { name: '5/24', description: 'Cannot approve if 5+ cards opened in 24 months (any issuer)', window: 24, limit: 5, scope: 'all_issuers' },
      { name: '1/30', description: 'Only 1 personal card approval per 30 days', window: 1, limit: 1, scope: 'personal', unit: 'months' },
      { name: '2/30 Business', description: 'Max 2 business cards per 30 days', window: 1, limit: 2, scope: 'business', unit: 'months' },
      { name: 'Sapphire 48-month', description: 'No Sapphire bonus if received one in past 48 months', window: 48, scope: 'sapphire_family' },
      { name: 'CL Cap', description: 'Total Chase CL typically capped at 50% of income', scope: 'credit_limit' }
    ],
    pullsBureau: ['Experian', 'Equifax'],
    notes: 'Generally most valuable cards to get first due to 5/24. Can sometimes combine hard pulls same day.'
  },
  'Amex': {
    rules: [
      { name: 'Once Per Lifetime', description: 'Signup bonus only once per card product ever (with some exceptions)', scope: 'bonus' },
      { name: '1/5', description: 'Max 1 credit card per 5 days', window: 5, limit: 1, scope: 'credit', unit: 'days' },
      { name: '2/90', description: 'Max 2 credit cards per 90 days', window: 90, limit: 2, scope: 'credit', unit: 'days' },
      { name: '4-5 Credit Card Limit', description: 'Max 4-5 Amex credit cards at once (charge cards unlimited)', scope: 'total' },
      { name: 'NLL Offers', description: 'No Lifetime Language offers via targeted links bypass once-per-lifetime', scope: 'exception' }
    ],
    pullsBureau: ['Experian'],
    notes: 'Soft pull for existing customers. Business cards don\'t report to personal credit. Watch for NLL offers.'
  },
  'Citi': {
    rules: [
      { name: '1/8', description: 'Only 1 application per 8 days', window: 8, limit: 1, unit: 'days' },
      { name: '2/65', description: 'Max 2 approvals per 65 days', window: 65, limit: 2, unit: 'days' },
      { name: '1/24 Same Family', description: 'No bonus on same card family within 24 months', window: 24, scope: 'family' },
      { name: '6/6', description: 'May deny if 6+ inquiries in 6 months', window: 6, limit: 6, scope: 'inquiries' }
    ],
    pullsBureau: ['Experian', 'Equifax', 'TransUnion'],
    notes: 'Known for matching signup bonuses via SM. AA cards have been churnable historically.'
  },
  'Capital One': {
    rules: [
      { name: '1/6 Months', description: 'Generally 1 card per 6 months', window: 6, limit: 1, unit: 'months' },
      { name: 'Inquiry Sensitive', description: 'May deny with many recent inquiries', scope: 'inquiries' },
      { name: '3 Bureau Pull', description: 'Pulls all 3 bureaus for new customers', scope: 'pull' }
    ],
    pullsBureau: ['Experian', 'Equifax', 'TransUnion'],
    notes: 'All 3 bureau pulls hurt. Venture X has been more lenient. Can PC between Venture cards.'
  },
  'Bank of America': {
    rules: [
      { name: '2/3/4', description: '2 cards per 2 months, 3 per 12 months, 4 per 24 months', scope: 'velocity' },
      { name: '7/12', description: 'Max 7 cards per 12 months across all issuers', window: 12, limit: 7, scope: 'all_issuers' },
      { name: 'Preferred Rewards', description: 'Better bonuses with $100k+ in BoA/Merrill accounts', scope: 'relationship' }
    ],
    pullsBureau: ['Experian'],
    notes: 'Relationship helps a lot. Alaska cards are popular for companion fare.'
  },
  'Barclays': {
    rules: [
      { name: '6/24 Sensitive', description: 'May deny if 6+ cards in 24 months', window: 24, limit: 6, scope: 'all_issuers' },
      { name: '1/6', description: 'One Barclays card per 6 months recommended', window: 6, limit: 1, unit: 'months' }
    ],
    pullsBureau: ['TransUnion'],
    notes: 'AA Aviator is popular. JetBlue cards available. Known for recon success.'
  },
  'US Bank': {
    rules: [
      { name: 'Inquiry Sensitive', description: 'Very sensitive to recent inquiries', scope: 'inquiries' },
      { name: 'Relationship Helps', description: 'Checking account significantly improves approval odds', scope: 'relationship' },
      { name: '0/12 Preference', description: 'Prefers 0-1 new cards in past 12 months', window: 12, limit: 1, scope: 'preference' }
    ],
    pullsBureau: ['TransUnion', 'Experian'],
    notes: 'Altitude Reserve/Connect are valuable. Open checking first if no relationship.'
  },
  'Wells Fargo': {
    rules: [
      { name: '15/12', description: 'May deny with 15+ inquiries in 12 months', window: 12, limit: 15, scope: 'inquiries' },
      { name: 'Cell Phone Protection', description: 'Autograph has cell phone protection benefit', scope: 'benefit' }
    ],
    pullsBureau: ['Experian'],
    notes: 'Autograph is their main rewards card. Not as churnable as others.'
  },
  'Goldman Sachs': {
    rules: [
      { name: 'Apple Ecosystem', description: 'Apple Card is only product currently', scope: 'product' }
    ],
    pullsBureau: ['TransUnion'],
    notes: 'Apple Card - 3% on Apple, 2% Apple Pay. No traditional signup bonus.'
  }
};

// Downgrade paths for preserving credit history
const downgradePaths = {
  'Chase Sapphire Preferred': ['Freedom Unlimited', 'Freedom Flex', 'Freedom'],
  'Chase Sapphire Reserve': ['Freedom Unlimited', 'Freedom Flex', 'Freedom', 'Sapphire Preferred'],
  'Chase United Quest': ['United Gateway (no AF)'],
  'Chase United Explorer': ['United Gateway (no AF)'],
  'Chase Southwest Priority': ['Southwest Plus'],
  'Amex Gold': ['Amex Green (lower AF)', 'None - keep or cancel'],
  'Amex Platinum': ['Amex Gold', 'Amex Green', 'None - keep or cancel'],
  'Amex Blue Cash Preferred': ['Blue Cash Everyday (no AF)'],
  'Amex Delta Platinum': ['Delta Blue (no AF)'],
  'Citi Premier': ['Citi Double Cash', 'Citi Custom Cash'],
  'Capital One Venture X': ['Venture', 'VentureOne'],
  'Capital One Venture': ['VentureOne (no AF)']
};

// Applications Tab Component
function ApplicationsTab({ applications, setApplications, creditPulls, setCreditPulls, cards, issuerRules, apiKey }) {
  const [showAddApp, setShowAddApp] = useState(false);
  const [showAddPull, setShowAddPull] = useState(false);
  const [showImportReport, setShowImportReport] = useState(false);
  const [reportText, setReportText] = useState('');
  const [parsing, setParsing] = useState(false);
  const [parseResult, setParseResult] = useState(null);
  const [selectedIssuer, setSelectedIssuer] = useState(null);
  const [activeSubTab, setActiveSubTab] = useState('applications');

  const addApplication = (app) => {
    const id = Date.now();
    setApplications([...applications, { ...app, id }]);
    setShowAddApp(false);
  };

  const updateApplication = (id, updates) => {
    setApplications(applications.map(a => a.id === id ? { ...a, ...updates } : a));
  };

  const deleteApplication = (id) => {
    if (confirm('Delete this application?')) {
      setApplications(applications.filter(a => a.id !== id));
    }
  };

  const addCreditPull = (pull) => {
    const id = Date.now();
    setCreditPulls([...creditPulls, { ...pull, id }]);
    setShowAddPull(false);
  };

  const deleteCreditPull = (id) => {
    if (confirm('Delete this inquiry?')) {
      setCreditPulls(creditPulls.filter(p => p.id !== id));
    }
  };

  // Parse credit report with Claude API
  const parseReport = async () => {
    if (!apiKey || !reportText) return;
    setParsing(true);
    setParseResult(null);

    try {
      const response = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'anthropic-dangerous-direct-browser-access': 'true'
        },
        body: JSON.stringify({
          model: 'claude-sonnet-4-20250514',
          max_tokens: 8000,
          messages: [{
            role: 'user',
            content: `Parse this credit report text and extract all HARD INQUIRIES (not soft inquiries). Return JSON:

{
  "bureau": "Experian" | "Equifax" | "TransUnion",
  "inquiries": [
    {
      "creditor": "string - company name",
      "date": "YYYY-MM-DD",
      "type": "string - credit card, auto loan, mortgage, personal loan, other"
    }
  ]
}

Credit report text:
${reportText}

Return ONLY valid JSON, no other text. Only include hard inquiries, not soft/promotional inquiries.`
          }]
        })
      });

      const data = await response.json();

      if (data.error) {
        setParseResult({ error: data.error.message || 'API error', raw: JSON.stringify(data.error, null, 2) });
        setParsing(false);
        return;
      }

      let content = data.content?.[0]?.text || '';
      content = content.replace(/^```(?:json)?\s*\n?/i, '').replace(/\n?```\s*$/i, '').trim();

      try {
        const parsed = JSON.parse(content);
        setParseResult(parsed);
      } catch {
        let braceCount = 0, startIdx = -1, endIdx = -1;
        for (let i = 0; i < content.length; i++) {
          if (content[i] === '{') { if (startIdx === -1) startIdx = i; braceCount++; }
          else if (content[i] === '}') { braceCount--; if (braceCount === 0 && startIdx !== -1) { endIdx = i; break; } }
        }
        if (startIdx !== -1 && endIdx !== -1) {
          const parsed = JSON.parse(content.substring(startIdx, endIdx + 1));
          setParseResult(parsed);
        } else {
          setParseResult({ error: 'Could not parse response', raw: content });
        }
      }
    } catch (error) {
      setParseResult({ error: error.message });
    }
    setParsing(false);
  };

  const applyReportResult = () => {
    if (!parseResult || parseResult.error) return;

    const newPulls = parseResult.inquiries.map((inq, idx) => ({
      id: Date.now() + idx,
      bureau: parseResult.bureau,
      creditor: inq.creditor,
      date: inq.date,
      type: inq.type,
      source: 'credit_report'
    }));

    // Deduplicate - don't add if same creditor + date + bureau already exists
    const existingKeys = new Set(creditPulls.map(p => `${p.bureau}-${p.date}-${p.creditor}`));
    const uniqueNewPulls = newPulls.filter(p => !existingKeys.has(`${p.bureau}-${p.date}-${p.creditor}`));

    setCreditPulls([...creditPulls, ...uniqueNewPulls]);
    setShowImportReport(false);
    setReportText('');
    setParseResult(null);
  };

  // Calculate velocity status for each issuer (uses applications, not pulls)
  const getIssuerVelocityStatus = (issuer) => {
    const rules = issuerRules[issuer];
    if (!rules) return null;

    const issuerApps = applications.filter(a => a.issuer === issuer && a.status === 'Approved');
    const allApps = applications.filter(a => a.status === 'Approved');
    
    const now = new Date();
    const warnings = [];
    const blockers = [];

    rules.rules.forEach(rule => {
      let relevantApps = rule.scope === 'all_issuers' ? allApps : issuerApps;
      
      if (rule.window && rule.limit !== undefined) {
        const windowMs = rule.unit === 'days' 
          ? rule.window * 24 * 60 * 60 * 1000 
          : rule.window * 30 * 24 * 60 * 60 * 1000;
        const cutoff = new Date(now - windowMs);
        const count = relevantApps.filter(a => new Date(a.applicationDate) > cutoff).length;
        
        if (count >= rule.limit) {
          blockers.push({ rule: rule.name, count, limit: rule.limit, description: rule.description });
        } else if (count >= rule.limit - 1) {
          warnings.push({ rule: rule.name, count, limit: rule.limit, description: rule.description });
        }
      }
    });

    return { warnings, blockers, rules: rules.rules, pullsBureau: rules.pullsBureau, notes: rules.notes };
  };

  // Calculate hard pulls by bureau from creditPulls data
  const now = new Date();
  const sixMonthsAgo = new Date(now - 6 * 30 * 24 * 60 * 60 * 1000);
  const twelveMonthsAgo = new Date(now - 12 * 30 * 24 * 60 * 60 * 1000);
  const twentyFourMonthsAgo = new Date(now - 24 * 30 * 24 * 60 * 60 * 1000);

  const pullsByBureau = {
    Experian: creditPulls.filter(p => p.bureau === 'Experian'),
    Equifax: creditPulls.filter(p => p.bureau === 'Equifax'),
    TransUnion: creditPulls.filter(p => p.bureau === 'TransUnion')
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <h2 style={{ fontSize: '1.5rem', fontWeight: 600, color: '#f1f5f9', margin: 0 }}>Applications & Credit</h2>
      </div>

      {/* Sub-navigation */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '24px' }}>
        {[
          { id: 'applications', label: 'Applications' },
          { id: 'pulls', label: 'Hard Inquiries' },
          { id: 'velocity', label: 'Issuer Rules' }
        ].map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveSubTab(tab.id)}
            style={{
              padding: '10px 20px',
              border: 'none',
              borderRadius: '8px',
              background: activeSubTab === tab.id ? '#f59e0b' : '#334155',
              color: activeSubTab === tab.id ? '#0f172a' : '#e2e8f0',
              fontWeight: 600,
              cursor: 'pointer',
              transition: 'all 0.2s',
              fontFamily: 'inherit'
            }}
          >
            {tab.label}
            {tab.id === 'pulls' && creditPulls.length > 0 && (
              <span style={{ 
                marginLeft: '8px', 
                background: activeSubTab === tab.id ? '#0f172a' : '#f59e0b',
                color: activeSubTab === tab.id ? '#f59e0b' : '#0f172a',
                padding: '2px 8px',
                borderRadius: '10px',
                fontSize: '0.75rem'
              }}>
                {creditPulls.length}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Applications Sub-tab */}
      {activeSubTab === 'applications' && (
        <div>
          <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '16px' }}>
            <button className="btn-primary" onClick={() => setShowAddApp(true)}>+ Log Application</button>
          </div>

          {applications.length === 0 ? (
            <div style={{
              background: '#1e293b',
              borderRadius: '12px',
              padding: '32px',
              textAlign: 'center',
              border: '1px solid #334155'
            }}>
              <div style={{ color: '#64748b', marginBottom: '8px' }}>No applications logged yet</div>
              <div style={{ color: '#94a3b8', fontSize: '0.85rem' }}>
                Click "Log Application" to track your card applications
              </div>
            </div>
          ) : (
            <div style={{ display: 'grid', gap: '12px' }}>
              {applications.sort((a, b) => new Date(b.applicationDate) - new Date(a.applicationDate)).map(app => (
                <div key={app.id} style={{
                  background: '#1e293b',
                  borderRadius: '12px',
                  padding: '20px',
                  border: '1px solid #334155'
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                        <h4 style={{ margin: 0, color: '#f1f5f9' }}>{app.issuer} {app.cardName}</h4>
                        <span style={{
                          padding: '4px 10px',
                          borderRadius: '12px',
                          fontSize: '0.75rem',
                          fontWeight: 600,
                          background: app.status === 'Approved' ? '#166534' : 
                                     app.status === 'Denied' ? '#7f1d1d' : 
                                     app.status === 'Pending' ? '#7c2d12' : '#334155',
                          color: app.status === 'Approved' ? '#86efac' : 
                                app.status === 'Denied' ? '#fca5a5' : 
                                app.status === 'Pending' ? '#fdba74' : '#94a3b8'
                        }}>
                          {app.status}
                        </span>
                        <span style={{
                          padding: '2px 8px',
                          borderRadius: '8px',
                          fontSize: '0.7rem',
                          background: getHolderColor(app.holder).bg,
                          color: getHolderColor(app.holder).text
                        }}>
                          {app.holder}
                        </span>
                      </div>
                      <div style={{ color: '#64748b', fontSize: '0.85rem', marginTop: '8px' }}>
                        Applied: {formatDate(app.applicationDate)}
                        {app.approvalDate && ` • Approved: ${formatDate(app.approvalDate)}`}
                      </div>
                    </div>
                    <div style={{ display: 'flex', gap: '8px' }}>
                      <select
                        className="input-field"
                        style={{ padding: '6px 12px', fontSize: '0.8rem', width: 'auto' }}
                        value={app.status}
                        onChange={(e) => updateApplication(app.id, { 
                          status: e.target.value,
                          approvalDate: e.target.value === 'Approved' ? new Date().toISOString().split('T')[0] : app.approvalDate
                        })}
                      >
                        <option>Pending</option>
                        <option>Approved</option>
                        <option>Denied</option>
                        <option>Cancelled</option>
                      </select>
                      <button 
                        className="btn-secondary"
                        style={{ padding: '6px 12px', fontSize: '0.8rem' }}
                        onClick={() => deleteApplication(app.id)}
                      >
                        ✕
                      </button>
                    </div>
                  </div>
                  
                  {app.status === 'Approved' && (
                    <div style={{ 
                      display: 'grid', 
                      gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', 
                      gap: '16px',
                      marginTop: '16px',
                      paddingTop: '16px',
                      borderTop: '1px solid #334155'
                    }}>
                      <div>
                        <div style={{ color: '#64748b', fontSize: '0.75rem' }}>Credit Limit</div>
                        <input
                          type="number"
                          className="input-field"
                          style={{ padding: '6px 10px', fontSize: '0.9rem', marginTop: '4px' }}
                          placeholder="$0"
                          value={app.creditLimit || ''}
                          onChange={(e) => updateApplication(app.id, { creditLimit: parseFloat(e.target.value) || 0 })}
                        />
                      </div>
                      <div>
                        <div style={{ color: '#64748b', fontSize: '0.75rem' }}>Signup Bonus</div>
                        <div style={{ color: '#f59e0b', fontWeight: 600, marginTop: '8px' }}>
                          {app.signupBonus?.toLocaleString() || '—'} pts
                        </div>
                      </div>
                      <div>
                        <div style={{ color: '#64748b', fontSize: '0.75rem' }}>Bonus Deadline</div>
                        <div style={{ color: '#e2e8f0', marginTop: '8px' }}>
                          {app.bonusDeadline ? formatDate(app.bonusDeadline) : '—'}
                        </div>
                      </div>
                    </div>
                  )}

                  {app.notes && (
                    <div style={{ marginTop: '12px', color: '#94a3b8', fontSize: '0.85rem' }}>
                      📝 {app.notes}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Hard Inquiries Sub-tab */}
      {activeSubTab === 'pulls' && (
        <div>
          {/* Info Banner */}
          <div style={{
            background: '#1e3a5f',
            border: '1px solid #3b82f6',
            borderRadius: '12px',
            padding: '16px 20px',
            marginBottom: '24px'
          }}>
            <div style={{ color: '#93c5fd', fontWeight: 600, marginBottom: '8px' }}>📊 Optional: Track Hard Inquiries</div>
            <div style={{ color: '#bfdbfe', fontSize: '0.9rem' }}>
              Import inquiries from your credit reports (Credit Karma, Experian, etc.) or add them manually. 
              This helps track inquiry-sensitive issuers like Capital One and US Bank.
            </div>
          </div>

          {/* Action Buttons */}
          <div style={{ display: 'flex', gap: '12px', marginBottom: '24px' }}>
            <button className="btn-primary" onClick={() => setShowImportReport(true)}>
              📄 Import from Credit Report
            </button>
            <button className="btn-secondary" onClick={() => setShowAddPull(true)}>
              + Add Manually
            </button>
          </div>

          {/* Summary by Bureau */}
          {creditPulls.length > 0 && (
            <div style={{ 
              display: 'grid', 
              gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', 
              gap: '16px', 
              marginBottom: '24px' 
            }}>
              {['Experian', 'Equifax', 'TransUnion'].map(bureau => {
                const pulls = pullsByBureau[bureau] || [];
                const last6 = pulls.filter(p => new Date(p.date) > sixMonthsAgo).length;
                const last12 = pulls.filter(p => new Date(p.date) > twelveMonthsAgo).length;
                const last24 = pulls.filter(p => new Date(p.date) > twentyFourMonthsAgo).length;
                
                return (
                  <div key={bureau} className="card-hover" style={{
                    background: '#1e293b',
                    borderRadius: '12px',
                    padding: '20px',
                    border: '1px solid #334155',
                    transition: 'all 0.3s'
                  }}>
                    <div style={{ color: '#94a3b8', fontSize: '0.85rem', marginBottom: '8px' }}>{bureau}</div>
                    <div style={{ fontSize: '2rem', fontWeight: 700, color: last12 > 6 ? '#ef4444' : '#f59e0b' }}>{last12}</div>
                    <div style={{ color: '#64748b', fontSize: '0.8rem' }}>inquiries (12mo)</div>
                    <div style={{ marginTop: '12px', display: 'flex', gap: '16px', fontSize: '0.8rem' }}>
                      <span style={{ color: '#94a3b8' }}>6mo: <span style={{ color: '#e2e8f0' }}>{last6}</span></span>
                      <span style={{ color: '#94a3b8' }}>24mo: <span style={{ color: '#e2e8f0' }}>{last24}</span></span>
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          {/* Inquiry List */}
          {creditPulls.length === 0 ? (
            <div style={{
              background: '#1e293b',
              borderRadius: '12px',
              padding: '32px',
              textAlign: 'center',
              border: '1px solid #334155'
            }}>
              <div style={{ color: '#64748b', marginBottom: '8px' }}>No inquiries tracked yet</div>
              <div style={{ color: '#94a3b8', fontSize: '0.85rem' }}>
                Import from a credit report or add manually to start tracking
              </div>
            </div>
          ) : (
            <div>
              <h3 style={{ color: '#f1f5f9', marginBottom: '16px' }}>All Inquiries</h3>
              <div style={{ display: 'grid', gap: '8px' }}>
                {creditPulls.sort((a, b) => new Date(b.date) - new Date(a.date)).map(pull => {
                  const pullDate = new Date(pull.date);
                  const isOld = pullDate < twentyFourMonthsAgo;
                  
                  return (
                    <div key={pull.id} style={{
                      background: '#1e293b',
                      borderRadius: '8px',
                      padding: '12px 16px',
                      border: '1px solid #334155',
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      opacity: isOld ? 0.5 : 1
                    }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                        <span style={{
                          padding: '4px 10px',
                          borderRadius: '6px',
                          fontSize: '0.75rem',
                          fontWeight: 600,
                          background: pull.bureau === 'Experian' ? '#1e3a5f' : 
                                     pull.bureau === 'Equifax' ? '#3f1f5f' : '#1f3f2f',
                          color: pull.bureau === 'Experian' ? '#60a5fa' : 
                                pull.bureau === 'Equifax' ? '#c084fc' : '#86efac'
                        }}>
                          {pull.bureau}
                        </span>
                        <div>
                          <div style={{ fontWeight: 500, color: '#f1f5f9' }}>{pull.creditor}</div>
                          <div style={{ color: '#64748b', fontSize: '0.8rem' }}>{pull.type}</div>
                        </div>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                        <div style={{ textAlign: 'right' }}>
                          <div style={{ color: '#e2e8f0' }}>{formatDate(pull.date)}</div>
                          <div style={{ color: '#64748b', fontSize: '0.8rem' }}>
                            {isOld ? 'Falls off soon' : `${Math.ceil((new Date() - pullDate) / (1000 * 60 * 60 * 24))} days ago`}
                          </div>
                        </div>
                        <button
                          onClick={() => deleteCreditPull(pull.id)}
                          style={{
                            background: 'transparent',
                            border: 'none',
                            color: '#64748b',
                            cursor: 'pointer',
                            padding: '4px 8px',
                            fontSize: '1rem'
                          }}
                        >
                          ✕
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      )}

      {/* Issuer Velocity Rules Sub-tab */}
      {activeSubTab === 'velocity' && (
        <div>
          <div style={{ 
            background: '#1e293b', 
            borderRadius: '12px', 
            padding: '16px 20px', 
            marginBottom: '24px',
            border: '1px solid #334155'
          }}>
            <div style={{ color: '#94a3b8', fontSize: '0.9rem' }}>
              Click any issuer to see their application rules and your current status.
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '12px' }}>
            {Object.keys(issuerRules).map(issuer => {
              const status = getIssuerVelocityStatus(issuer);
              const hasBlockers = status?.blockers?.length > 0;
              const hasWarnings = status?.warnings?.length > 0;
              
              return (
                <div 
                  key={issuer}
                  onClick={() => setSelectedIssuer(selectedIssuer === issuer ? null : issuer)}
                  style={{
                    background: '#1e293b',
                    borderRadius: '12px',
                    padding: '16px',
                    border: hasBlockers ? '2px solid #ef4444' : hasWarnings ? '2px solid #f59e0b' : '1px solid #334155',
                    cursor: 'pointer',
                    transition: 'all 0.2s'
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div style={{ fontWeight: 600, color: '#f1f5f9' }}>{issuer}</div>
                    <div style={{
                      padding: '4px 10px',
                      borderRadius: '12px',
                      fontSize: '0.75rem',
                      fontWeight: 600,
                      background: hasBlockers ? '#7f1d1d' : hasWarnings ? '#7c2d12' : '#166534',
                      color: hasBlockers ? '#fca5a5' : hasWarnings ? '#fdba74' : '#86efac'
                    }}>
                      {hasBlockers ? 'BLOCKED' : hasWarnings ? 'CAUTION' : 'CLEAR'}
                    </div>
                  </div>
                  <div style={{ color: '#64748b', fontSize: '0.8rem', marginTop: '8px' }}>
                    Typically pulls: {status?.pullsBureau?.join(', ')}
                  </div>
                  
                  {selectedIssuer === issuer && (
                    <div style={{ marginTop: '16px', paddingTop: '16px', borderTop: '1px solid #334155' }}>
                      {status?.blockers?.map((b, i) => (
                        <div key={i} style={{ 
                          color: '#fca5a5', 
                          fontSize: '0.85rem', 
                          marginBottom: '8px',
                          padding: '8px',
                          background: '#7f1d1d',
                          borderRadius: '6px'
                        }}>
                          ⛔ <strong>{b.rule}</strong>: {b.count}/{b.limit} - {b.description}
                        </div>
                      ))}
                      {status?.warnings?.map((w, i) => (
                        <div key={i} style={{ 
                          color: '#fdba74', 
                          fontSize: '0.85rem', 
                          marginBottom: '8px',
                          padding: '8px',
                          background: '#7c2d12',
                          borderRadius: '6px'
                        }}>
                          ⚠️ <strong>{w.rule}</strong>: {w.count}/{w.limit} - {w.description}
                        </div>
                      ))}
                      <div style={{ marginTop: '12px' }}>
                        {status?.rules?.map((rule, i) => (
                          <div key={i} style={{ color: '#94a3b8', fontSize: '0.8rem', marginBottom: '4px' }}>
                            • <strong>{rule.name}</strong>: {rule.description}
                          </div>
                        ))}
                      </div>
                      {status?.notes && (
                        <div style={{ 
                          marginTop: '12px', 
                          padding: '8px', 
                          background: '#0f172a', 
                          borderRadius: '6px',
                          color: '#94a3b8',
                          fontSize: '0.8rem'
                        }}>
                          💡 {status.notes}
                        </div>
                      )}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Add Application Modal */}
      {showAddApp && (
        <div className="modal-overlay" onClick={() => setShowAddApp(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: '500px' }}>
            <h3 style={{ margin: '0 0 20px', color: '#f1f5f9' }}>Log New Application</h3>
            <form onSubmit={(e) => {
              e.preventDefault();
              const form = e.target;
              addApplication({
                cardName: form.cardName.value,
                issuer: form.issuer.value,
                holder: form.holder.value,
                applicationDate: form.applicationDate.value,
                status: form.status.value,
                signupBonus: parseFloat(form.signupBonus.value) || 0,
                signupSpend: parseFloat(form.signupSpend.value) || 0,
                bonusDeadline: form.bonusDeadline.value || null,
                notes: form.notes.value
              });
            }}>
              <div style={{ display: 'grid', gap: '16px' }}>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Card Name *</label>
                    <input name="cardName" required className="input-field" placeholder="Sapphire Preferred" />
                  </div>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Issuer *</label>
                    <select name="issuer" required className="input-field">
                      {Object.keys(issuerRules).map(issuer => (
                        <option key={issuer} value={issuer}>{issuer}</option>
                      ))}
                    </select>
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px' }}>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Holder</label>
                    <select name="holder" className="input-field">
                      {holders.map(h => <option key={h} value={h}>{h}</option>)}
                    </select>
                  </div>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>App Date *</label>
                    <input name="applicationDate" type="date" required className="input-field" defaultValue={new Date().toISOString().split('T')[0]} />
                  </div>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Status</label>
                    <select name="status" className="input-field">
                      <option>Pending</option>
                      <option>Approved</option>
                      <option>Denied</option>
                    </select>
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px' }}>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Signup Bonus</label>
                    <input name="signupBonus" type="number" className="input-field" placeholder="60000" />
                  </div>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Spend Required</label>
                    <input name="signupSpend" type="number" className="input-field" placeholder="4000" />
                  </div>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Bonus Deadline</label>
                    <input name="bonusDeadline" type="date" className="input-field" />
                  </div>
                </div>

                <div>
                  <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Notes</label>
                  <textarea name="notes" className="input-field" style={{ minHeight: '60px' }} placeholder="Referral used, instant approval, etc." />
                </div>
              </div>

              <div style={{ display: 'flex', gap: '12px', marginTop: '24px' }}>
                <button type="submit" className="btn-primary">Log Application</button>
                <button type="button" className="btn-secondary" onClick={() => setShowAddApp(false)}>Cancel</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Add Manual Pull Modal */}
      {showAddPull && (
        <div className="modal-overlay" onClick={() => setShowAddPull(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()}>
            <h3 style={{ margin: '0 0 20px', color: '#f1f5f9' }}>Add Hard Inquiry</h3>
            <form onSubmit={(e) => {
              e.preventDefault();
              const form = e.target;
              addCreditPull({
                bureau: form.bureau.value,
                creditor: form.creditor.value,
                date: form.date.value,
                type: form.type.value,
                source: 'manual'
              });
            }}>
              <div style={{ display: 'grid', gap: '16px' }}>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Bureau *</label>
                    <select name="bureau" required className="input-field">
                      <option value="Experian">Experian</option>
                      <option value="Equifax">Equifax</option>
                      <option value="TransUnion">TransUnion</option>
                    </select>
                  </div>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Date *</label>
                    <input name="date" type="date" required className="input-field" />
                  </div>
                </div>
                <div>
                  <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Creditor *</label>
                  <input name="creditor" required className="input-field" placeholder="Chase Bank, Capital One, etc." />
                </div>
                <div>
                  <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Type</label>
                  <select name="type" className="input-field">
                    <option value="Credit Card">Credit Card</option>
                    <option value="Auto Loan">Auto Loan</option>
                    <option value="Mortgage">Mortgage</option>
                    <option value="Personal Loan">Personal Loan</option>
                    <option value="Other">Other</option>
                  </select>
                </div>
              </div>

              <div style={{ display: 'flex', gap: '12px', marginTop: '24px' }}>
                <button type="submit" className="btn-primary">Add Inquiry</button>
                <button type="button" className="btn-secondary" onClick={() => setShowAddPull(false)}>Cancel</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Import Credit Report Modal */}
      {showImportReport && (
        <div className="modal-overlay" onClick={() => { setShowImportReport(false); setParseResult(null); }}>
          <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: '600px' }}>
            <h3 style={{ margin: '0 0 8px', color: '#f1f5f9' }}>Import from Credit Report</h3>
            <p style={{ color: '#94a3b8', fontSize: '0.9rem', marginBottom: '20px' }}>
              Copy the Hard Inquiries section from your credit report (Credit Karma, Experian, etc.) and paste below.
            </p>

            {!apiKey ? (
              <div style={{
                background: '#7c2d12',
                border: '1px solid #f59e0b',
                borderRadius: '8px',
                padding: '16px',
                marginBottom: '16px'
              }}>
                <div style={{ color: '#fbbf24', fontWeight: 600 }}>API Key Required</div>
                <div style={{ color: '#fed7aa', fontSize: '0.85rem', marginTop: '4px' }}>
                  Set your Anthropic API key in the header to use this feature.
                </div>
              </div>
            ) : (
              <>
                <textarea
                  className="input-field"
                  style={{ minHeight: '200px', fontFamily: 'monospace', fontSize: '0.85rem' }}
                  placeholder="Paste your credit report's Hard Inquiries section here...

Example:
HARD INQUIRIES
CHASE CARD SERVICES - Jan 15, 2025
CAPITAL ONE - Dec 3, 2024
AMERICAN EXPRESS - Nov 20, 2024"
                  value={reportText}
                  onChange={(e) => setReportText(e.target.value)}
                />

                <div style={{ marginTop: '12px', marginBottom: '16px' }}>
                  <label style={{ color: '#94a3b8', fontSize: '0.85rem', marginRight: '12px' }}>Bureau:</label>
                  <select id="reportBureau" className="input-field" style={{ width: 'auto', display: 'inline-block' }}>
                    <option value="Experian">Experian</option>
                    <option value="Equifax">Equifax</option>
                    <option value="TransUnion">TransUnion</option>
                  </select>
                </div>

                {parseResult && !parseResult.error && (
                  <div style={{
                    background: '#166534',
                    border: '1px solid #22c55e',
                    borderRadius: '8px',
                    padding: '16px',
                    marginBottom: '16px'
                  }}>
                    <div style={{ color: '#86efac', fontWeight: 600, marginBottom: '12px' }}>
                      ✓ Found {parseResult.inquiries?.length || 0} inquiries
                    </div>
                    <div style={{ maxHeight: '150px', overflowY: 'auto' }}>
                      {parseResult.inquiries?.map((inq, i) => (
                        <div key={i} style={{ color: '#bbf7d0', fontSize: '0.85rem', marginBottom: '4px' }}>
                          • {inq.creditor} - {formatDate(inq.date)}
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {parseResult?.error && (
                  <div style={{
                    background: '#7f1d1d',
                    border: '1px solid #ef4444',
                    borderRadius: '8px',
                    padding: '16px',
                    marginBottom: '16px'
                  }}>
                    <div style={{ color: '#fca5a5' }}>Error: {parseResult.error}</div>
                  </div>
                )}
              </>
            )}

            <div style={{ display: 'flex', gap: '12px' }}>
              {!parseResult ? (
                <button 
                  className="btn-primary" 
                  onClick={parseReport}
                  disabled={!apiKey || !reportText || parsing}
                  style={{ opacity: (!apiKey || !reportText || parsing) ? 0.5 : 1 }}
                >
                  {parsing ? 'Parsing...' : 'Parse Report'}
                </button>
              ) : !parseResult.error ? (
                <button className="btn-primary" onClick={applyReportResult}>
                  Import {parseResult.inquiries?.length || 0} Inquiries
                </button>
              ) : null}
              <button 
                className="btn-secondary" 
                onClick={() => { setShowImportReport(false); setParseResult(null); setReportText(''); }}
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// Annual Fees Tab Component
function AnnualFeesTab({ cards, setCards, downgradePaths }) {
  const [retentionOffers, setRetentionOffers] = useState({});

  const cardsWithFees = cards
    .filter(c => c.annualFee > 0)
    .map(card => ({
      ...card,
      daysUntilFee: daysUntil(card.anniversaryDate),
      downgradeOptions: downgradePaths[`${card.issuer} ${card.name}`] || []
    }))
    .sort((a, b) => a.daysUntilFee - b.daysUntilFee);

  const upcomingFees = cardsWithFees.filter(c => c.daysUntilFee <= 90 && c.daysUntilFee > 0);
  const totalAnnualFees = cards.reduce((sum, c) => sum + (c.annualFee || 0), 0);

  const updateRetentionOffer = (cardId, offer) => {
    setRetentionOffers(prev => ({ ...prev, [cardId]: offer }));
  };

  return (
    <div>
      <h2 style={{ fontSize: '1.5rem', fontWeight: 600, color: '#f1f5f9', marginBottom: '24px' }}>Annual Fee Calendar</h2>

      {/* Summary */}
      <div style={{ 
        display: 'grid', 
        gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', 
        gap: '16px', 
        marginBottom: '32px' 
      }}>
        <div className="card-hover" style={{
          background: '#1e293b',
          borderRadius: '12px',
          padding: '24px',
          border: '1px solid #334155',
          transition: 'all 0.3s'
        }}>
          <div style={{ color: '#94a3b8', fontSize: '0.9rem', marginBottom: '8px' }}>Total Annual Fees</div>
          <div style={{ fontSize: '2.5rem', fontWeight: 700, color: '#f59e0b' }}>{formatCurrency(totalAnnualFees)}</div>
          <div style={{ color: '#64748b', fontSize: '0.85rem', marginTop: '8px' }}>
            Across {cardsWithFees.length} cards
          </div>
        </div>

        <div className="card-hover" style={{
          background: upcomingFees.length > 0 ? '#7c2d12' : '#1e293b',
          borderRadius: '12px',
          padding: '24px',
          border: upcomingFees.length > 0 ? '2px solid #f59e0b' : '1px solid #334155',
          transition: 'all 0.3s'
        }}>
          <div style={{ color: '#94a3b8', fontSize: '0.9rem', marginBottom: '8px' }}>Fees Due in 90 Days</div>
          <div style={{ fontSize: '2.5rem', fontWeight: 700, color: upcomingFees.length > 0 ? '#fbbf24' : '#22c55e' }}>
            {formatCurrency(upcomingFees.reduce((sum, c) => sum + c.annualFee, 0))}
          </div>
          <div style={{ color: '#64748b', fontSize: '0.85rem', marginTop: '8px' }}>
            {upcomingFees.length} card{upcomingFees.length !== 1 ? 's' : ''} upcoming
          </div>
        </div>

        <div className="card-hover" style={{
          background: '#1e293b',
          borderRadius: '12px',
          padding: '24px',
          border: '1px solid #334155',
          transition: 'all 0.3s'
        }}>
          <div style={{ color: '#94a3b8', fontSize: '0.9rem', marginBottom: '8px' }}>No-Fee Cards</div>
          <div style={{ fontSize: '2.5rem', fontWeight: 700, color: '#22c55e' }}>
            {cards.filter(c => c.annualFee === 0).length}
          </div>
          <div style={{ color: '#64748b', fontSize: '0.85rem', marginTop: '8px' }}>
            Keep indefinitely for credit history
          </div>
        </div>
      </div>

      {/* Upcoming Fees Alert */}
      {upcomingFees.length > 0 && (
        <div style={{ marginBottom: '32px' }}>
          <h3 style={{ color: '#f59e0b', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            ⚠️ Action Required - Fees Due Soon
          </h3>
          <div style={{ display: 'grid', gap: '12px' }}>
            {upcomingFees.map(card => (
              <div key={card.id} style={{
                background: '#1e293b',
                borderRadius: '12px',
                padding: '20px',
                border: '2px solid #f59e0b'
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', marginBottom: '16px' }}>
                  <div>
                    <h4 style={{ margin: 0, color: '#f1f5f9' }}>{card.issuer} {card.name}</h4>
                    <div style={{ color: '#64748b', fontSize: '0.85rem', marginTop: '4px' }}>
                      {card.holder} • Fee due {formatDate(card.anniversaryDate)}
                    </div>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: '1.5rem', fontWeight: 700, color: '#f59e0b' }}>
                      {formatCurrency(card.annualFee)}
                    </div>
                    <div style={{ 
                      color: card.daysUntilFee <= 30 ? '#ef4444' : '#f59e0b',
                      fontSize: '0.85rem',
                      fontWeight: 600
                    }}>
                      {card.daysUntilFee} days
                    </div>
                  </div>
                </div>

                {/* Decision Options */}
                <div style={{ 
                  display: 'grid', 
                  gridTemplateColumns: 'repeat(3, 1fr)', 
                  gap: '12px',
                  marginBottom: '16px'
                }}>
                  <button 
                    className="btn-secondary"
                    style={{ 
                      background: card.feeDecision === 'keep' ? '#166534' : '#334155',
                      borderColor: card.feeDecision === 'keep' ? '#22c55e' : '#475569'
                    }}
                    onClick={() => {
                      const updated = { ...card, feeDecision: 'keep' };
                      setCards(cards.map(c => c.id === card.id ? updated : c));
                    }}
                  >
                    ✓ Keep
                  </button>
                  <button 
                    className="btn-secondary"
                    style={{ 
                      background: card.feeDecision === 'downgrade' ? '#1e3a8a' : '#334155',
                      borderColor: card.feeDecision === 'downgrade' ? '#3b82f6' : '#475569'
                    }}
                    onClick={() => {
                      const updated = { ...card, feeDecision: 'downgrade' };
                      setCards(cards.map(c => c.id === card.id ? updated : c));
                    }}
                  >
                    ↓ Downgrade
                  </button>
                  <button 
                    className="btn-secondary"
                    style={{ 
                      background: card.feeDecision === 'cancel' ? '#7f1d1d' : '#334155',
                      borderColor: card.feeDecision === 'cancel' ? '#ef4444' : '#475569'
                    }}
                    onClick={() => {
                      const updated = { ...card, feeDecision: 'cancel' };
                      setCards(cards.map(c => c.id === card.id ? updated : c));
                    }}
                  >
                    ✕ Cancel
                  </button>
                </div>

                {/* Downgrade Options */}
                {card.downgradeOptions.length > 0 && (
                  <div style={{ 
                    padding: '12px', 
                    background: '#0f172a', 
                    borderRadius: '8px',
                    marginBottom: '12px'
                  }}>
                    <div style={{ color: '#64748b', fontSize: '0.8rem', marginBottom: '8px' }}>Downgrade options:</div>
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                      {card.downgradeOptions.map((opt, i) => (
                        <span key={i} style={{
                          padding: '4px 10px',
                          background: '#334155',
                          borderRadius: '6px',
                          color: '#e2e8f0',
                          fontSize: '0.8rem'
                        }}>
                          {opt}
                        </span>
                      ))}
                    </div>
                  </div>
                )}

                {/* Retention Offer Tracking */}
                <div style={{ padding: '12px', background: '#0f172a', borderRadius: '8px' }}>
                  <div style={{ color: '#64748b', fontSize: '0.8rem', marginBottom: '8px' }}>Retention offer (call and ask!):</div>
                  <div style={{ display: 'flex', gap: '8px' }}>
                    <input
                      className="input-field"
                      style={{ flex: 1, padding: '8px 12px', fontSize: '0.85rem' }}
                      placeholder="e.g., $150 statement credit, 20k points..."
                      value={retentionOffers[card.id] || card.retentionOffer || ''}
                      onChange={(e) => updateRetentionOffer(card.id, e.target.value)}
                    />
                    <button 
                      className="btn-primary"
                      style={{ padding: '8px 16px', fontSize: '0.85rem' }}
                      onClick={() => {
                        const updated = { ...card, retentionOffer: retentionOffers[card.id] };
                        setCards(cards.map(c => c.id === card.id ? updated : c));
                      }}
                    >
                      Save
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Full Year Calendar */}
      <h3 style={{ color: '#f1f5f9', marginBottom: '16px' }}>Full Year Fee Calendar</h3>
      <div style={{ display: 'grid', gap: '8px' }}>
        {cardsWithFees.map(card => {
          const isPast = card.daysUntilFee < 0;
          const isUrgent = card.daysUntilFee <= 30 && card.daysUntilFee > 0;
          const isUpcoming = card.daysUntilFee <= 90 && card.daysUntilFee > 30;
          
          return (
            <div key={card.id} style={{
              background: '#1e293b',
              borderRadius: '8px',
              padding: '16px',
              border: '1px solid #334155',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              opacity: isPast ? 0.5 : 1
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                <div style={{
                  width: '4px',
                  height: '40px',
                  borderRadius: '2px',
                  background: isPast ? '#64748b' : isUrgent ? '#ef4444' : isUpcoming ? '#f59e0b' : '#22c55e'
                }} />
                <div>
                  <div style={{ fontWeight: 500, color: '#f1f5f9' }}>{card.issuer} {card.name}</div>
                  <div style={{ color: '#64748b', fontSize: '0.8rem' }}>{card.holder}</div>
                </div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '24px' }}>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ color: '#e2e8f0' }}>{formatDate(card.anniversaryDate)}</div>
                  <div style={{ 
                    color: isPast ? '#64748b' : isUrgent ? '#ef4444' : isUpcoming ? '#f59e0b' : '#94a3b8',
                    fontSize: '0.8rem'
                  }}>
                    {isPast ? 'Passed' : `${card.daysUntilFee} days`}
                  </div>
                </div>
                <div style={{ 
                  fontWeight: 600, 
                  color: '#f59e0b',
                  minWidth: '80px',
                  textAlign: 'right'
                }}>
                  {formatCurrency(card.annualFee)}
                </div>
                {card.feeDecision && (
                  <span style={{
                    padding: '4px 10px',
                    borderRadius: '8px',
                    fontSize: '0.75rem',
                    fontWeight: 600,
                    background: card.feeDecision === 'keep' ? '#166534' : 
                               card.feeDecision === 'downgrade' ? '#1e3a8a' : '#7f1d1d',
                    color: card.feeDecision === 'keep' ? '#86efac' : 
                          card.feeDecision === 'downgrade' ? '#93c5fd' : '#fca5a5'
                  }}>
                    {card.feeDecision.toUpperCase()}
                  </span>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// Enhanced Companion Pass Component for Dashboard
function CompanionPassSection({ companionPasses, setCompanionPasses, cards, holders }) {
  const [showEdit, setShowEdit] = useState(null);

  // Calculate Southwest earning for Companion Pass
  const swCards = cards.filter(c => c.name.toLowerCase().includes('southwest'));
  const currentYear = new Date().getFullYear();
  
  // Find or create SW Companion Pass tracking
  const swPass = companionPasses.find(p => p.type === 'Southwest Companion Pass') || {
    type: 'Southwest Companion Pass',
    earned: false,
    progress: 0,
    target: 135000,
    expiresDate: null
  };

  const updatePass = (index, updates) => {
    const newPasses = [...companionPasses];
    newPasses[index] = { ...newPasses[index], ...updates };
    setCompanionPasses(newPasses);
  };

  const addPass = (pass) => {
    setCompanionPasses([...companionPasses, pass]);
  };

  return (
    <div style={{ marginBottom: '32px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
        <h2 style={{ fontSize: '1.25rem', fontWeight: 600, color: '#f1f5f9', margin: 0 }}>
          Companion Passes & Certificates
        </h2>
        <button 
          className="btn-secondary"
          style={{ padding: '6px 12px', fontSize: '0.8rem' }}
          onClick={() => setShowEdit('new')}
        >
          + Add
        </button>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(350px, 1fr))', gap: '16px' }}>
        {companionPasses.map((pass, idx) => (
          <div key={idx} style={{
            background: pass.earned ? 'linear-gradient(135deg, #166534 0%, #14532d 100%)' : '#1e293b',
            borderRadius: '12px',
            padding: '20px',
            border: pass.earned ? '2px solid #22c55e' : '1px solid #334155',
            position: 'relative'
          }}>
            {pass.earned && (
              <div style={{
                position: 'absolute',
                top: '-8px',
                right: '16px',
                background: '#22c55e',
                color: '#052e16',
                padding: '4px 12px',
                borderRadius: '12px',
                fontSize: '0.7rem',
                fontWeight: 700
              }}>
                ✓ EARNED
              </div>
            )}

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', marginBottom: '12px' }}>
              <div>
                <div style={{ fontWeight: 600, color: '#f1f5f9', fontSize: '1.1rem' }}>{pass.type}</div>
                {pass.holder && <div style={{ color: '#94a3b8', fontSize: '0.85rem' }}>{pass.holder}</div>}
              </div>
              <button
                onClick={() => setShowEdit(idx)}
                style={{
                  background: 'transparent',
                  border: 'none',
                  color: '#64748b',
                  cursor: 'pointer',
                  padding: '4px 8px'
                }}
              >
                ✎
              </button>
            </div>

            {pass.earned ? (
              <div>
                <div style={{ color: '#bbf7d0', marginBottom: '8px' }}>
                  <span style={{ fontWeight: 600 }}>Expires:</span>{' '}
                  <span style={{ 
                    color: daysUntil(pass.expiresDate) < 60 ? '#fbbf24' : '#bbf7d0'
                  }}>
                    {formatDate(pass.expiresDate)}
                  </span>
                </div>
                {daysUntil(pass.expiresDate) && (
                  <div style={{ 
                    padding: '8px 12px',
                    background: 'rgba(0,0,0,0.2)',
                    borderRadius: '6px',
                    color: daysUntil(pass.expiresDate) < 60 ? '#fbbf24' : '#86efac',
                    fontSize: '0.9rem'
                  }}>
                    {daysUntil(pass.expiresDate) > 0 
                      ? `${daysUntil(pass.expiresDate)} days remaining`
                      : 'Expired'}
                  </div>
                )}
                {pass.usedCount !== undefined && (
                  <div style={{ color: '#94a3b8', fontSize: '0.85rem', marginTop: '12px' }}>
                    Used {pass.usedCount} time{pass.usedCount !== 1 ? 's' : ''} this year
                  </div>
                )}
              </div>
            ) : (
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px', fontSize: '0.9rem' }}>
                  <span style={{ color: '#94a3b8' }}>Progress ({currentYear})</span>
                  <span style={{ color: '#e2e8f0', fontWeight: 600 }}>
                    {(pass.progress || 0).toLocaleString()} / {(pass.target || 135000).toLocaleString()}
                  </span>
                </div>
                <div className="progress-bar" style={{ height: '12px', marginBottom: '12px' }}>
                  <div 
                    className="progress-fill" 
                    style={{ 
                      width: `${Math.min(100, ((pass.progress || 0) / (pass.target || 135000)) * 100)}%`,
                      background: 'linear-gradient(90deg, #f59e0b 0%, #fbbf24 100%)'
                    }} 
                  />
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.85rem' }}>
                  <span style={{ color: '#64748b' }}>
                    {((pass.progress || 0) / (pass.target || 135000) * 100).toFixed(1)}% complete
                  </span>
                  <span style={{ color: '#f59e0b' }}>
                    {((pass.target || 135000) - (pass.progress || 0)).toLocaleString()} pts to go
                  </span>
                </div>

                {pass.type === 'Southwest Companion Pass' && (
                  <div style={{ 
                    marginTop: '16px', 
                    padding: '12px', 
                    background: '#0f172a', 
                    borderRadius: '8px',
                    fontSize: '0.8rem',
                    color: '#94a3b8'
                  }}>
                    <div style={{ marginBottom: '8px' }}>
                      <strong style={{ color: '#e2e8f0' }}>Ways to earn:</strong>
                    </div>
                    <div>• Southwest card signup bonuses (50k-80k)</div>
                    <div>• Flying Southwest (points earned)</div>
                    <div>• Rapid Rewards shopping portal</div>
                    <div>• Rapid Rewards dining</div>
                    <div style={{ marginTop: '8px', color: '#f59e0b' }}>
                      💡 Tip: Apply for 2 SW personal cards in same day to combine pulls!
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        ))}
      </div>

      {/* Edit Modal */}
      {showEdit !== null && (
        <div className="modal-overlay" onClick={() => setShowEdit(null)}>
          <div className="modal-content" onClick={e => e.stopPropagation()}>
            <h3 style={{ margin: '0 0 20px', color: '#f1f5f9' }}>
              {showEdit === 'new' ? 'Add Companion Pass' : 'Edit Companion Pass'}
            </h3>
            <form onSubmit={(e) => {
              e.preventDefault();
              const form = e.target;
              const passData = {
                type: form.type.value,
                holder: form.holder.value,
                earned: form.earned.checked,
                expiresDate: form.expiresDate.value || null,
                progress: parseInt(form.progress.value) || 0,
                target: parseInt(form.target.value) || 135000
              };
              if (showEdit === 'new') {
                addPass(passData);
              } else {
                updatePass(showEdit, passData);
              }
              setShowEdit(null);
            }}>
              <div style={{ display: 'grid', gap: '16px' }}>
                <div>
                  <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Type</label>
                  <select 
                    name="type" 
                    className="input-field"
                    defaultValue={showEdit !== 'new' ? companionPasses[showEdit]?.type : ''}
                  >
                    <option value="Southwest Companion Pass">Southwest Companion Pass</option>
                    <option value="Delta Companion Certificate">Delta Companion Certificate</option>
                    <option value="Alaska Companion Fare">Alaska Companion Fare</option>
                    <option value="Other">Other</option>
                  </select>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Holder</label>
                    <select 
                      name="holder" 
                      className="input-field"
                      defaultValue={showEdit !== 'new' ? companionPasses[showEdit]?.holder : holders[0]}
                    >
                      {holders.map(h => <option key={h} value={h}>{h}</option>)}
                    </select>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', paddingTop: '24px' }}>
                    <input 
                      type="checkbox" 
                      name="earned" 
                      id="earned"
                      defaultChecked={showEdit !== 'new' ? companionPasses[showEdit]?.earned : false}
                    />
                    <label htmlFor="earned" style={{ color: '#94a3b8' }}>Already Earned</label>
                  </div>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Current Progress</label>
                    <input 
                      name="progress" 
                      type="number" 
                      className="input-field"
                      defaultValue={showEdit !== 'new' ? companionPasses[showEdit]?.progress : 0}
                    />
                  </div>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Target</label>
                    <input 
                      name="target" 
                      type="number" 
                      className="input-field"
                      defaultValue={showEdit !== 'new' ? companionPasses[showEdit]?.target : 135000}
                    />
                  </div>
                </div>
                <div>
                  <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Expiration Date (if earned)</label>
                  <input 
                    name="expiresDate" 
                    type="date" 
                    className="input-field"
                    defaultValue={showEdit !== 'new' ? companionPasses[showEdit]?.expiresDate : ''}
                  />
                </div>
              </div>
              <div style={{ display: 'flex', gap: '12px', marginTop: '24px' }}>
                <button type="submit" className="btn-primary">Save</button>
                <button type="button" className="btn-secondary" onClick={() => setShowEdit(null)}>Cancel</button>
                {showEdit !== 'new' && (
                  <button 
                    type="button" 
                    className="btn-secondary"
                    style={{ marginLeft: 'auto', borderColor: '#7f1d1d', color: '#fca5a5' }}
                    onClick={() => {
                      setCompanionPasses(companionPasses.filter((_, i) => i !== showEdit));
                      setShowEdit(null);
                    }}
                  >
                    Delete
                  </button>
                )}
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

// Popular cards database for recommendations
const popularCards = [
  {
    name: 'Sapphire Preferred',
    issuer: 'Chase',
    annualFee: 95,
    signupBonus: 60000,
    signupSpend: 4000,
    signupMonths: 3,
    rewardType: 'Ultimate Rewards',
    pointValue: 0.02,
    categories: '3x dining, 3x streaming, 2x travel, 5x Lyft',
    bestFor: 'Travel redemptions via transfer partners',
    churnWindow: 48,
    notes: 'Cannot have Sapphire bonus in past 48 months'
  },
  {
    name: 'Sapphire Reserve',
    issuer: 'Chase',
    annualFee: 550,
    signupBonus: 60000,
    signupSpend: 4000,
    signupMonths: 3,
    rewardType: 'Ultimate Rewards',
    pointValue: 0.02,
    categories: '3x dining, 3x travel, 10x hotels/car via portal',
    bestFor: 'Heavy travelers, $300 travel credit, Priority Pass',
    churnWindow: 48,
    notes: 'Cannot have Sapphire bonus in past 48 months'
  },
  {
    name: 'Ink Business Preferred',
    issuer: 'Chase',
    annualFee: 95,
    signupBonus: 100000,
    signupSpend: 8000,
    signupMonths: 3,
    rewardType: 'Ultimate Rewards',
    pointValue: 0.02,
    categories: '3x travel, shipping, internet, advertising',
    bestFor: 'Business expenses, high SUB',
    churnWindow: 24,
    notes: 'Business card - does not count toward 5/24'
  },
  {
    name: 'Freedom Unlimited',
    issuer: 'Chase',
    annualFee: 0,
    signupBonus: 20000,
    signupSpend: 500,
    signupMonths: 3,
    rewardType: 'Ultimate Rewards',
    pointValue: 0.02,
    categories: '1.5% everything, 3% dining/drugstores, 5% travel via portal',
    bestFor: 'Everyday spend, pairs with Sapphire',
    churnWindow: 24,
    notes: 'Keep long-term for UR earning'
  },
  {
    name: 'World of Hyatt',
    issuer: 'Chase',
    annualFee: 95,
    signupBonus: 60000,
    signupSpend: 6000,
    signupMonths: 6,
    rewardType: 'Hyatt Points',
    pointValue: 0.017,
    categories: '4x Hyatt, 2x dining/fitness/transit',
    bestFor: 'Hyatt loyalists, free night annually',
    churnWindow: 24,
    notes: 'One of best hotel cards for value'
  },
  {
    name: 'United Explorer',
    issuer: 'Chase',
    annualFee: 95,
    signupBonus: 60000,
    signupSpend: 3000,
    signupMonths: 3,
    rewardType: 'United Miles',
    pointValue: 0.012,
    categories: '2x United, dining, hotel',
    bestFor: 'United flyers, free checked bag',
    churnWindow: 24,
    notes: 'Often has elevated offers 70-80k'
  },
  {
    name: 'Southwest Priority',
    issuer: 'Chase',
    annualFee: 149,
    signupBonus: 50000,
    signupSpend: 3000,
    signupMonths: 3,
    rewardType: 'Rapid Rewards',
    pointValue: 0.014,
    categories: '2x Southwest, Rapid Rewards partners',
    bestFor: 'Companion Pass pursuit, $75 SW credit',
    churnWindow: 24,
    notes: 'Key card for Companion Pass strategy'
  },
  {
    name: 'Gold Card',
    issuer: 'Amex',
    annualFee: 250,
    signupBonus: 60000,
    signupSpend: 6000,
    signupMonths: 6,
    rewardType: 'Membership Rewards',
    pointValue: 0.02,
    categories: '4x dining, 4x groceries (up to $25k)',
    bestFor: 'Dining/groceries, $120 dining credit, $120 Uber',
    churnWindow: 84,
    notes: 'Once per lifetime rule - keep or never get again'
  },
  {
    name: 'Platinum Card',
    issuer: 'Amex',
    annualFee: 695,
    signupBonus: 80000,
    signupSpend: 8000,
    signupMonths: 6,
    rewardType: 'Membership Rewards',
    pointValue: 0.02,
    categories: '5x flights, 5x hotels via Amex Travel',
    bestFor: 'Lounge access, travel credits, status',
    churnWindow: 84,
    notes: 'Once per lifetime - many statement credits offset fee'
  },
  {
    name: 'Blue Cash Preferred',
    issuer: 'Amex',
    annualFee: 95,
    signupBonus: 350,
    signupSpend: 3000,
    signupMonths: 6,
    rewardType: 'Cash Back',
    pointValue: 1,
    categories: '6% groceries (up to $6k), 6% streaming, 3% gas',
    bestFor: 'Families with high grocery spend',
    churnWindow: 84,
    notes: 'Cash back card - once per lifetime'
  },
  {
    name: 'Delta SkyMiles Gold',
    issuer: 'Amex',
    annualFee: 150,
    signupBonus: 70000,
    signupSpend: 3000,
    signupMonths: 6,
    rewardType: 'Delta SkyMiles',
    pointValue: 0.012,
    categories: '2x Delta, dining, groceries',
    bestFor: 'Delta flyers, first checked bag free',
    churnWindow: 84,
    notes: 'Can churn between personal/business versions'
  },
  {
    name: 'Venture X',
    issuer: 'Capital One',
    annualFee: 395,
    signupBonus: 75000,
    signupSpend: 4000,
    signupMonths: 3,
    rewardType: 'Capital One Miles',
    pointValue: 0.01,
    categories: '2x everything, 10x hotels/car via portal',
    bestFor: 'Lounge access, $300 travel credit, easy 2x',
    churnWindow: 48,
    notes: 'No 5/24 equivalent - easier approval'
  },
  {
    name: 'Venture',
    issuer: 'Capital One',
    annualFee: 95,
    signupBonus: 75000,
    signupSpend: 4000,
    signupMonths: 3,
    rewardType: 'Capital One Miles',
    pointValue: 0.01,
    categories: '2x everything, 5x hotels/car via portal',
    bestFor: 'Simple 2x earning, transfer partners',
    churnWindow: 48,
    notes: 'Good for those over 5/24'
  },
  {
    name: 'Citi Premier',
    issuer: 'Citi',
    annualFee: 95,
    signupBonus: 60000,
    signupSpend: 4000,
    signupMonths: 3,
    rewardType: 'ThankYou Points',
    pointValue: 0.017,
    categories: '3x dining, groceries, gas, travel, hotels',
    bestFor: 'Broad 3x categories, transfer partners',
    churnWindow: 24,
    notes: '24 month rule between Citi bonuses'
  }
];

function StrategyTab({ cards, pointsBalances, applications, apiKey, setShowSettings, issuerRules }) {
  const [selectedCard, setSelectedCard] = useState(null);
  const [customCard, setCustomCard] = useState({
    name: '',
    issuer: '',
    annualFee: 0,
    signupBonus: 0,
    signupSpend: 0,
    signupMonths: 3,
    rewardType: 'Cash Back',
    pointValue: 0.01
  });
  const [analysisResult, setAnalysisResult] = useState(null);
  const [analyzing, setAnalyzing] = useState(false);
  const [activeSubTab, setActiveSubTab] = useState('churn');

  // Calculate churn opportunities
  const churnOpportunities = cards
    .filter(c => c.churnEligible)
    .map(card => {
      const daysUntilEligible = daysUntil(card.churnEligible);
      const isEligible = daysUntilEligible <= 0;
      const matchingPopular = popularCards.find(p => 
        p.name.toLowerCase().includes(card.name.toLowerCase()) || 
        card.name.toLowerCase().includes(p.name.toLowerCase())
      );
      return {
        ...card,
        daysUntilEligible,
        isEligible,
        potentialBonus: matchingPopular?.signupBonus || null,
        potentialValue: matchingPopular ? (matchingPopular.signupBonus * matchingPopular.pointValue) : null,
        churnWindow: matchingPopular?.churnWindow || 48
      };
    })
    .sort((a, b) => a.daysUntilEligible - b.daysUntilEligible);

  // Calculate 5/24 status
  const twoYearsAgo = new Date();
  twoYearsAgo.setFullYear(twoYearsAgo.getFullYear() - 2);
  const recentCards = cards.filter(c => new Date(c.openDate) > twoYearsAgo);
  const fiveOverTwentyFour = recentCards.length;
  const canApplyChase = fiveOverTwentyFour < 5;

  // Analyze card with Claude API
  const analyzeCard = async (cardToAnalyze) => {
    if (!apiKey) {
      setShowSettings(true);
      return;
    }

    setAnalyzing(true);
    setAnalysisResult(null);

    const currentCardsContext = cards.map(c => `${c.issuer} ${c.name} (${c.holder})`).join(', ');
    const pointsContext = Object.entries(pointsBalances)
      .filter(([_, v]) => v > 0)
      .map(([k, v]) => `${k}: ${v.toLocaleString()}`)
      .join(', ');

    try {
      const response = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'anthropic-dangerous-direct-browser-access': 'true'
        },
        body: JSON.stringify({
          model: 'claude-sonnet-4-20250514',
          max_tokens: 2000,
          messages: [{
            role: 'user',
            content: `You are a credit card rewards expert. Analyze whether this person should apply for this card.

CARD BEING CONSIDERED:
- Name: ${cardToAnalyze.issuer} ${cardToAnalyze.name}
- Annual Fee: $${cardToAnalyze.annualFee}
- Signup Bonus: ${cardToAnalyze.signupBonus.toLocaleString()} ${cardToAnalyze.rewardType}
- Signup Spend Requirement: $${cardToAnalyze.signupSpend} in ${cardToAnalyze.signupMonths} months
- Point Value Estimate: ${cardToAnalyze.pointValue} cents per point
- Categories: ${cardToAnalyze.categories || 'N/A'}
- Best For: ${cardToAnalyze.bestFor || 'N/A'}
- Notes: ${cardToAnalyze.notes || 'N/A'}

CURRENT SITUATION:
- Cards already owned: ${currentCardsContext}
- Current points balances: ${pointsContext}
- Chase 5/24 status: ${fiveOverTwentyFour}/5 (${canApplyChase ? 'CAN apply for Chase cards' : 'CANNOT apply for Chase cards'})
- Recent cards (24 months): ${recentCards.map(c => `${c.issuer} ${c.name}`).join(', ') || 'None'}

Provide a structured analysis in JSON format:
{
  "recommendation": "APPLY" | "WAIT" | "SKIP",
  "signupBonusValue": number (dollar value of signup bonus),
  "firstYearValue": number (total first year value including bonus minus fee),
  "ongoingAnnualValue": number (value in subsequent years minus fee),
  "pros": ["string", "string", ...],
  "cons": ["string", "string", ...],
  "timing": "string - best time to apply or why to wait",
  "alternativeCards": ["string", "string"] or null,
  "spendStrategy": "string - how to meet minimum spend",
  "keepOrChurn": "KEEP" | "CHURN" - whether to keep long-term or cancel after bonus,
  "summary": "2-3 sentence summary of recommendation"
}

Consider:
1. Does this card overlap with existing cards?
2. Is the signup bonus competitive vs alternatives?
3. Can they realistically meet the spend requirement?
4. Impact on 5/24 status
5. Whether this is a card to keep or churn
6. Transfer partner overlap with existing points

Return ONLY valid JSON.`
          }]
        })
      });

      const data = await response.json();

      if (data.error) {
        setAnalysisResult({ error: data.error.message || 'API error' });
        setAnalyzing(false);
        return;
      }

      let content = data.content?.[0]?.text || '';
      content = content.replace(/^```(?:json)?\s*\n?/i, '').replace(/\n?```\s*$/i, '').trim();

      try {
        setAnalysisResult(JSON.parse(content));
      } catch {
        let braceCount = 0, startIdx = -1, endIdx = -1;
        for (let i = 0; i < content.length; i++) {
          if (content[i] === '{') { if (startIdx === -1) startIdx = i; braceCount++; }
          else if (content[i] === '}') { braceCount--; if (braceCount === 0 && startIdx !== -1) { endIdx = i; break; } }
        }
        if (startIdx !== -1 && endIdx !== -1) {
          setAnalysisResult(JSON.parse(content.substring(startIdx, endIdx + 1)));
        } else {
          setAnalysisResult({ error: 'Could not parse response' });
        }
      }
    } catch (error) {
      setAnalysisResult({ error: error.message });
    }
    setAnalyzing(false);
  };

  return (
    <div>
      {/* Sub-navigation */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '24px' }}>
        {[
          { id: 'churn', label: 'Churn Opportunities' },
          { id: 'evaluate', label: 'Evaluate New Card' },
          { id: 'recommendations', label: 'Card Recommendations' }
        ].map(tab => (
          <button
            key={tab.id}
            onClick={() => { setActiveSubTab(tab.id); setAnalysisResult(null); setSelectedCard(null); }}
            style={{
              padding: '10px 20px',
              border: 'none',
              borderRadius: '8px',
              background: activeSubTab === tab.id ? '#f59e0b' : '#334155',
              color: activeSubTab === tab.id ? '#0f172a' : '#e2e8f0',
              fontWeight: 600,
              cursor: 'pointer',
              transition: 'all 0.2s',
              fontFamily: 'inherit'
            }}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Churn Opportunities */}
      {activeSubTab === 'churn' && (
        <div>
          <div style={{ 
            background: '#1e293b', 
            borderRadius: '12px', 
            padding: '20px', 
            marginBottom: '24px',
            border: '1px solid #334155'
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <h3 style={{ margin: 0, color: '#f1f5f9' }}>Chase 5/24 Status</h3>
                <p style={{ margin: '8px 0 0', color: '#94a3b8', fontSize: '0.9rem' }}>
                  Cards opened in the past 24 months count toward Chase's 5/24 rule
                </p>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ 
                  fontSize: '3rem', 
                  fontWeight: 700, 
                  color: canApplyChase ? '#22c55e' : '#ef4444' 
                }}>
                  {fiveOverTwentyFour}/5
                </div>
                <div style={{ 
                  color: canApplyChase ? '#86efac' : '#fca5a5',
                  fontWeight: 500
                }}>
                  {canApplyChase ? `${5 - fiveOverTwentyFour} slots available` : 'Over 5/24'}
                </div>
              </div>
            </div>
            {recentCards.length > 0 && (
              <div style={{ marginTop: '16px', paddingTop: '16px', borderTop: '1px solid #334155' }}>
                <div style={{ color: '#64748b', fontSize: '0.85rem', marginBottom: '8px' }}>Recent cards counting toward 5/24:</div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                  {recentCards.map(c => (
                    <span key={c.id} style={{
                      background: '#0f172a',
                      padding: '6px 12px',
                      borderRadius: '6px',
                      fontSize: '0.85rem',
                      color: '#e2e8f0'
                    }}>
                      {c.issuer} {c.name} ({formatDate(c.openDate)})
                    </span>
                  ))}
                </div>
              </div>
            )}
          </div>

          <h3 style={{ color: '#f1f5f9', marginBottom: '16px' }}>Churn Timeline</h3>
          
          {churnOpportunities.length === 0 ? (
            <div style={{ 
              background: '#1e293b', 
              borderRadius: '12px', 
              padding: '32px', 
              textAlign: 'center',
              border: '1px solid #334155'
            }}>
              <div style={{ color: '#94a3b8' }}>No cards with churn dates set</div>
            </div>
          ) : (
            <div style={{ display: 'grid', gap: '12px' }}>
              {churnOpportunities.map(card => (
                <div key={card.id} style={{
                  background: '#1e293b',
                  borderRadius: '12px',
                  padding: '20px',
                  border: card.isEligible ? '2px solid #22c55e' : '1px solid #334155'
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                        <h4 style={{ margin: 0, color: '#f1f5f9' }}>{card.issuer} {card.name}</h4>
                        {card.isEligible && (
                          <span style={{
                            background: '#166534',
                            color: '#86efac',
                            padding: '4px 10px',
                            borderRadius: '12px',
                            fontSize: '0.75rem',
                            fontWeight: 600
                          }}>
                            ELIGIBLE NOW
                          </span>
                        )}
                      </div>
                      <div style={{ color: '#64748b', fontSize: '0.85rem', marginTop: '4px' }}>
                        {card.holder} • Opened {formatDate(card.openDate)}
                      </div>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <div style={{ 
                        color: card.isEligible ? '#22c55e' : '#f59e0b',
                        fontWeight: 600
                      }}>
                        {card.isEligible ? 'Ready to churn!' : `${card.daysUntilEligible} days`}
                      </div>
                      <div style={{ color: '#64748b', fontSize: '0.85rem' }}>
                        Eligible: {formatDate(card.churnEligible)}
                      </div>
                    </div>
                  </div>
                  
                  {card.potentialBonus && (
                    <div style={{ 
                      marginTop: '16px', 
                      paddingTop: '16px', 
                      borderTop: '1px solid #334155',
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center'
                    }}>
                      <div>
                        <div style={{ color: '#94a3b8', fontSize: '0.85rem' }}>Potential new signup bonus</div>
                        <div style={{ color: '#f59e0b', fontWeight: 600, fontSize: '1.25rem' }}>
                          {card.potentialBonus.toLocaleString()} pts
                        </div>
                      </div>
                      <div style={{ textAlign: 'right' }}>
                        <div style={{ color: '#94a3b8', fontSize: '0.85rem' }}>Estimated value</div>
                        <div style={{ color: '#22c55e', fontWeight: 600, fontSize: '1.25rem' }}>
                          {formatCurrency(card.potentialValue)}
                        </div>
                      </div>
                    </div>
                  )}

                  {card.isEligible && (
                    <button
                      className="btn-primary"
                      style={{ marginTop: '16px', width: '100%' }}
                      onClick={() => {
                        const matchingPopular = popularCards.find(p => 
                          p.name.toLowerCase().includes(card.name.toLowerCase()) || 
                          card.name.toLowerCase().includes(p.name.toLowerCase())
                        );
                        if (matchingPopular) {
                          setSelectedCard(matchingPopular);
                          setActiveSubTab('evaluate');
                          analyzeCard(matchingPopular);
                        }
                      }}
                    >
                      Analyze Re-Application →
                    </button>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Evaluate New Card */}
      {activeSubTab === 'evaluate' && (
        <div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px' }}>
            {/* Card Selection */}
            <div>
              <h3 style={{ color: '#f1f5f9', marginBottom: '16px' }}>Select a Card to Evaluate</h3>
              
              <div style={{ 
                background: '#1e293b', 
                borderRadius: '12px', 
                padding: '20px',
                border: '1px solid #334155',
                maxHeight: '500px',
                overflowY: 'auto'
              }}>
                {popularCards.map((card, idx) => (
                  <div
                    key={idx}
                    onClick={() => { setSelectedCard(card); setAnalysisResult(null); }}
                    style={{
                      padding: '16px',
                      borderRadius: '8px',
                      marginBottom: '8px',
                      cursor: 'pointer',
                      background: selectedCard?.name === card.name ? '#334155' : 'transparent',
                      border: selectedCard?.name === card.name ? '1px solid #f59e0b' : '1px solid transparent',
                      transition: 'all 0.2s'
                    }}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
                      <div>
                        <div style={{ fontWeight: 600, color: '#f1f5f9' }}>{card.issuer} {card.name}</div>
                        <div style={{ color: '#64748b', fontSize: '0.85rem', marginTop: '4px' }}>
                          {card.signupBonus.toLocaleString()} {card.rewardType} • ${card.annualFee}/yr
                        </div>
                      </div>
                      <div style={{ 
                        color: '#22c55e', 
                        fontWeight: 600,
                        fontSize: '0.9rem'
                      }}>
                        ~{formatCurrency(card.signupBonus * card.pointValue)}
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              {/* Custom Card Entry */}
              <div style={{ marginTop: '20px' }}>
                <h4 style={{ color: '#94a3b8', marginBottom: '12px' }}>Or Enter Custom Card</h4>
                <div style={{ display: 'grid', gap: '12px' }}>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                    <input
                      className="input-field"
                      placeholder="Card Name"
                      value={customCard.name}
                      onChange={e => setCustomCard({ ...customCard, name: e.target.value })}
                    />
                    <input
                      className="input-field"
                      placeholder="Issuer"
                      value={customCard.issuer}
                      onChange={e => setCustomCard({ ...customCard, issuer: e.target.value })}
                    />
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px' }}>
                    <input
                      className="input-field"
                      type="number"
                      placeholder="Annual Fee"
                      value={customCard.annualFee || ''}
                      onChange={e => setCustomCard({ ...customCard, annualFee: parseFloat(e.target.value) || 0 })}
                    />
                    <input
                      className="input-field"
                      type="number"
                      placeholder="Signup Bonus"
                      value={customCard.signupBonus || ''}
                      onChange={e => setCustomCard({ ...customCard, signupBonus: parseFloat(e.target.value) || 0 })}
                    />
                    <input
                      className="input-field"
                      type="number"
                      placeholder="Spend Req"
                      value={customCard.signupSpend || ''}
                      onChange={e => setCustomCard({ ...customCard, signupSpend: parseFloat(e.target.value) || 0 })}
                    />
                  </div>
                  <button
                    className="btn-secondary"
                    onClick={() => {
                      if (customCard.name && customCard.issuer) {
                        setSelectedCard({ ...customCard, categories: '', bestFor: '', notes: '' });
                        setAnalysisResult(null);
                      }
                    }}
                  >
                    Use Custom Card
                  </button>
                </div>
              </div>
            </div>

            {/* Analysis Panel */}
            <div>
              <h3 style={{ color: '#f1f5f9', marginBottom: '16px' }}>Analysis</h3>
              
              {!selectedCard ? (
                <div style={{ 
                  background: '#1e293b', 
                  borderRadius: '12px', 
                  padding: '32px',
                  border: '1px solid #334155',
                  textAlign: 'center'
                }}>
                  <div style={{ color: '#64748b', marginBottom: '8px' }}>Select a card to analyze</div>
                  <div style={{ color: '#94a3b8', fontSize: '0.85rem' }}>
                    Claude will evaluate whether this card makes sense for your situation
                  </div>
                </div>
              ) : (
                <div style={{ 
                  background: '#1e293b', 
                  borderRadius: '12px', 
                  padding: '24px',
                  border: '1px solid #334155'
                }}>
                  {/* Selected Card Summary */}
                  <div style={{ marginBottom: '20px', paddingBottom: '20px', borderBottom: '1px solid #334155' }}>
                    <h4 style={{ margin: '0 0 12px', color: '#f1f5f9' }}>
                      {selectedCard.issuer} {selectedCard.name}
                    </h4>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', fontSize: '0.9rem' }}>
                      <div>
                        <span style={{ color: '#64748b' }}>Annual Fee:</span>
                        <span style={{ color: '#e2e8f0', marginLeft: '8px' }}>${selectedCard.annualFee}</span>
                      </div>
                      <div>
                        <span style={{ color: '#64748b' }}>Signup Bonus:</span>
                        <span style={{ color: '#f59e0b', marginLeft: '8px', fontWeight: 600 }}>
                          {selectedCard.signupBonus?.toLocaleString()} pts
                        </span>
                      </div>
                      <div>
                        <span style={{ color: '#64748b' }}>Spend Required:</span>
                        <span style={{ color: '#e2e8f0', marginLeft: '8px' }}>
                          ${selectedCard.signupSpend?.toLocaleString()} in {selectedCard.signupMonths}mo
                        </span>
                      </div>
                      <div>
                        <span style={{ color: '#64748b' }}>Est. Value:</span>
                        <span style={{ color: '#22c55e', marginLeft: '8px', fontWeight: 600 }}>
                          {formatCurrency(selectedCard.signupBonus * selectedCard.pointValue)}
                        </span>
                      </div>
                    </div>
                    {selectedCard.categories && (
                      <div style={{ marginTop: '12px', color: '#94a3b8', fontSize: '0.85rem' }}>
                        <strong>Categories:</strong> {selectedCard.categories}
                      </div>
                    )}
                  </div>

                  {/* Analyze Button */}
                  {!analysisResult && (
                    <button
                      className="btn-primary"
                      style={{ width: '100%' }}
                      onClick={() => analyzeCard(selectedCard)}
                      disabled={analyzing}
                    >
                      {analyzing ? 'Analyzing with Claude...' : 'Analyze This Card'}
                    </button>
                  )}

                  {/* Analysis Result */}
                  {analysisResult && !analysisResult.error && (
                    <div>
                      {/* Recommendation Badge */}
                      <div style={{ 
                        display: 'flex', 
                        justifyContent: 'center',
                        marginBottom: '20px'
                      }}>
                        <span style={{
                          padding: '12px 32px',
                          borderRadius: '24px',
                          fontSize: '1.25rem',
                          fontWeight: 700,
                          background: analysisResult.recommendation === 'APPLY' ? '#166534' : 
                                     analysisResult.recommendation === 'WAIT' ? '#7c2d12' : '#7f1d1d',
                          color: analysisResult.recommendation === 'APPLY' ? '#86efac' : 
                                analysisResult.recommendation === 'WAIT' ? '#fdba74' : '#fca5a5'
                        }}>
                          {analysisResult.recommendation === 'APPLY' ? '✓ APPLY' : 
                           analysisResult.recommendation === 'WAIT' ? '⏳ WAIT' : '✗ SKIP'}
                        </span>
                      </div>

                      {/* Value Summary */}
                      <div style={{ 
                        display: 'grid', 
                        gridTemplateColumns: '1fr 1fr 1fr', 
                        gap: '12px',
                        marginBottom: '20px'
                      }}>
                        <div style={{ background: '#0f172a', padding: '12px', borderRadius: '8px', textAlign: 'center' }}>
                          <div style={{ color: '#64748b', fontSize: '0.75rem' }}>Bonus Value</div>
                          <div style={{ color: '#22c55e', fontWeight: 700, fontSize: '1.1rem' }}>
                            {formatCurrency(analysisResult.signupBonusValue)}
                          </div>
                        </div>
                        <div style={{ background: '#0f172a', padding: '12px', borderRadius: '8px', textAlign: 'center' }}>
                          <div style={{ color: '#64748b', fontSize: '0.75rem' }}>Year 1 Net</div>
                          <div style={{ color: '#f59e0b', fontWeight: 700, fontSize: '1.1rem' }}>
                            {formatCurrency(analysisResult.firstYearValue)}
                          </div>
                        </div>
                        <div style={{ background: '#0f172a', padding: '12px', borderRadius: '8px', textAlign: 'center' }}>
                          <div style={{ color: '#64748b', fontSize: '0.75rem' }}>Ongoing/Yr</div>
                          <div style={{ 
                            color: analysisResult.ongoingAnnualValue >= 0 ? '#22c55e' : '#ef4444', 
                            fontWeight: 700, 
                            fontSize: '1.1rem' 
                          }}>
                            {formatCurrency(analysisResult.ongoingAnnualValue)}
                          </div>
                        </div>
                      </div>

                      {/* Pros & Cons */}
                      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '20px' }}>
                        <div>
                          <div style={{ color: '#22c55e', fontWeight: 600, marginBottom: '8px' }}>✓ Pros</div>
                          {analysisResult.pros?.map((pro, i) => (
                            <div key={i} style={{ color: '#94a3b8', fontSize: '0.85rem', marginBottom: '4px' }}>
                              • {pro}
                            </div>
                          ))}
                        </div>
                        <div>
                          <div style={{ color: '#ef4444', fontWeight: 600, marginBottom: '8px' }}>✗ Cons</div>
                          {analysisResult.cons?.map((con, i) => (
                            <div key={i} style={{ color: '#94a3b8', fontSize: '0.85rem', marginBottom: '4px' }}>
                              • {con}
                            </div>
                          ))}
                        </div>
                      </div>

                      {/* Additional Details */}
                      <div style={{ display: 'grid', gap: '12px' }}>
                        <div style={{ background: '#0f172a', padding: '12px', borderRadius: '8px' }}>
                          <div style={{ color: '#64748b', fontSize: '0.75rem', marginBottom: '4px' }}>Timing</div>
                          <div style={{ color: '#e2e8f0', fontSize: '0.9rem' }}>{analysisResult.timing}</div>
                        </div>
                        <div style={{ background: '#0f172a', padding: '12px', borderRadius: '8px' }}>
                          <div style={{ color: '#64748b', fontSize: '0.75rem', marginBottom: '4px' }}>Spend Strategy</div>
                          <div style={{ color: '#e2e8f0', fontSize: '0.9rem' }}>{analysisResult.spendStrategy}</div>
                        </div>
                        <div style={{ background: '#0f172a', padding: '12px', borderRadius: '8px' }}>
                          <div style={{ color: '#64748b', fontSize: '0.75rem', marginBottom: '4px' }}>Keep or Churn?</div>
                          <div style={{ 
                            color: analysisResult.keepOrChurn === 'KEEP' ? '#22c55e' : '#f59e0b', 
                            fontSize: '0.9rem',
                            fontWeight: 600
                          }}>
                            {analysisResult.keepOrChurn}
                          </div>
                        </div>
                      </div>

                      {/* Summary */}
                      <div style={{ 
                        marginTop: '20px', 
                        padding: '16px', 
                        background: '#0f172a', 
                        borderRadius: '8px',
                        borderLeft: '3px solid #f59e0b'
                      }}>
                        <div style={{ color: '#e2e8f0', fontSize: '0.95rem' }}>{analysisResult.summary}</div>
                      </div>

                      <button
                        className="btn-secondary"
                        style={{ width: '100%', marginTop: '16px' }}
                        onClick={() => setAnalysisResult(null)}
                      >
                        Analyze Again
                      </button>
                    </div>
                  )}

                  {analysisResult?.error && (
                    <div style={{ color: '#fca5a5', marginTop: '16px' }}>
                      Error: {analysisResult.error}
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Recommendations */}
      {activeSubTab === 'recommendations' && (
        <div>
          <div style={{ 
            background: '#1e293b', 
            borderRadius: '12px', 
            padding: '20px', 
            marginBottom: '24px',
            border: '1px solid #334155'
          }}>
            <h3 style={{ margin: '0 0 8px', color: '#f1f5f9' }}>Personalized Recommendations</h3>
            <p style={{ margin: 0, color: '#94a3b8', fontSize: '0.9rem' }}>
              Based on your current cards and 5/24 status of {fiveOverTwentyFour}/5
            </p>
          </div>

          {/* Chase Cards if under 5/24 */}
          {canApplyChase && (
            <div style={{ marginBottom: '32px' }}>
              <h4 style={{ color: '#3b82f6', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span style={{ 
                  background: '#1e3a8a', 
                  padding: '4px 12px', 
                  borderRadius: '6px',
                  fontSize: '0.8rem'
                }}>
                  PRIORITY
                </span>
                Chase Cards (Before You Hit 5/24)
              </h4>
              <div style={{ display: 'grid', gap: '12px' }}>
                {popularCards
                  .filter(c => c.issuer === 'Chase' && !cards.some(existing => 
                    existing.name.toLowerCase().includes(c.name.toLowerCase()) && 
                    existing.issuer === 'Chase'
                  ))
                  .slice(0, 4)
                  .map((card, idx) => (
                    <div key={idx} className="card-hover" style={{
                      background: '#1e293b',
                      borderRadius: '12px',
                      padding: '20px',
                      border: '1px solid #334155',
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      cursor: 'pointer',
                      transition: 'all 0.3s'
                    }}
                    onClick={() => {
                      setSelectedCard(card);
                      setActiveSubTab('evaluate');
                    }}
                    >
                      <div>
                        <div style={{ fontWeight: 600, color: '#f1f5f9' }}>{card.name}</div>
                        <div style={{ color: '#64748b', fontSize: '0.85rem', marginTop: '4px' }}>
                          {card.bestFor}
                        </div>
                        <div style={{ color: '#94a3b8', fontSize: '0.85rem', marginTop: '4px' }}>
                          ${card.signupSpend.toLocaleString()} spend in {card.signupMonths} months • ${card.annualFee}/yr
                        </div>
                      </div>
                      <div style={{ textAlign: 'right' }}>
                        <div style={{ color: '#f59e0b', fontWeight: 700, fontSize: '1.25rem' }}>
                          {card.signupBonus.toLocaleString()}
                        </div>
                        <div style={{ color: '#64748b', fontSize: '0.85rem' }}>{card.rewardType}</div>
                        <div style={{ color: '#22c55e', fontSize: '0.9rem', marginTop: '4px' }}>
                          ≈{formatCurrency(card.signupBonus * card.pointValue)}
                        </div>
                      </div>
                    </div>
                  ))}
              </div>
            </div>
          )}

          {/* Other Recommendations */}
          <div>
            <h4 style={{ color: '#94a3b8', marginBottom: '16px' }}>
              {canApplyChase ? 'Other Good Options' : 'Recommended Cards (Over 5/24 Friendly)'}
            </h4>
            <div style={{ display: 'grid', gap: '12px' }}>
              {popularCards
                .filter(c => canApplyChase ? c.issuer !== 'Chase' : true)
                .filter(c => !cards.some(existing => 
                  existing.name.toLowerCase().includes(c.name.toLowerCase()) && 
                  existing.issuer === c.issuer
                ))
                .slice(0, 6)
                .map((card, idx) => (
                  <div key={idx} className="card-hover" style={{
                    background: '#1e293b',
                    borderRadius: '12px',
                    padding: '20px',
                    border: '1px solid #334155',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    cursor: 'pointer',
                    transition: 'all 0.3s'
                  }}
                  onClick={() => {
                    setSelectedCard(card);
                    setActiveSubTab('evaluate');
                  }}
                  >
                    <div>
                      <div style={{ fontWeight: 600, color: '#f1f5f9' }}>{card.issuer} {card.name}</div>
                      <div style={{ color: '#64748b', fontSize: '0.85rem', marginTop: '4px' }}>
                        {card.bestFor}
                      </div>
                      <div style={{ color: '#94a3b8', fontSize: '0.85rem', marginTop: '4px' }}>
                        ${card.signupSpend.toLocaleString()} spend in {card.signupMonths} months • ${card.annualFee}/yr
                      </div>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <div style={{ color: '#f59e0b', fontWeight: 700, fontSize: '1.25rem' }}>
                        {card.signupBonus.toLocaleString()}
                      </div>
                      <div style={{ color: '#64748b', fontSize: '0.85rem' }}>{card.rewardType}</div>
                      <div style={{ color: '#22c55e', fontSize: '0.9rem', marginTop: '4px' }}>
                        ≈{formatCurrency(card.signupBonus * card.pointValue)}
                      </div>
                    </div>
                  </div>
                ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default function CreditCardTracker() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [activeSection, setActiveSection] = useState('wallet');
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [cards, setCards] = useState([]);
  const [pointsBalances, setPointsBalances] = useState({});
  const [companionPasses, setCompanionPasses] = useState([]);
  const [applications, setApplications] = useState([]);
  const [creditPulls, setCreditPulls] = useState([]);
  const [apiKey, setApiKey] = useState('sk-ant-api03-Ak6hsx540KwW1pLwTNI2LyYrr61bG7B9dlIt36Y03NhuhTRL0FSCwC2v8Si7pNIVHbzUjvZRjPQLj-Ubf7NR1w-GRKJgwAA');
  const [statementText, setStatementText] = useState('');
  const [parsing, setParsing] = useState(false);
  const [parseResult, setParseResult] = useState(null);
  const [editingCard, setEditingCard] = useState(null);
  const [showAddCard, setShowAddCard] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedImportCard, setSelectedImportCard] = useState('');
  const [holders, setHolders] = useState(['Sterling', 'Spouse']);
  const [showSettings, setShowSettings] = useState(false);
  const [newHolderName, setNewHolderName] = useState('');

  // Sidebar navigation structure
  const sidebarSections = [
    { id: 'wallet', label: 'Wallet', icon: '💳', group: 'OVERVIEW', defaultTab: 'dashboard', subTabs: ['dashboard', 'points', 'payoff'] },
    { id: 'cards', label: 'Cards', icon: '🗂', group: 'MANAGE', defaultTab: 'cards', subTabs: ['cards', 'fees'] },
    { id: 'offers', label: 'Offers', icon: '🏷', group: 'MANAGE', defaultTab: 'offers', subTabs: ['offers'] },
    { id: 'churn', label: 'Churn Tracker', icon: '📊', group: 'MANAGE', defaultTab: 'applications', subTabs: ['applications', 'strategy'] },
  ];

  const switchSection = (sectionId) => {
    setActiveSection(sectionId);
    const section = sidebarSections.find(s => s.id === sectionId);
    if (section) setActiveTab(section.defaultTab);
  };
  const [icloudStatus, setIcloudStatus] = useState({ available: false, lastSync: null });

  // Color palette for holder badges
  const holderColors = [
    { bg: '#1e3a5f', text: '#60a5fa' },
    { bg: '#3f1f5f', text: '#c084fc' },
    { bg: '#1f4f3f', text: '#6ee7b7' },
    { bg: '#5f3f1f', text: '#fbbf24' },
    { bg: '#4f1f1f', text: '#fca5a5' },
  ];

  const getHolderColor = (name) => {
    const idx = holders.indexOf(name);
    return holderColors[(idx >= 0 ? idx : 0) % holderColors.length];
  };

  // Helper: safe storage access (works in both Electron and browser)
  const storageGet = (key) => window.storage ? window.storage.get(key).catch(() => null) : Promise.resolve(null);
  const storageSet = (key, value) => window.storage ? window.storage.set(key, value).catch(console.error) : Promise.resolve();

  // Load data from persistent storage
  useEffect(() => {
    const loadData = async () => {
      try {
        const [cardsResult, pointsResult, passesResult, apiKeyResult, applicationsResult, creditPullsResult, holdersResult] = await Promise.all([
          storageGet('cc-tracker-cards'),
          storageGet('cc-tracker-points'),
          storageGet('cc-tracker-passes'),
          storageGet('cc-tracker-apikey'),
          storageGet('cc-tracker-applications'),
          storageGet('cc-tracker-creditpulls'),
          storageGet('cc-tracker-holders')
        ]);

        setCards(cardsResult?.value ? JSON.parse(cardsResult.value) : initialCards);
        setPointsBalances(pointsResult?.value ? JSON.parse(pointsResult.value) : initialPointsBalances);
        setCompanionPasses(passesResult?.value ? JSON.parse(passesResult.value) : initialCompanionPasses);
        setApplications(applicationsResult?.value ? JSON.parse(applicationsResult.value) : initialApplications);
        setCreditPulls(creditPullsResult?.value ? JSON.parse(creditPullsResult.value) : initialCreditPulls);
        if (apiKeyResult?.value) setApiKey(apiKeyResult.value);
        else setApiKey('sk-ant-api03-Ak6hsx540KwW1pLwTNI2LyYrr61bG7B9dlIt36Y03NhuhTRL0FSCwC2v8Si7pNIVHbzUjvZRjPQLj-Ubf7NR1w-GRKJgwAA');
        if (holdersResult?.value) setHolders(JSON.parse(holdersResult.value));
      } catch (e) {
        console.error('Error loading data:', e);
        setCards(initialCards);
        setPointsBalances(initialPointsBalances);
        setCompanionPasses(initialCompanionPasses);
        setApplications(initialApplications);
        setCreditPulls(initialCreditPulls);
      }
      setIsLoading(false);

      // Check iCloud status
      if (window.icloud) {
        const status = await window.icloud.getStatus();
        setIcloudStatus(status);
      }
    };
    loadData();
  }, []);

  // Listen for iCloud changes from other devices
  useEffect(() => {
    if (window.icloud) {
      window.icloud.onDataChanged((data) => {
        if (data.cards) setCards(data.cards);
        if (data.pointsBalances) setPointsBalances(data.pointsBalances);
        if (data.companionPasses) setCompanionPasses(data.companionPasses);
        if (data.applications) setApplications(data.applications);
        if (data.creditPulls) setCreditPulls(data.creditPulls);
        if (data.holders) setHolders(data.holders);
        setIcloudStatus(prev => ({ ...prev, lastSync: new Date().toISOString() }));
      });
    }
  }, []);

  // Save data whenever it changes
  useEffect(() => {
    if (!isLoading && cards.length > 0) {
      storageSet('cc-tracker-cards', JSON.stringify(cards));
    }
  }, [cards, isLoading]);

  useEffect(() => {
    if (!isLoading && Object.keys(pointsBalances).length > 0) {
      storageSet('cc-tracker-points', JSON.stringify(pointsBalances));
    }
  }, [pointsBalances, isLoading]);

  useEffect(() => {
    if (!isLoading && companionPasses.length > 0) {
      storageSet('cc-tracker-passes', JSON.stringify(companionPasses));
    }
  }, [companionPasses, isLoading]);

  useEffect(() => {
    if (!isLoading) {
      storageSet('cc-tracker-applications', JSON.stringify(applications));
    }
  }, [applications, isLoading]);

  useEffect(() => {
    if (!isLoading) {
      storageSet('cc-tracker-creditpulls', JSON.stringify(creditPulls));
    }
  }, [creditPulls, isLoading]);

  useEffect(() => {
    if (!isLoading && holders.length > 0) {
      storageSet('cc-tracker-holders', JSON.stringify(holders));
    }
  }, [holders, isLoading]);

  const saveApiKey = async (key) => {
    setApiKey(key);
    await storageSet('cc-tracker-apikey', key);
    setShowSettings(false);
  };

  const parseStatement = async () => {
    if (!apiKey || !statementText) return;
    setParsing(true);
    setParseResult(null);

    try {
      const response = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'anthropic-dangerous-direct-browser-access': 'true'
        },
        body: JSON.stringify({
          model: 'claude-sonnet-4-20250514',
          max_tokens: 8000,
          messages: [{
            role: 'user',
            content: `Parse this credit card statement and extract the following information in JSON format:
{
  "cardIdentifier": "string - card name/type if identifiable",
  "issuer": "string - bank/issuer name",
  "statementDate": "YYYY-MM-DD",
  "balance": number,
  "minimumPayment": number,
  "dueDate": "YYYY-MM-DD",
  "apr": number (as percentage, e.g., 21.99),
  "transactions": [
    {
      "date": "YYYY-MM-DD",
      "description": "string",
      "amount": number (positive for charges, negative for credits),
      "category": "string - best guess: groceries, gas, dining, travel, streaming, amazon, other"
    }
  ],
  "categoryTotals": {
    "groceries": number,
    "gas": number,
    "dining": number,
    "travel": number,
    "streaming": number,
    "amazon": number,
    "other": number
  },
  "rewardsEarned": number or null,
  "rewardsType": "string - points/miles/cashback type" or null
}

Statement text:
${statementText}

Return ONLY valid JSON, no other text.`
          }]
        })
      });

      const data = await response.json();

      // Check for API error responses
      if (data.error) {
        setParseResult({ error: data.error.message || 'API error', raw: JSON.stringify(data.error, null, 2) });
        setParsing(false);
        return;
      }

      let content = data.content?.[0]?.text || '';

      // Strip markdown code fences if present
      content = content.replace(/^```(?:json)?\s*\n?/i, '').replace(/\n?```\s*$/i, '').trim();

      // Try to parse the JSON response
      try {
        const parsed = JSON.parse(content);
        setParseResult(parsed);
      } catch {
        // Fallback: find outermost balanced braces
        let braceCount = 0, startIdx = -1, endIdx = -1;
        for (let i = 0; i < content.length; i++) {
          if (content[i] === '{') { if (startIdx === -1) startIdx = i; braceCount++; }
          else if (content[i] === '}') { braceCount--; if (braceCount === 0 && startIdx !== -1) { endIdx = i; break; } }
        }
        if (startIdx !== -1 && endIdx !== -1) {
          const parsed = JSON.parse(content.substring(startIdx, endIdx + 1));
          setParseResult(parsed);
        } else {
          setParseResult({ error: 'Could not parse response', raw: content });
        }
      }
    } catch (error) {
      setParseResult({ error: error.message });
    }
    setParsing(false);
  };

  const applyParseResult = () => {
    if (!parseResult || parseResult.error) return;

    // Use selected card from dropdown, or try to auto-match
    const matchingCard = selectedImportCard
      ? cards.find(c => c.id === parseInt(selectedImportCard))
      : cards.find(c =>
          c.name.toLowerCase().includes(parseResult.cardIdentifier?.toLowerCase() || '') ||
          c.issuer.toLowerCase() === parseResult.issuer?.toLowerCase()
        );

    if (matchingCard) {
      setCards(cards.map(c => {
        if (c.id === matchingCard.id) {
          const updated = { ...c };
          if (parseResult.balance !== undefined) updated.currentBalance = parseResult.balance;
          if (parseResult.apr) updated.apr = parseResult.apr;
          
          // Update spending caps with category totals
          if (parseResult.categoryTotals && c.spendingCaps) {
            updated.spendingCaps = c.spendingCaps.map(cap => {
              const categoryKey = cap.category.toLowerCase();
              if (parseResult.categoryTotals[categoryKey]) {
                return { ...cap, currentSpend: cap.currentSpend + parseResult.categoryTotals[categoryKey] };
              }
              return cap;
            });
          }

          // Update signup bonus progress
          if (parseResult.categoryTotals && c.signupBonus && !c.signupBonus.completed) {
            const totalSpend = Object.values(parseResult.categoryTotals).reduce((a, b) => a + b, 0);
            updated.signupBonus = {
              ...c.signupBonus,
              current: Math.min(c.signupBonus.target, c.signupBonus.current + totalSpend)
            };
            if (updated.signupBonus.current >= updated.signupBonus.target) {
              updated.signupBonus.completed = true;
            }
          }

          return updated;
        }
        return c;
      }));

      // Update points if rewards were earned
      if (parseResult.rewardsEarned && parseResult.rewardsType) {
        setPointsBalances(prev => ({
          ...prev,
          [parseResult.rewardsType]: (prev[parseResult.rewardsType] || 0) + parseResult.rewardsEarned
        }));
      }
    }

    setStatementText('');
    setParseResult(null);
  };

  const updateCard = (cardId, updates) => {
    setCards(cards.map(c => c.id === cardId ? { ...c, ...updates } : c));
  };

  const addCard = (newCard) => {
    const id = Math.max(...cards.map(c => c.id), 0) + 1;
    setCards([...cards, { ...newCard, id }]);
    setShowAddCard(false);
  };

  const deleteCard = (cardId) => {
    if (confirm('Are you sure you want to delete this card?')) {
      setCards(cards.filter(c => c.id !== cardId));
    }
  };

  const totalDebt = cards.reduce((sum, c) => sum + (c.currentBalance || 0), 0);
  const totalAnnualFees = cards.reduce((sum, c) => sum + (c.annualFee || 0), 0);
  const cardsWithBalance = cards.filter(c => c.currentBalance > 0).sort((a, b) => a.currentBalance - b.currentBalance);

  if (isLoading) {
    return (
      <div style={{
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #0f172a 100%)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontFamily: '"DM Sans", system-ui, sans-serif'
      }}>
        <div style={{ color: '#94a3b8', fontSize: '1.25rem' }}>Loading your cards...</div>
      </div>
    );
  }

  return (
    <div style={{
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #0f172a 100%)',
      fontFamily: '"DM Sans", system-ui, sans-serif',
      color: '#e2e8f0',
      display: 'flex'
    }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');
        
        * { box-sizing: border-box; }
        
        .card-hover:hover {
          transform: translateY(-2px);
          box-shadow: 0 20px 40px rgba(0,0,0,0.3);
        }
        
        .sidebar {
          width: 240px;
          min-width: 240px;
          height: 100vh;
          background: rgba(15, 23, 42, 0.95);
          border-right: 1px solid #334155;
          display: flex;
          flex-direction: column;
          padding: 0;
          overflow-y: auto;
          transition: width 0.2s ease, min-width 0.2s ease;
          position: sticky;
          top: 0;
        }

        .sidebar.collapsed {
          width: 64px;
          min-width: 64px;
        }

        .sidebar-group-label {
          font-size: 0.7rem;
          font-weight: 600;
          color: #475569;
          letter-spacing: 0.08em;
          text-transform: uppercase;
          padding: 20px 20px 6px;
        }

        .sidebar.collapsed .sidebar-group-label {
          visibility: hidden;
          height: 20px;
          padding: 20px 0 6px;
        }

        .sidebar-item {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 10px 20px;
          border: none;
          background: transparent;
          color: #94a3b8;
          font-size: 0.9rem;
          font-weight: 500;
          cursor: pointer;
          transition: all 0.15s;
          font-family: inherit;
          width: 100%;
          text-align: left;
          border-radius: 0;
          position: relative;
        }

        .sidebar.collapsed .sidebar-item {
          justify-content: center;
          padding: 10px;
        }

        .sidebar.collapsed .sidebar-item-label {
          display: none;
        }

        .sidebar-item:hover {
          background: rgba(51, 65, 85, 0.5);
          color: #e2e8f0;
        }

        .sidebar-item.active {
          background: rgba(245, 158, 11, 0.1);
          color: #f59e0b;
        }

        .sidebar-item.active::before {
          content: '';
          position: absolute;
          left: 0;
          top: 4px;
          bottom: 4px;
          width: 3px;
          background: #f59e0b;
          border-radius: 0 3px 3px 0;
        }

        .sidebar-icon {
          font-size: 1.15rem;
          width: 24px;
          text-align: center;
          flex-shrink: 0;
        }

        .sub-tab-bar {
          display: flex;
          gap: 4px;
          padding: 8px 16px;
          background: rgba(30, 41, 59, 0.5);
          border-bottom: 1px solid #334155;
          margin-bottom: 24px;
          border-radius: 0;
        }

        .sub-tab-btn {
          padding: 8px 16px;
          border: none;
          background: transparent;
          color: #64748b;
          font-size: 0.85rem;
          font-weight: 500;
          cursor: pointer;
          border-radius: 6px;
          transition: all 0.15s;
          font-family: inherit;
        }

        .sub-tab-btn:hover {
          color: #94a3b8;
          background: rgba(51, 65, 85, 0.3);
        }

        .sub-tab-btn.active {
          color: #f59e0b;
          background: rgba(245, 158, 11, 0.1);
        }

        .sidebar-toggle {
          background: transparent;
          border: none;
          color: #64748b;
          cursor: pointer;
          padding: 8px;
          font-size: 1.1rem;
          border-radius: 6px;
          transition: all 0.15s;
        }

        .sidebar-toggle:hover {
          color: #94a3b8;
          background: rgba(51, 65, 85, 0.3);
        }
        
        .progress-bar {
          height: 8px;
          background: #1e293b;
          border-radius: 4px;
          overflow: hidden;
        }
        
        .progress-fill {
          height: 100%;
          border-radius: 4px;
          transition: width 0.5s ease;
        }
        
        .btn-primary {
          background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
          color: #0f172a;
          border: none;
          padding: 10px 20px;
          border-radius: 8px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.2s;
          font-family: inherit;
        }
        
        .btn-primary:hover {
          transform: translateY(-1px);
          box-shadow: 0 4px 12px rgba(245, 158, 11, 0.3);
        }
        
        .btn-secondary {
          background: #334155;
          color: #e2e8f0;
          border: 1px solid #475569;
          padding: 10px 20px;
          border-radius: 8px;
          font-weight: 500;
          cursor: pointer;
          transition: all 0.2s;
          font-family: inherit;
        }
        
        .btn-secondary:hover {
          background: #3f4f63;
        }
        
        .input-field {
          background: #1e293b;
          border: 1px solid #334155;
          color: #e2e8f0;
          padding: 12px 16px;
          border-radius: 8px;
          font-size: 1rem;
          width: 100%;
          font-family: inherit;
        }
        
        .input-field:focus {
          outline: none;
          border-color: #f59e0b;
          box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.1);
        }
        
        .modal-overlay {
          position: fixed;
          inset: 0;
          background: rgba(0,0,0,0.7);
          display: flex;
          align-items: center;
          justify-content: center;
          z-index: 100;
          backdrop-filter: blur(4px);
        }
        
        .modal-content {
          background: #1e293b;
          border-radius: 16px;
          padding: 32px;
          max-width: 500px;
          width: 90%;
          border: 1px solid #334155;
        }
        
        textarea {
          font-family: 'JetBrains Mono', monospace;
          font-size: 0.85rem;
        }
      `}</style>

      {/* Sidebar */}
      <aside className={`sidebar ${sidebarCollapsed ? 'collapsed' : ''}`}>
        {/* Logo area */}
        <div style={{ padding: sidebarCollapsed ? '16px 8px' : '20px 20px 8px', display: 'flex', alignItems: 'center', justifyContent: sidebarCollapsed ? 'center' : 'space-between' }}>
          {!sidebarCollapsed && (
            <div style={{ display: 'flex', alignItems: 'center' }}>
              <PlastikLogo size={32} />
              <div>
                <div style={{
                  fontSize: '1.15rem',
                  fontWeight: 700,
                  background: 'linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%)',
                  WebkitBackgroundClip: 'text',
                  WebkitTextFillColor: 'transparent'
                }}>Plastik</div>
              </div>
            </div>
          )}
          {sidebarCollapsed && <PlastikLogo size={28} />}
          <button className="sidebar-toggle" onClick={() => setSidebarCollapsed(!sidebarCollapsed)} title={sidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}>
            {sidebarCollapsed ? '▶' : '◀'}
          </button>
        </div>

        {/* Nav groups */}
        <div style={{ flex: 1 }}>
          {['OVERVIEW', 'MANAGE'].map(group => (
            <div key={group}>
              <div className="sidebar-group-label">{group}</div>
              {sidebarSections.filter(s => s.group === group).map(section => (
                <button
                  key={section.id}
                  className={`sidebar-item ${activeSection === section.id ? 'active' : ''}`}
                  onClick={() => switchSection(section.id)}
                  title={sidebarCollapsed ? section.label : undefined}
                >
                  <span className="sidebar-icon">{section.icon}</span>
                  <span className="sidebar-item-label">{section.label}</span>
                </button>
              ))}
            </div>
          ))}
        </div>

        {/* Bottom section: Settings + Sync */}
        <div style={{ borderTop: '1px solid #334155', padding: '8px 0' }}>
          <button
            className={`sidebar-item`}
            onClick={() => setShowSettings(true)}
            title={sidebarCollapsed ? 'Settings' : undefined}
          >
            <span className="sidebar-icon">⚙</span>
            <span className="sidebar-item-label">Settings</span>
            {!sidebarCollapsed && (
              <span style={{
                width: '8px',
                height: '8px',
                borderRadius: '50%',
                background: apiKey ? '#22c55e' : '#ef4444',
                marginLeft: 'auto'
              }}></span>
            )}
          </button>
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: sidebarCollapsed ? 0 : '8px',
              justifyContent: sidebarCollapsed ? 'center' : 'flex-start',
              color: icloudStatus.available ? '#22c55e' : '#64748b',
              fontSize: '0.75rem',
              cursor: 'pointer',
              padding: sidebarCollapsed ? '8px' : '6px 20px',
            }}
            title={icloudStatus.available
              ? `iCloud synced${icloudStatus.lastSync ? ' • ' + new Date(icloudStatus.lastSync).toLocaleTimeString() : ''}`
              : 'iCloud not available'}
            onClick={() => {
              if (window.icloud) {
                window.icloud.syncNow().then(r => {
                  if (r.success) {
                    window.icloud.getStatus().then(setIcloudStatus);
                  }
                });
              }
            }}
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z"/>
            </svg>
            {!sidebarCollapsed && (icloudStatus.available ? 'Synced' : 'Local')}
          </div>
        </div>
      </aside>

      {/* Main Content Area */}
      <div style={{ flex: 1, overflowY: 'auto', height: '100vh' }}>
        {/* Sub-tab bar */}
        {activeSection !== 'settings' && (() => {
          const section = sidebarSections.find(s => s.id === activeSection);
          if (!section || section.subTabs.length <= 1) return null;
          const tabLabels = { dashboard: 'Dashboard', points: 'Points', payoff: 'Payoff', cards: 'My Cards', fees: 'Fees', applications: 'Applications', strategy: 'Strategy' };
          return (
            <div className="sub-tab-bar">
              {section.subTabs.map(tab => (
                <button
                  key={tab}
                  className={`sub-tab-btn ${activeTab === tab ? 'active' : ''}`}
                  onClick={() => setActiveTab(tab)}
                >
                  {tabLabels[tab] || tab.charAt(0).toUpperCase() + tab.slice(1)}
                </button>
              ))}
            </div>
          );
        })()}

      {/* Main Content */}
      <main style={{ maxWidth: '1400px', margin: '0 auto', padding: '32px' }}>
        
        {/* Dashboard Tab */}
        {activeTab === 'dashboard' && (
          <div>
            {/* Summary Cards */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '24px', marginBottom: '32px' }}>
              <div className="card-hover" style={{
                background: 'linear-gradient(135deg, #1e293b 0%, #334155 100%)',
                borderRadius: '16px',
                padding: '24px',
                border: '1px solid #475569',
                transition: 'all 0.3s'
              }}>
                <div style={{ color: '#94a3b8', fontSize: '0.9rem', marginBottom: '8px' }}>Total Cards</div>
                <div style={{ fontSize: '2.5rem', fontWeight: 700, color: '#f59e0b' }}>{cards.length}</div>
                <div style={{ color: '#64748b', fontSize: '0.85rem', marginTop: '8px' }}>
                  {holders.map((h, i) => `${cards.filter(c => c.holder === h).length} ${h}`).join(' / ')}
                </div>
              </div>

              <div className="card-hover" style={{
                background: 'linear-gradient(135deg, #1e293b 0%, #334155 100%)',
                borderRadius: '16px',
                padding: '24px',
                border: '1px solid #475569',
                transition: 'all 0.3s'
              }}>
                <div style={{ color: '#94a3b8', fontSize: '0.9rem', marginBottom: '8px' }}>Total Balance</div>
                <div style={{ fontSize: '2.5rem', fontWeight: 700, color: totalDebt > 0 ? '#ef4444' : '#22c55e' }}>
                  {formatCurrency(totalDebt)}
                </div>
                <div style={{ color: '#64748b', fontSize: '0.85rem', marginTop: '8px' }}>
                  Across {cardsWithBalance.length} cards
                </div>
              </div>

              <div className="card-hover" style={{
                background: 'linear-gradient(135deg, #1e293b 0%, #334155 100%)',
                borderRadius: '16px',
                padding: '24px',
                border: '1px solid #475569',
                transition: 'all 0.3s'
              }}>
                <div style={{ color: '#94a3b8', fontSize: '0.9rem', marginBottom: '8px' }}>Annual Fees</div>
                <div style={{ fontSize: '2.5rem', fontWeight: 700, color: '#e2e8f0' }}>
                  {formatCurrency(totalAnnualFees)}
                </div>
                <div style={{ color: '#64748b', fontSize: '0.85rem', marginTop: '8px' }}>
                  {cards.filter(c => c.annualFee > 0).length} cards with fees
                </div>
              </div>

              <div className="card-hover" style={{
                background: 'linear-gradient(135deg, #1e293b 0%, #334155 100%)',
                borderRadius: '16px',
                padding: '24px',
                border: '1px solid #475569',
                transition: 'all 0.3s'
              }}>
                <div style={{ color: '#94a3b8', fontSize: '0.9rem', marginBottom: '8px' }}>Chase 5/24 Status</div>
                <div style={{ fontSize: '2.5rem', fontWeight: 700, color: '#3b82f6' }}>
                  {cards.filter(c => {
                    const openDate = new Date(c.openDate);
                    const twoYearsAgo = new Date();
                    twoYearsAgo.setFullYear(twoYearsAgo.getFullYear() - 2);
                    return openDate > twoYearsAgo;
                  }).length}/5
                </div>
                <div style={{ color: '#64748b', fontSize: '0.85rem', marginTop: '8px' }}>
                  Cards opened in 24 months
                </div>
              </div>
            </div>

            {/* Companion Passes - Enhanced */}
            <CompanionPassSection
              companionPasses={companionPasses}
              setCompanionPasses={setCompanionPasses}
              cards={cards}
              holders={holders}
            />

            {/* Upcoming Actions */}
            <div>
              <h2 style={{ fontSize: '1.25rem', fontWeight: 600, marginBottom: '16px', color: '#f1f5f9' }}>
                Upcoming Actions
              </h2>
              <div style={{ background: '#1e293b', borderRadius: '12px', border: '1px solid #334155' }}>
                {cards
                  .filter(c => c.anniversaryDate || (c.signupBonus && !c.signupBonus.completed))
                  .sort((a, b) => {
                    const dateA = new Date(a.anniversaryDate || '2099-12-31');
                    const dateB = new Date(b.anniversaryDate || '2099-12-31');
                    return dateA - dateB;
                  })
                  .slice(0, 5)
                  .map((card, idx) => {
                    const daysToAnniversary = daysUntil(card.anniversaryDate);
                    return (
                      <div key={card.id} style={{
                        padding: '16px 20px',
                        borderBottom: idx < 4 ? '1px solid #334155' : 'none',
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center'
                      }}>
                        <div>
                          <div style={{ fontWeight: 500, color: '#f1f5f9' }}>
                            {card.issuer} {card.name}
                          </div>
                          <div style={{ color: '#64748b', fontSize: '0.85rem' }}>
                            {card.holder} • {card.annualFee > 0 ? formatCurrency(card.annualFee) + ' annual fee' : 'No annual fee'}
                          </div>
                        </div>
                        <div style={{ textAlign: 'right' }}>
                          <div style={{ color: daysToAnniversary < 30 ? '#f59e0b' : '#94a3b8', fontWeight: 500 }}>
                            {formatDate(card.anniversaryDate)}
                          </div>
                          <div style={{ color: '#64748b', fontSize: '0.85rem' }}>
                            {daysToAnniversary > 0 ? `${daysToAnniversary} days` : 'Past due'}
                          </div>
                        </div>
                      </div>
                    );
                  })}
              </div>
            </div>
          </div>
        )}

        {/* Cards Tab */}
        {activeTab === 'cards' && (
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
              <h2 style={{ fontSize: '1.5rem', fontWeight: 600, color: '#f1f5f9', margin: 0 }}>All Cards</h2>
              <button className="btn-primary" onClick={() => setShowAddCard(true)}>+ Add Card</button>
            </div>

            <div style={{ display: 'grid', gap: '16px' }}>
              {cards.map(card => (
                <div key={card.id} className="card-hover" style={{
                  background: '#1e293b',
                  borderRadius: '12px',
                  padding: '24px',
                  border: '1px solid #334155',
                  transition: 'all 0.3s'
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', marginBottom: '16px' }}>
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                        <h3 style={{ margin: 0, fontSize: '1.25rem', fontWeight: 600, color: '#f1f5f9' }}>
                          {card.issuer} {card.name}
                        </h3>
                        <span style={{
                          padding: '2px 10px',
                          borderRadius: '12px',
                          fontSize: '0.75rem',
                          fontWeight: 500,
                          background: getHolderColor(card.holder).bg,
                          color: getHolderColor(card.holder).text
                        }}>
                          {card.holder}
                        </span>
                      </div>
                      <div style={{ color: '#64748b', fontSize: '0.9rem', marginTop: '4px' }}>
                        Opened {formatDate(card.openDate)} • APR {card.apr}%
                      </div>
                    </div>
                    <div style={{ display: 'flex', gap: '8px' }}>
                      <button 
                        className="btn-secondary" 
                        style={{ padding: '8px 16px', fontSize: '0.85rem' }}
                        onClick={() => setEditingCard(card)}
                      >
                        Edit
                      </button>
                      <button 
                        className="btn-secondary" 
                        style={{ padding: '8px 16px', fontSize: '0.85rem', borderColor: '#7f1d1d', color: '#fca5a5' }}
                        onClick={() => deleteCard(card.id)}
                      >
                        Delete
                      </button>
                    </div>
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '20px' }}>
                    <div>
                      <div style={{ color: '#64748b', fontSize: '0.85rem' }}>Balance</div>
                      <div style={{ fontSize: '1.5rem', fontWeight: 600, color: card.currentBalance > 0 ? '#ef4444' : '#22c55e' }}>
                        {formatCurrency(card.currentBalance)}
                      </div>
                    </div>
                    <div>
                      <div style={{ color: '#64748b', fontSize: '0.85rem' }}>Annual Fee</div>
                      <div style={{ fontSize: '1.5rem', fontWeight: 600, color: '#e2e8f0' }}>
                        {formatCurrency(card.annualFee)}
                      </div>
                    </div>
                    <div>
                      <div style={{ color: '#64748b', fontSize: '0.85rem' }}>Anniversary</div>
                      <div style={{ fontSize: '1.1rem', fontWeight: 500, color: '#e2e8f0' }}>
                        {formatDate(card.anniversaryDate)}
                      </div>
                    </div>
                    <div>
                      <div style={{ color: '#64748b', fontSize: '0.85rem' }}>Churn Eligible</div>
                      <div style={{ fontSize: '1.1rem', fontWeight: 500, color: card.churnEligible ? '#e2e8f0' : '#64748b' }}>
                        {card.churnEligible ? formatDate(card.churnEligible) : 'Keep'}
                      </div>
                    </div>
                  </div>

                  {/* Signup Bonus Progress */}
                  {card.signupBonus && (
                    <div style={{ marginTop: '20px', padding: '16px', background: '#0f172a', borderRadius: '8px' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                        <span style={{ color: '#94a3b8', fontSize: '0.9rem' }}>Signup Bonus</span>
                        <span style={{
                          padding: '2px 8px',
                          borderRadius: '8px',
                          fontSize: '0.75rem',
                          background: card.signupBonus.completed ? '#166534' : '#7c2d12',
                          color: card.signupBonus.completed ? '#86efac' : '#fdba74'
                        }}>
                          {card.signupBonus.completed ? 'EARNED' : 'IN PROGRESS'}
                        </span>
                      </div>
                      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                        <span style={{ color: '#e2e8f0' }}>
                          {formatCurrency(card.signupBonus.current)} / {formatCurrency(card.signupBonus.target)}
                        </span>
                        <span style={{ color: '#f59e0b', fontWeight: 600 }}>
                          {card.signupBonus.reward.toLocaleString()} {card.signupBonus.rewardType}
                        </span>
                      </div>
                      <div className="progress-bar">
                        <div 
                          className="progress-fill" 
                          style={{ 
                            width: `${Math.min(100, (card.signupBonus.current / card.signupBonus.target) * 100)}%`,
                            background: card.signupBonus.completed 
                              ? 'linear-gradient(90deg, #22c55e 0%, #4ade80 100%)'
                              : 'linear-gradient(90deg, #f59e0b 0%, #fbbf24 100%)'
                          }} 
                        />
                      </div>
                    </div>
                  )}

                  {/* Spending Caps */}
                  {card.spendingCaps && card.spendingCaps.length > 0 && (
                    <div style={{ marginTop: '16px' }}>
                      <div style={{ color: '#94a3b8', fontSize: '0.85rem', marginBottom: '12px' }}>Spending Caps</div>
                      <div style={{ display: 'grid', gap: '12px' }}>
                        {card.spendingCaps.map((cap, idx) => (
                          <div key={idx} style={{ padding: '12px', background: '#0f172a', borderRadius: '8px' }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                              <span style={{ color: '#e2e8f0' }}>{cap.category} ({cap.rate}%)</span>
                              <span style={{ color: '#94a3b8' }}>
                                {formatCurrency(cap.currentSpend)} / {formatCurrency(cap.cap)}
                              </span>
                            </div>
                            <div className="progress-bar">
                              <div 
                                className="progress-fill" 
                                style={{ 
                                  width: `${Math.min(100, (cap.currentSpend / cap.cap) * 100)}%`,
                                  background: cap.currentSpend >= cap.cap 
                                    ? '#ef4444'
                                    : 'linear-gradient(90deg, #3b82f6 0%, #60a5fa 100%)'
                                }} 
                              />
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {card.notes && (
                    <div style={{ marginTop: '16px', padding: '12px', background: '#0f172a', borderRadius: '8px', color: '#94a3b8', fontSize: '0.9rem' }}>
                      📝 {card.notes}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Points Tab */}
        {activeTab === 'points' && (
          <div>
            <h2 style={{ fontSize: '1.5rem', fontWeight: 600, color: '#f1f5f9', marginBottom: '24px' }}>Points & Rewards Balances</h2>
            
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '20px' }}>
              {Object.entries(pointsBalances).filter(([_, val]) => val > 0 || ['Chase Ultimate Rewards', 'Southwest Rapid Rewards', 'Delta SkyMiles', 'United MileagePlus'].includes(_)).map(([type, balance]) => (
                <div key={type} className="card-hover" style={{
                  background: '#1e293b',
                  borderRadius: '12px',
                  padding: '24px',
                  border: '1px solid #334155',
                  transition: 'all 0.3s'
                }}>
                  <div style={{ color: '#94a3b8', fontSize: '0.9rem', marginBottom: '8px' }}>{type}</div>
                  <div style={{ display: 'flex', alignItems: 'baseline', gap: '8px' }}>
                    <span style={{ fontSize: '2.5rem', fontWeight: 700, color: '#f59e0b' }}>
                      {balance.toLocaleString()}
                    </span>
                    <span style={{ color: '#64748b' }}>
                      {type.includes('Cash') || type.includes('Rewards') && type.includes('Amazon') ? '$' : 'pts'}
                    </span>
                  </div>
                  {type === 'Amazon Rewards' && (
                    <div style={{ color: '#64748b', fontSize: '0.85rem', marginTop: '8px' }}>
                      ≈ {formatCurrency(balance / 100)} value
                    </div>
                  )}
                  <div style={{ marginTop: '16px' }}>
                    <input
                      type="number"
                      placeholder="Update balance..."
                      className="input-field"
                      style={{ fontSize: '0.9rem' }}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') {
                          setPointsBalances(prev => ({ ...prev, [type]: parseInt(e.target.value) || 0 }));
                          e.target.value = '';
                        }
                      }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Applications Tab */}
        {activeTab === 'applications' && (
          <ApplicationsTab 
            applications={applications}
            setApplications={setApplications}
            creditPulls={creditPulls}
            setCreditPulls={setCreditPulls}
            cards={cards}
            issuerRules={issuerRules}
            apiKey={apiKey}
          />
        )}

        {/* Annual Fees Tab */}
        {activeTab === 'fees' && (
          <AnnualFeesTab 
            cards={cards}
            setCards={setCards}
            downgradePaths={downgradePaths}
          />
        )}

        {/* Offers Tab (Placeholder) */}
        {activeTab === 'offers' && (
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
              <h2 style={{ margin: 0, fontSize: '1.5rem', fontWeight: 600 }}>Current Offers</h2>
            </div>
            <div style={{
              background: 'linear-gradient(135deg, #1e293b 0%, #334155 100%)',
              borderRadius: '16px',
              padding: '48px 32px',
              textAlign: 'center',
              border: '1px solid #334155'
            }}>
              <div style={{ fontSize: '3rem', marginBottom: '16px' }}>🏷</div>
              <h3 style={{ color: '#f1f5f9', fontSize: '1.25rem', marginBottom: '8px' }}>Offers Coming Soon</h3>
              <p style={{ color: '#64748b', fontSize: '0.95rem', maxWidth: '400px', margin: '0 auto' }}>
                Credit card signup offers and limited-time promotions will appear here once the data feed is connected.
              </p>
            </div>
          </div>
        )}

        {/* Import Tab */}
        {activeTab === 'import' && (
          <div>
            <h2 style={{ fontSize: '1.5rem', fontWeight: 600, color: '#f1f5f9', marginBottom: '8px' }}>Import Statement</h2>
            <p style={{ color: '#64748b', marginBottom: '24px' }}>
              Paste your statement text below and Claude will parse it to update your card data.
            </p>

            {!apiKey && (
              <div style={{
                background: '#7c2d12',
                border: '1px solid #f59e0b',
                borderRadius: '12px',
                padding: '20px',
                marginBottom: '24px'
              }}>
                <div style={{ fontWeight: 600, color: '#fbbf24', marginBottom: '8px' }}>API Key Required</div>
                <div style={{ color: '#fed7aa', marginBottom: '12px' }}>
                  To use the statement parsing feature, you need to add your Anthropic API key.
                </div>
                <button className="btn-primary" onClick={() => setShowSettings(true)}>
                  Add API Key
                </button>
              </div>
            )}

            <div style={{ display: 'grid', gap: '20px' }}>
              <div>
                <label style={{ display: 'block', color: '#94a3b8', marginBottom: '8px', fontSize: '0.9rem' }}>
                  Assign to Card
                </label>
                <select
                  className="input-field"
                  value={selectedImportCard}
                  onChange={(e) => setSelectedImportCard(e.target.value)}
                  style={{ maxWidth: '400px' }}
                >
                  <option value="">Auto-detect from statement</option>
                  {cards.map(c => (
                    <option key={c.id} value={c.id}>{c.issuer} {c.name}</option>
                  ))}
                </select>
              </div>

              <div>
                <label style={{ display: 'block', color: '#94a3b8', marginBottom: '8px', fontSize: '0.9rem' }}>
                  Statement Text (copy from PDF or online portal)
                </label>
                <textarea
                  className="input-field"
                  style={{ minHeight: '300px', resize: 'vertical' }}
                  placeholder="Paste your credit card statement text here..."
                  value={statementText}
                  onChange={(e) => setStatementText(e.target.value)}
                />
              </div>

              <div style={{ display: 'flex', gap: '12px' }}>
                <button 
                  className="btn-primary" 
                  onClick={parseStatement}
                  disabled={!apiKey || !statementText || parsing}
                  style={{ opacity: (!apiKey || !statementText || parsing) ? 0.5 : 1 }}
                >
                  {parsing ? 'Parsing...' : 'Parse Statement'}
                </button>
                <button 
                  className="btn-secondary"
                  onClick={() => { setStatementText(''); setParseResult(null); }}
                >
                  Clear
                </button>
              </div>

              {parseResult && (
                <div style={{
                  background: parseResult.error ? '#7f1d1d' : '#1e293b',
                  border: `1px solid ${parseResult.error ? '#ef4444' : '#334155'}`,
                  borderRadius: '12px',
                  padding: '24px'
                }}>
                  {parseResult.error ? (
                    <div>
                      <div style={{ fontWeight: 600, color: '#fca5a5', marginBottom: '8px' }}>Parse Error</div>
                      <div style={{ color: '#fed7aa' }}>{parseResult.error}</div>
                      {parseResult.raw && (
                        <pre style={{ marginTop: '12px', color: '#94a3b8', fontSize: '0.8rem', overflow: 'auto' }}>
                          {parseResult.raw}
                        </pre>
                      )}
                    </div>
                  ) : (
                    <div>
                      <div style={{ fontWeight: 600, color: '#22c55e', marginBottom: '16px' }}>✓ Statement Parsed Successfully</div>
                      
                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '16px', marginBottom: '20px' }}>
                        <div>
                          <div style={{ color: '#64748b', fontSize: '0.85rem' }}>Card</div>
                          <div style={{ color: '#e2e8f0', fontWeight: 500 }}>{parseResult.issuer} {parseResult.cardIdentifier}</div>
                        </div>
                        <div>
                          <div style={{ color: '#64748b', fontSize: '0.85rem' }}>Statement Date</div>
                          <div style={{ color: '#e2e8f0', fontWeight: 500 }}>{formatDate(parseResult.statementDate)}</div>
                        </div>
                        <div>
                          <div style={{ color: '#64748b', fontSize: '0.85rem' }}>Balance</div>
                          <div style={{ color: '#ef4444', fontWeight: 600, fontSize: '1.25rem' }}>{formatCurrency(parseResult.balance)}</div>
                        </div>
                        <div>
                          <div style={{ color: '#64748b', fontSize: '0.85rem' }}>APR</div>
                          <div style={{ color: '#e2e8f0', fontWeight: 500 }}>{parseResult.apr}%</div>
                        </div>
                      </div>

                      {parseResult.categoryTotals && (
                        <div style={{ marginBottom: '20px' }}>
                          <div style={{ color: '#94a3b8', fontSize: '0.9rem', marginBottom: '12px' }}>Spending by Category</div>
                          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '12px' }}>
                            {Object.entries(parseResult.categoryTotals).filter(([_, v]) => v > 0).map(([cat, amount]) => (
                              <div key={cat} style={{
                                background: '#0f172a',
                                padding: '8px 16px',
                                borderRadius: '8px'
                              }}>
                                <span style={{ color: '#94a3b8', textTransform: 'capitalize' }}>{cat}:</span>
                                <span style={{ color: '#e2e8f0', marginLeft: '8px', fontWeight: 500 }}>{formatCurrency(amount)}</span>
                              </div>
                            ))}
                          </div>
                        </div>
                      )}

                      <div style={{ display: 'flex', gap: '12px' }}>
                        <button className="btn-primary" onClick={applyParseResult}>
                          Apply to Card Data
                        </button>
                        <button className="btn-secondary" onClick={() => setParseResult(null)}>
                          Dismiss
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        )}

        {/* Payoff Tab */}
        {activeTab === 'payoff' && (
          <div>
            <h2 style={{ fontSize: '1.5rem', fontWeight: 600, color: '#f1f5f9', marginBottom: '8px' }}>Debt Payoff Strategy</h2>
            <p style={{ color: '#64748b', marginBottom: '24px' }}>
              Snowball method: Pay minimums on all cards, put extra toward smallest balance first.
            </p>

            {totalDebt === 0 ? (
              <div style={{
                background: '#14532d',
                border: '1px solid #22c55e',
                borderRadius: '12px',
                padding: '32px',
                textAlign: 'center'
              }}>
                <div style={{ fontSize: '3rem', marginBottom: '12px' }}>🎉</div>
                <div style={{ fontSize: '1.5rem', fontWeight: 600, color: '#86efac' }}>Debt Free!</div>
                <div style={{ color: '#bbf7d0', marginTop: '8px' }}>All card balances are at $0</div>
              </div>
            ) : (
              <div>
                <div style={{
                  background: '#1e293b',
                  borderRadius: '12px',
                  padding: '24px',
                  border: '1px solid #334155',
                  marginBottom: '24px'
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div>
                      <div style={{ color: '#94a3b8', fontSize: '0.9rem' }}>Total Debt</div>
                      <div style={{ fontSize: '2.5rem', fontWeight: 700, color: '#ef4444' }}>{formatCurrency(totalDebt)}</div>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <div style={{ color: '#94a3b8', fontSize: '0.9rem' }}>Cards with Balance</div>
                      <div style={{ fontSize: '2rem', fontWeight: 600, color: '#e2e8f0' }}>{cardsWithBalance.length}</div>
                    </div>
                  </div>
                </div>

                <h3 style={{ fontSize: '1.1rem', fontWeight: 600, color: '#f1f5f9', marginBottom: '16px' }}>
                  Snowball Order (Smallest to Largest)
                </h3>

                <div style={{ display: 'grid', gap: '12px' }}>
                  {cardsWithBalance.map((card, idx) => (
                    <div key={card.id} style={{
                      background: '#1e293b',
                      borderRadius: '12px',
                      padding: '20px',
                      border: idx === 0 ? '2px solid #f59e0b' : '1px solid #334155',
                      position: 'relative'
                    }}>
                      {idx === 0 && (
                        <div style={{
                          position: 'absolute',
                          top: '-10px',
                          right: '16px',
                          background: '#f59e0b',
                          color: '#0f172a',
                          padding: '4px 12px',
                          borderRadius: '12px',
                          fontSize: '0.75rem',
                          fontWeight: 700
                        }}>
                          FOCUS HERE
                        </div>
                      )}
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                          <div style={{
                            width: '40px',
                            height: '40px',
                            borderRadius: '50%',
                            background: idx === 0 ? '#f59e0b' : '#334155',
                            color: idx === 0 ? '#0f172a' : '#94a3b8',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontWeight: 700
                          }}>
                            {idx + 1}
                          </div>
                          <div>
                            <div style={{ fontWeight: 600, color: '#f1f5f9' }}>{card.issuer} {card.name}</div>
                            <div style={{ color: '#64748b', fontSize: '0.85rem' }}>
                              {card.holder} • {card.apr}% APR
                            </div>
                          </div>
                        </div>
                        <div style={{ textAlign: 'right' }}>
                          <div style={{ fontSize: '1.5rem', fontWeight: 700, color: '#ef4444' }}>
                            {formatCurrency(card.currentBalance)}
                          </div>
                          <div style={{ color: '#64748b', fontSize: '0.85rem' }}>
                            ~{formatCurrency(card.currentBalance * (card.apr / 100 / 12))} interest/mo
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>

                <div style={{ marginTop: '24px', padding: '20px', background: '#0f172a', borderRadius: '12px' }}>
                  <h4 style={{ color: '#f1f5f9', marginBottom: '12px' }}>Quick Balance Update</h4>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '12px' }}>
                    {cardsWithBalance.map(card => (
                      <div key={card.id} style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                        <label style={{ color: '#94a3b8', fontSize: '0.85rem', minWidth: '150px' }}>
                          {card.issuer} {card.name}:
                        </label>
                        <input
                          type="number"
                          className="input-field"
                          style={{ flex: 1, padding: '8px 12px' }}
                          defaultValue={card.currentBalance}
                          onBlur={(e) => updateCard(card.id, { currentBalance: parseFloat(e.target.value) || 0 })}
                        />
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Strategy Tab */}
        {activeTab === 'strategy' && (
          <StrategyTab 
            cards={cards} 
            pointsBalances={pointsBalances}
            applications={applications}
            apiKey={apiKey}
            setShowSettings={setShowSettings}
            issuerRules={issuerRules}
          />
        )}
      </main>

      {/* Settings Modal */}
      {showSettings && (
        <div className="modal-overlay" onClick={() => setShowSettings(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: '500px' }}>
            <h3 style={{ margin: '0 0 24px', color: '#f1f5f9', fontSize: '1.25rem' }}>Settings</h3>

            {/* Account Holders Section */}
            <div style={{ marginBottom: '24px' }}>
              <h4 style={{ color: '#94a3b8', fontSize: '0.85rem', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '12px' }}>Account Holders</h4>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '12px' }}>
                {holders.map((holder, idx) => (
                  <div key={idx} style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <span style={{
                      width: '8px', height: '8px', borderRadius: '50%',
                      background: holderColors[idx % holderColors.length].text,
                      flexShrink: 0
                    }}></span>
                    <span style={{ color: '#f1f5f9', flex: 1 }}>{holder}</span>
                    {holders.length > 1 && (
                      <button
                        onClick={() => setHolders(holders.filter((_, i) => i !== idx))}
                        style={{
                          background: 'none', border: 'none', color: '#ef4444', cursor: 'pointer',
                          fontSize: '1.1rem', padding: '2px 6px', borderRadius: '4px'
                        }}
                        onMouseOver={e => e.target.style.background = '#7f1d1d'}
                        onMouseOut={e => e.target.style.background = 'none'}
                      >
                        ×
                      </button>
                    )}
                  </div>
                ))}
              </div>
              <div style={{ display: 'flex', gap: '8px' }}>
                <input
                  type="text"
                  className="input-field"
                  placeholder="New holder name..."
                  value={newHolderName}
                  onChange={(e) => setNewHolderName(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' && newHolderName.trim()) {
                      setHolders([...holders, newHolderName.trim()]);
                      setNewHolderName('');
                    }
                  }}
                  style={{ flex: 1 }}
                />
                <button
                  className="btn-primary"
                  style={{ padding: '8px 16px' }}
                  onClick={() => {
                    if (newHolderName.trim()) {
                      setHolders([...holders, newHolderName.trim()]);
                      setNewHolderName('');
                    }
                  }}
                >
                  Add
                </button>
              </div>
            </div>

            {/* API Key Section */}
            <div style={{ borderTop: '1px solid #334155', paddingTop: '20px' }}>
              <h4 style={{ color: '#94a3b8', fontSize: '0.85rem', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '12px' }}>Anthropic API Key</h4>
              <p style={{ color: '#64748b', marginBottom: '12px', fontSize: '0.85rem' }}>
                Stored locally. Used only for statement parsing and strategy analysis.
              </p>
              <input
                id="settings-api-key"
                type="password"
                className="input-field"
                placeholder="sk-ant-..."
                defaultValue={apiKey}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') saveApiKey(e.target.value);
                }}
              />
              <button
                className="btn-secondary"
                style={{ marginTop: '8px', padding: '6px 16px', fontSize: '0.85rem' }}
                onClick={() => {
                  const input = document.getElementById('settings-api-key');
                  if (input) saveApiKey(input.value);
                }}
              >
                {apiKey ? 'Update Key' : 'Save Key'}
              </button>
            </div>

            {/* Close Button */}
            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '24px', borderTop: '1px solid #334155', paddingTop: '16px' }}>
              <button className="btn-primary" onClick={() => setShowSettings(false)}>
                Done
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Edit Card Modal */}
      {editingCard && (
        <div className="modal-overlay" onClick={() => setEditingCard(null)}>
          <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: '600px' }}>
            <h3 style={{ margin: '0 0 20px', color: '#f1f5f9' }}>Edit {editingCard.issuer} {editingCard.name}</h3>

            <div style={{ display: 'grid', gap: '16px' }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div>
                  <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Card Name</label>
                  <input
                    type="text"
                    className="input-field"
                    defaultValue={editingCard.name}
                    onChange={(e) => setEditingCard({ ...editingCard, name: e.target.value })}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Issuer</label>
                  <input
                    type="text"
                    className="input-field"
                    defaultValue={editingCard.issuer}
                    onChange={(e) => setEditingCard({ ...editingCard, issuer: e.target.value })}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div>
                  <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Balance</label>
                  <input
                    type="number"
                    className="input-field"
                    defaultValue={editingCard.currentBalance}
                    onChange={(e) => setEditingCard({ ...editingCard, currentBalance: parseFloat(e.target.value) || 0 })}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>APR %</label>
                  <input
                    type="number"
                    step="0.01"
                    className="input-field"
                    defaultValue={editingCard.apr}
                    onChange={(e) => setEditingCard({ ...editingCard, apr: parseFloat(e.target.value) || 0 })}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div>
                  <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Annual Fee</label>
                  <input
                    type="number"
                    className="input-field"
                    defaultValue={editingCard.annualFee}
                    onChange={(e) => setEditingCard({ ...editingCard, annualFee: parseFloat(e.target.value) || 0 })}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Credit Limit</label>
                  <input
                    type="number"
                    className="input-field"
                    defaultValue={editingCard.creditLimit || 0}
                    onChange={(e) => setEditingCard({ ...editingCard, creditLimit: parseFloat(e.target.value) || 0 })}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div>
                  <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Holder</label>
                  <select
                    className="input-field"
                    defaultValue={editingCard.holder}
                    onChange={(e) => setEditingCard({ ...editingCard, holder: e.target.value })}
                  >
                    {holders.map(h => <option key={h} value={h}>{h}</option>)}
                  </select>
                </div>
              </div>

              <div>
                <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Notes</label>
                <textarea
                  className="input-field"
                  style={{ minHeight: '80px' }}
                  defaultValue={editingCard.notes}
                  onChange={(e) => setEditingCard({ ...editingCard, notes: e.target.value })}
                />
              </div>
            </div>

            <div style={{ display: 'flex', gap: '12px', marginTop: '24px' }}>
              <button 
                className="btn-primary"
                onClick={() => {
                  updateCard(editingCard.id, editingCard);
                  setEditingCard(null);
                }}
              >
                Save Changes
              </button>
              <button className="btn-secondary" onClick={() => setEditingCard(null)}>
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Add Card Modal */}
      {showAddCard && (
        <div className="modal-overlay" onClick={() => setShowAddCard(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: '600px' }}>
            <h3 style={{ margin: '0 0 20px', color: '#f1f5f9' }}>Add New Card</h3>
            
            <form onSubmit={(e) => {
              e.preventDefault();
              const form = e.target;
              addCard({
                name: form.name.value,
                issuer: form.issuer.value,
                holder: form.holder.value,
                annualFee: parseFloat(form.annualFee.value) || 0,
                apr: parseFloat(form.apr.value) || 0,
                creditLimit: parseFloat(form.creditLimit.value) || 0,
                currentBalance: 0,
                openDate: form.openDate.value,
                anniversaryDate: form.openDate.value,
                signupBonus: form.signupTarget.value ? {
                  target: parseFloat(form.signupTarget.value),
                  current: 0,
                  reward: parseFloat(form.signupReward.value) || 0,
                  rewardType: form.rewardType.value,
                  completed: false
                } : null,
                spendingCaps: [],
                churnEligible: null,
                pointsType: form.pointsType.value || null,
                notes: form.notes.value
              });
            }}>
              <div style={{ display: 'grid', gap: '16px' }}>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Card Name *</label>
                    <input name="name" required className="input-field" placeholder="Sapphire Preferred" />
                  </div>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Issuer *</label>
                    <input name="issuer" required className="input-field" placeholder="Chase" />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Holder</label>
                    <select name="holder" className="input-field">
                      {holders.map(h => <option key={h} value={h}>{h}</option>)}
                    </select>
                  </div>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Credit Limit</label>
                    <input name="creditLimit" type="number" className="input-field" placeholder="10000" />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Annual Fee</label>
                    <input name="annualFee" type="number" className="input-field" placeholder="95" />
                  </div>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>APR %</label>
                    <input name="apr" type="number" step="0.01" className="input-field" placeholder="21.99" />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Open Date</label>
                    <input name="openDate" type="date" className="input-field" />
                  </div>
                  <div>
                    <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Points Type</label>
                    <input name="pointsType" className="input-field" placeholder="Chase Ultimate Rewards" />
                  </div>
                </div>

                <div style={{ borderTop: '1px solid #334155', paddingTop: '16px' }}>
                  <div style={{ color: '#94a3b8', fontSize: '0.9rem', marginBottom: '12px' }}>Signup Bonus (optional)</div>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px' }}>
                    <div>
                      <label style={{ display: 'block', color: '#64748b', marginBottom: '6px', fontSize: '0.8rem' }}>Spend Target</label>
                      <input name="signupTarget" type="number" className="input-field" placeholder="4000" />
                    </div>
                    <div>
                      <label style={{ display: 'block', color: '#64748b', marginBottom: '6px', fontSize: '0.8rem' }}>Reward Amount</label>
                      <input name="signupReward" type="number" className="input-field" placeholder="60000" />
                    </div>
                    <div>
                      <label style={{ display: 'block', color: '#64748b', marginBottom: '6px', fontSize: '0.8rem' }}>Reward Type</label>
                      <input name="rewardType" className="input-field" placeholder="Ultimate Rewards" />
                    </div>
                  </div>
                </div>

                <div>
                  <label style={{ display: 'block', color: '#94a3b8', marginBottom: '6px', fontSize: '0.85rem' }}>Notes</label>
                  <textarea name="notes" className="input-field" style={{ minHeight: '60px' }} placeholder="Card benefits, category bonuses, etc." />
                </div>
              </div>

              <div style={{ display: 'flex', gap: '12px', marginTop: '24px' }}>
                <button type="submit" className="btn-primary">Add Card</button>
                <button type="button" className="btn-secondary" onClick={() => setShowAddCard(false)}>Cancel</button>
              </div>
            </form>
          </div>
        </div>
      )}
      </div>{/* end main content wrapper */}
    </div>
  );
}
