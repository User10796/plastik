import Foundation

struct PopularCard: Identifiable {
    let id = UUID()
    let name: String
    let issuer: String
    let annualFee: Double
    let signupBonus: Double
    let signupSpend: Double
    let signupMonths: Int
    let rewardType: String
    let pointValue: Double
    let categories: String
    let bestFor: String
    let churnWindow: Int
    let notes: String
}

enum PopularCards {
    static let all: [PopularCard] = [
        PopularCard(name: "Sapphire Preferred", issuer: "Chase", annualFee: 95, signupBonus: 60000, signupSpend: 4000, signupMonths: 3, rewardType: "Ultimate Rewards", pointValue: 0.02, categories: "3x dining, 3x streaming, 2x travel, 5x Lyft", bestFor: "Travel redemptions via transfer partners", churnWindow: 48, notes: "Cannot have Sapphire bonus in past 48 months"),
        PopularCard(name: "Sapphire Reserve", issuer: "Chase", annualFee: 550, signupBonus: 60000, signupSpend: 4000, signupMonths: 3, rewardType: "Ultimate Rewards", pointValue: 0.02, categories: "3x dining, 3x travel, 10x hotels/car via portal", bestFor: "Heavy travelers, $300 travel credit, Priority Pass", churnWindow: 48, notes: "Cannot have Sapphire bonus in past 48 months"),
        PopularCard(name: "Ink Business Preferred", issuer: "Chase", annualFee: 95, signupBonus: 100000, signupSpend: 8000, signupMonths: 3, rewardType: "Ultimate Rewards", pointValue: 0.02, categories: "3x travel, shipping, internet, advertising", bestFor: "Business expenses, high SUB", churnWindow: 24, notes: "Business card - does not count toward 5/24"),
        PopularCard(name: "Freedom Unlimited", issuer: "Chase", annualFee: 0, signupBonus: 20000, signupSpend: 500, signupMonths: 3, rewardType: "Ultimate Rewards", pointValue: 0.02, categories: "1.5% everything, 3% dining/drugstores, 5% travel via portal", bestFor: "Everyday spend, pairs with Sapphire", churnWindow: 24, notes: "Keep long-term for UR earning"),
        PopularCard(name: "World of Hyatt", issuer: "Chase", annualFee: 95, signupBonus: 60000, signupSpend: 6000, signupMonths: 6, rewardType: "Hyatt Points", pointValue: 0.017, categories: "4x Hyatt, 2x dining/fitness/transit", bestFor: "Hyatt loyalists, free night annually", churnWindow: 24, notes: "One of best hotel cards for value"),
        PopularCard(name: "United Explorer", issuer: "Chase", annualFee: 95, signupBonus: 60000, signupSpend: 3000, signupMonths: 3, rewardType: "United Miles", pointValue: 0.012, categories: "2x United, dining, hotel", bestFor: "United flyers, free checked bag", churnWindow: 24, notes: "Often has elevated offers 70-80k"),
        PopularCard(name: "Southwest Priority", issuer: "Chase", annualFee: 149, signupBonus: 50000, signupSpend: 3000, signupMonths: 3, rewardType: "Rapid Rewards", pointValue: 0.014, categories: "2x Southwest, Rapid Rewards partners", bestFor: "Companion Pass pursuit, $75 SW credit", churnWindow: 24, notes: "Key card for Companion Pass strategy"),
        PopularCard(name: "Gold Card", issuer: "Amex", annualFee: 250, signupBonus: 60000, signupSpend: 6000, signupMonths: 6, rewardType: "Membership Rewards", pointValue: 0.02, categories: "4x dining, 4x groceries (up to $25k)", bestFor: "Dining/groceries, $120 dining credit, $120 Uber", churnWindow: 84, notes: "Once per lifetime rule - keep or never get again"),
        PopularCard(name: "Platinum Card", issuer: "Amex", annualFee: 695, signupBonus: 80000, signupSpend: 8000, signupMonths: 6, rewardType: "Membership Rewards", pointValue: 0.02, categories: "5x flights, 5x hotels via Amex Travel", bestFor: "Lounge access, travel credits, status", churnWindow: 84, notes: "Once per lifetime - many statement credits offset fee"),
        PopularCard(name: "Blue Cash Preferred", issuer: "Amex", annualFee: 95, signupBonus: 350, signupSpend: 3000, signupMonths: 6, rewardType: "Cash Back", pointValue: 1, categories: "6% groceries (up to $6k), 6% streaming, 3% gas", bestFor: "Families with high grocery spend", churnWindow: 84, notes: "Cash back card - once per lifetime"),
        PopularCard(name: "Delta SkyMiles Gold", issuer: "Amex", annualFee: 150, signupBonus: 70000, signupSpend: 3000, signupMonths: 6, rewardType: "Delta SkyMiles", pointValue: 0.012, categories: "2x Delta, dining, groceries", bestFor: "Delta flyers, first checked bag free", churnWindow: 84, notes: "Can churn between personal/business versions"),
        PopularCard(name: "Venture X", issuer: "Capital One", annualFee: 395, signupBonus: 75000, signupSpend: 4000, signupMonths: 3, rewardType: "Capital One Miles", pointValue: 0.01, categories: "2x everything, 10x hotels/car via portal", bestFor: "Lounge access, $300 travel credit, easy 2x", churnWindow: 48, notes: "No 5/24 equivalent - easier approval"),
        PopularCard(name: "Venture", issuer: "Capital One", annualFee: 95, signupBonus: 75000, signupSpend: 4000, signupMonths: 3, rewardType: "Capital One Miles", pointValue: 0.01, categories: "2x everything, 5x hotels/car via portal", bestFor: "Simple 2x earning, transfer partners", churnWindow: 48, notes: "Good for those over 5/24"),
        PopularCard(name: "Citi Premier", issuer: "Citi", annualFee: 95, signupBonus: 60000, signupSpend: 4000, signupMonths: 3, rewardType: "ThankYou Points", pointValue: 0.017, categories: "3x dining, groceries, gas, travel, hotels", bestFor: "Broad 3x categories, transfer partners", churnWindow: 24, notes: "24 month rule between Citi bonuses")
    ]
}
