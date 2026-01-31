import Foundation

struct IssuerRule: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let window: Int?
    let limit: Int?
    let scope: String?
    let unit: String?

    init(name: String, description: String, window: Int? = nil, limit: Int? = nil, scope: String? = nil, unit: String? = nil) {
        self.name = name
        self.description = description
        self.window = window
        self.limit = limit
        self.scope = scope
        self.unit = unit
    }
}

struct IssuerInfo: Identifiable {
    let id = UUID()
    let name: String
    let rules: [IssuerRule]
    let pullsBureau: [String]
    let notes: String
}

enum IssuerRules {
    static let all: [IssuerInfo] = [
        IssuerInfo(
            name: "Chase",
            rules: [
                IssuerRule(name: "5/24", description: "Cannot approve if 5+ cards opened in 24 months (any issuer)", window: 24, limit: 5, scope: "all_issuers"),
                IssuerRule(name: "1/30", description: "Only 1 personal card approval per 30 days", window: 1, limit: 1, scope: "personal", unit: "months"),
                IssuerRule(name: "2/30 Business", description: "Max 2 business cards per 30 days", window: 1, limit: 2, scope: "business", unit: "months"),
                IssuerRule(name: "Sapphire 48-month", description: "No Sapphire bonus if received one in past 48 months", window: 48, scope: "sapphire_family"),
                IssuerRule(name: "CL Cap", description: "Total Chase CL typically capped at 50% of income", scope: "credit_limit")
            ],
            pullsBureau: ["Experian", "Equifax"],
            notes: "Generally most valuable cards to get first due to 5/24. Can sometimes combine hard pulls same day."
        ),
        IssuerInfo(
            name: "Amex",
            rules: [
                IssuerRule(name: "Once Per Lifetime", description: "Signup bonus only once per card product ever (with some exceptions)", scope: "bonus"),
                IssuerRule(name: "1/5", description: "Max 1 credit card per 5 days", window: 5, limit: 1, scope: "credit", unit: "days"),
                IssuerRule(name: "2/90", description: "Max 2 credit cards per 90 days", window: 90, limit: 2, scope: "credit", unit: "days"),
                IssuerRule(name: "4-5 Credit Card Limit", description: "Max 4-5 Amex credit cards at once (charge cards unlimited)", scope: "total"),
                IssuerRule(name: "NLL Offers", description: "No Lifetime Language offers via targeted links bypass once-per-lifetime", scope: "exception")
            ],
            pullsBureau: ["Experian"],
            notes: "Soft pull for existing customers. Business cards don't report to personal credit. Watch for NLL offers."
        ),
        IssuerInfo(
            name: "Citi",
            rules: [
                IssuerRule(name: "1/8", description: "Only 1 application per 8 days", window: 8, limit: 1, unit: "days"),
                IssuerRule(name: "2/65", description: "Max 2 approvals per 65 days", window: 65, limit: 2, unit: "days"),
                IssuerRule(name: "1/24 Same Family", description: "No bonus on same card family within 24 months", window: 24, scope: "family"),
                IssuerRule(name: "6/6", description: "May deny if 6+ inquiries in 6 months", window: 6, limit: 6, scope: "inquiries")
            ],
            pullsBureau: ["Experian", "Equifax", "TransUnion"],
            notes: "Known for matching signup bonuses via SM. AA cards have been churnable historically."
        ),
        IssuerInfo(
            name: "Capital One",
            rules: [
                IssuerRule(name: "1/6 Months", description: "Generally 1 card per 6 months", window: 6, limit: 1, unit: "months"),
                IssuerRule(name: "Inquiry Sensitive", description: "May deny with many recent inquiries", scope: "inquiries"),
                IssuerRule(name: "3 Bureau Pull", description: "Pulls all 3 bureaus for new customers", scope: "pull")
            ],
            pullsBureau: ["Experian", "Equifax", "TransUnion"],
            notes: "All 3 bureau pulls hurt. Venture X has been more lenient. Can PC between Venture cards."
        ),
        IssuerInfo(
            name: "Bank of America",
            rules: [
                IssuerRule(name: "2/3/4", description: "2 cards per 2 months, 3 per 12 months, 4 per 24 months", scope: "velocity"),
                IssuerRule(name: "7/12", description: "Max 7 cards per 12 months across all issuers", window: 12, limit: 7, scope: "all_issuers"),
                IssuerRule(name: "Preferred Rewards", description: "Better bonuses with $100k+ in BoA/Merrill accounts", scope: "relationship")
            ],
            pullsBureau: ["Experian"],
            notes: "Relationship helps a lot. Alaska cards are popular for companion fare."
        ),
        IssuerInfo(
            name: "Barclays",
            rules: [
                IssuerRule(name: "6/24 Sensitive", description: "May deny if 6+ cards in 24 months", window: 24, limit: 6, scope: "all_issuers"),
                IssuerRule(name: "1/6", description: "One Barclays card per 6 months recommended", window: 6, limit: 1, unit: "months")
            ],
            pullsBureau: ["TransUnion"],
            notes: "AA Aviator is popular. JetBlue cards available. Known for recon success."
        ),
        IssuerInfo(
            name: "US Bank",
            rules: [
                IssuerRule(name: "Inquiry Sensitive", description: "Very sensitive to recent inquiries", scope: "inquiries"),
                IssuerRule(name: "Relationship Helps", description: "Checking account significantly improves approval odds", scope: "relationship"),
                IssuerRule(name: "0/12 Preference", description: "Prefers 0-1 new cards in past 12 months", window: 12, limit: 1, scope: "preference")
            ],
            pullsBureau: ["TransUnion", "Experian"],
            notes: "Altitude Reserve/Connect are valuable. Open checking first if no relationship."
        ),
        IssuerInfo(
            name: "Wells Fargo",
            rules: [
                IssuerRule(name: "15/12", description: "May deny with 15+ inquiries in 12 months", window: 12, limit: 15, scope: "inquiries"),
                IssuerRule(name: "Cell Phone Protection", description: "Autograph has cell phone protection benefit", scope: "benefit")
            ],
            pullsBureau: ["Experian"],
            notes: "Autograph is their main rewards card. Not as churnable as others."
        ),
        IssuerInfo(
            name: "Goldman Sachs",
            rules: [
                IssuerRule(name: "Apple Ecosystem", description: "Apple Card is only product currently", scope: "product")
            ],
            pullsBureau: ["TransUnion"],
            notes: "Apple Card - 3% on Apple, 2% Apple Pay. No traditional signup bonus."
        )
    ]
}
