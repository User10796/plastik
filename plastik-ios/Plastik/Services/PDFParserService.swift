import Foundation
import Vision
import Compression
#if canImport(PDFKit)
import PDFKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

// MARK: - Import Source Type

enum ImportSourceType: String {
    case pdfFile = "PDF"
    case csvFile = "CSV"
    case excelFile = "Excel"
    case pastedText = "Text"

    var icon: String {
        switch self {
        case .pdfFile: return "doc.fill"
        case .csvFile: return "tablecells"
        case .excelFile: return "tablecells.fill"
        case .pastedText: return "doc.text"
        }
    }
}

// MARK: - Parsed Statement

struct ParsedStatement: Identifiable {
    let id = UUID()
    var detectedIssuer: Issuer?
    var detectedCardName: String?
    var statementPeriodStart: Date?
    var statementPeriodEnd: Date?
    var previousBalance: Double?
    var paymentsReceived: Double?
    var newCharges: Double?
    var currentBalance: Double
    var minimumPayment: Double?
    var paymentDueDate: Date?
    var apr: Double?
    let transactions: [ParsedTransaction]
    var detectedBenefits: [DetectedBenefit]
    var confidence: Double  // 0-1, how confident parser is in results
    var sourceType: ImportSourceType
    var sourceFileName: String?
    let cardLastFour: String?

    // Legacy computed properties for compatibility
    var totalSpend: Double { transactions.reduce(0) { $0 + $1.amount } }
    var statementDate: Date? { statementPeriodEnd }

    var statementPeriodFormatted: String {
        guard let start = statementPeriodStart, let end = statementPeriodEnd else {
            return "Unknown period"
        }
        return "\(start.formatted(.dateTime.month(.abbreviated).day())) – \(end.formatted(.dateTime.month(.abbreviated).day().year()))"
    }

    var transactionCount: Int { transactions.count }

    // Convenience initializer for simple parsing results
    init(transactions: [ParsedTransaction], totalSpend: Double, statementDate: Date?, cardLastFour: String?) {
        self.transactions = transactions
        self.currentBalance = totalSpend
        self.statementPeriodEnd = statementDate
        self.cardLastFour = cardLastFour
        self.detectedBenefits = []
        self.confidence = 0.5
        self.sourceType = .pdfFile
    }

    // Full initializer
    init(detectedIssuer: Issuer?, detectedCardName: String?, statementPeriodStart: Date?, statementPeriodEnd: Date?, previousBalance: Double?, paymentsReceived: Double?, newCharges: Double?, currentBalance: Double, minimumPayment: Double?, paymentDueDate: Date?, apr: Double?, transactions: [ParsedTransaction], detectedBenefits: [DetectedBenefit], confidence: Double, sourceType: ImportSourceType, sourceFileName: String?, cardLastFour: String? = nil) {
        self.detectedIssuer = detectedIssuer
        self.detectedCardName = detectedCardName
        self.statementPeriodStart = statementPeriodStart
        self.statementPeriodEnd = statementPeriodEnd
        self.previousBalance = previousBalance
        self.paymentsReceived = paymentsReceived
        self.newCharges = newCharges
        self.currentBalance = currentBalance
        self.minimumPayment = minimumPayment
        self.paymentDueDate = paymentDueDate
        self.apr = apr
        self.transactions = transactions
        self.detectedBenefits = detectedBenefits
        self.confidence = confidence
        self.sourceType = sourceType
        self.sourceFileName = sourceFileName
        self.cardLastFour = cardLastFour
    }
}

// MARK: - Parsed Transaction

struct ParsedTransaction: Identifiable {
    let id = UUID()
    let date: Date?
    let description: String
    let amount: Double
    let category: SpendCategory?
    var merchant: String?

    var isCredit: Bool { amount < 0 }

    init(date: Date?, description: String, amount: Double, category: SpendCategory?, merchant: String? = nil) {
        self.date = date
        self.description = description
        self.amount = amount
        self.category = category
        self.merchant = merchant
    }
}

// MARK: - Detected Benefit

struct DetectedBenefit: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let type: BenefitType

    enum BenefitType: String {
        case credit = "Credit"
        case earning = "Earning"
        case cap = "Cap Usage"
    }
}

// MARK: - Import State

enum ImportState: Equatable {
    case idle
    case processing(progress: Double, status: String)
    case preview(ParsedStatement)
    case success(cardName: String, transactionCount: Int, bonusProgressUpdate: Int?)
    case error(String)

    static func == (lhs: ImportState, rhs: ImportState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.processing(let p1, let s1), .processing(let p2, let s2)): return p1 == p2 && s1 == s2
        case (.preview, .preview): return true
        case (.success(let c1, let t1, let b1), .success(let c2, let t2, let b2)): return c1 == c2 && t1 == t2 && b1 == b2
        case (.error(let e1), .error(let e2)): return e1 == e2
        default: return false
        }
    }
}

// MARK: - Import History Item

struct ImportHistoryItem: Identifiable, Codable {
    let id: UUID
    let filename: String
    let sourceType: String  // "PDF", "CSV", "Text"
    let date: Date
    let cardId: String
    let cardName: String
    let issuerName: String
    let transactionsImported: Int
    let balance: Double?

    init(filename: String, sourceType: ImportSourceType, cardId: String, cardName: String, issuerName: String, transactionsImported: Int, balance: Double?) {
        self.id = UUID()
        self.filename = filename
        self.sourceType = sourceType.rawValue
        self.date = Date()
        self.cardId = cardId
        self.cardName = cardName
        self.issuerName = issuerName
        self.transactionsImported = transactionsImported
        self.balance = balance
    }
}

// MARK: - Statement Parser (for text/CSV parsing)

class StatementParser {

    /// Parses text or CSV content into a ParsedStatement
    static func parse(text: String, sourceType: ImportSourceType, fileName: String?) -> ParsedStatement {
        // Detect issuer from content
        let detectedIssuer = detectIssuer(from: text)
        let detectedCard = detectCardName(from: text)

        // Parse actual transactions from text
        let transactions = parseTransactions(from: text, sourceType: sourceType)

        // Extract balance information
        let balanceInfo = extractBalanceInfo(from: text)

        // Detect benefits if any mentioned
        let benefits = detectBenefits(from: text)

        let totalCharges = transactions.filter { !$0.isCredit }.reduce(0) { $0 + $1.amount }
        let currentBalance = balanceInfo.currentBalance ?? totalCharges

        // Determine confidence based on what we found
        let confidence: Double
        if transactions.isEmpty {
            confidence = 0.3  // Low confidence if no transactions found
        } else if detectedIssuer != nil {
            confidence = 0.85
        } else {
            confidence = 0.6
        }

        return ParsedStatement(
            detectedIssuer: detectedIssuer,
            detectedCardName: detectedCard,
            statementPeriodStart: balanceInfo.periodStart,
            statementPeriodEnd: balanceInfo.periodEnd,
            previousBalance: balanceInfo.previousBalance,
            paymentsReceived: balanceInfo.payments,
            newCharges: totalCharges,
            currentBalance: currentBalance,
            minimumPayment: balanceInfo.minimumPayment,
            paymentDueDate: balanceInfo.dueDate,
            apr: balanceInfo.apr,
            transactions: transactions,
            detectedBenefits: benefits,
            confidence: confidence,
            sourceType: sourceType,
            sourceFileName: fileName
        )
    }

    // MARK: - Issuer Detection

    private static func detectIssuer(from text: String) -> Issuer? {
        let lowerText = text.lowercased()

        if lowerText.contains("american express") || lowerText.contains("amex") {
            return .amex
        } else if lowerText.contains("chase") {
            return .chase
        } else if lowerText.contains("capital one") {
            return .capitalOne
        } else if lowerText.contains("citi") || lowerText.contains("citibank") {
            return .citi
        } else if lowerText.contains("discover") {
            return .discover
        } else if lowerText.contains("wells fargo") {
            return .wellsFargo
        } else if lowerText.contains("bank of america") || lowerText.contains("bofa") {
            return .bankOfAmerica
        } else if lowerText.contains("barclays") {
            return .barclays
        } else if lowerText.contains("u.s. bank") || lowerText.contains("us bank") {
            return .usBank
        }

        return nil
    }

    private static func detectCardName(from text: String) -> String? {
        let lowerText = text.lowercased()

        // Amex cards
        if lowerText.contains("gold card") { return "Gold Card" }
        if lowerText.contains("platinum card") { return "Platinum Card" }
        if lowerText.contains("green card") { return "Green Card" }

        // Chase cards
        if lowerText.contains("sapphire reserve") { return "Sapphire Reserve" }
        if lowerText.contains("sapphire preferred") { return "Sapphire Preferred" }
        if lowerText.contains("freedom unlimited") { return "Freedom Unlimited" }
        if lowerText.contains("freedom flex") { return "Freedom Flex" }

        // Capital One
        if lowerText.contains("venture x") { return "Venture X" }
        if lowerText.contains("venture") { return "Venture" }
        if lowerText.contains("savor") { return "Savor" }

        // Citi
        if lowerText.contains("double cash") { return "Double Cash" }
        if lowerText.contains("custom cash") { return "Custom Cash" }

        return nil
    }

    // MARK: - Transaction Parsing

    private static func parseTransactions(from text: String, sourceType: ImportSourceType) -> [ParsedTransaction] {
        if sourceType == .csvFile {
            return parseCSVTransactions(from: text)
        } else {
            return parseTextTransactions(from: text)
        }
    }

    private static func parseCSVTransactions(from text: String) -> [ParsedTransaction] {
        var transactions: [ParsedTransaction] = []
        let lines = text.components(separatedBy: .newlines)

        // Try to detect header row and column positions
        var dateCol = -1, descCol = -1, amountCol = -1
        var headerFound = false

        for (_, line) in lines.enumerated() {
            let columns = parseCSVLine(line)

            // Try to detect header row
            if !headerFound {
                for (colIndex, col) in columns.enumerated() {
                    let lower = col.lowercased()
                    if lower.contains("date") || lower.contains("trans") && lower.contains("date") {
                        dateCol = colIndex
                    }
                    if lower.contains("description") || lower.contains("merchant") || lower.contains("name") {
                        descCol = colIndex
                    }
                    if lower.contains("amount") || lower.contains("charge") || lower.contains("debit") {
                        amountCol = colIndex
                    }
                }
                if dateCol >= 0 || descCol >= 0 || amountCol >= 0 {
                    headerFound = true
                    continue
                }
            }

            // Parse data rows
            guard columns.count >= 2 else { continue }

            // Try to extract transaction even without header detection
            let date = extractDateFromColumns(columns, preferredIndex: dateCol)
            let desc = extractDescriptionFromColumns(columns, preferredIndex: descCol)
            let amount = extractAmountFromColumns(columns, preferredIndex: amountCol)

            if let amount = amount, !desc.isEmpty {
                let category = categorizeTransaction(desc)
                transactions.append(ParsedTransaction(
                    date: date,
                    description: desc,
                    amount: abs(amount),
                    category: category
                ))
            }
        }

        return transactions
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        var columns: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                columns.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        columns.append(current.trimmingCharacters(in: .whitespaces))
        return columns
    }

    private static func parseTextTransactions(from text: String) -> [ParsedTransaction] {
        var transactions: [ParsedTransaction] = []
        let lines = text.components(separatedBy: .newlines)

        // Patterns for common statement formats
        let patterns = [
            // MM/DD DESCRIPTION $AMOUNT
            #"(\d{1,2}/\d{1,2})\s+(.+?)\s+\$?([\d,]+\.\d{2})\s*$"#,
            // MM/DD/YYYY DESCRIPTION AMOUNT
            #"(\d{1,2}/\d{1,2}/\d{2,4})\s+(.+?)\s+\$?([\d,]+\.\d{2})\s*$"#,
            // DATE DESCRIPTION -$AMOUNT (negative for credits)
            #"(\d{1,2}/\d{1,2})\s+(.+?)\s+-?\$?([\d,]+\.\d{2})\s*$"#,
            // YYYY-MM-DD format
            #"(\d{4}-\d{2}-\d{2})\s+(.+?)\s+\$?([\d,]+\.\d{2})\s*$"#
        ]

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            for pattern in patterns {
                if let match = try? NSRegularExpression(pattern: pattern),
                   let result = match.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) {

                    guard let dateRange = Range(result.range(at: 1), in: trimmed),
                          let descRange = Range(result.range(at: 2), in: trimmed),
                          let amountRange = Range(result.range(at: 3), in: trimmed) else { continue }

                    let dateStr = String(trimmed[dateRange])
                    let desc = String(trimmed[descRange]).trimmingCharacters(in: .whitespaces)
                    let amountStr = String(trimmed[amountRange]).replacingOccurrences(of: ",", with: "")

                    if let amount = Double(amountStr), amount > 0 {
                        let date = parseDate(dateStr)
                        let category = categorizeTransaction(desc)

                        transactions.append(ParsedTransaction(
                            date: date,
                            description: desc,
                            amount: amount,
                            category: category
                        ))
                    }
                    break
                }
            }
        }

        return transactions
    }

    // MARK: - Balance Extraction

    private static func extractBalanceInfo(from text: String) -> (
        currentBalance: Double?,
        previousBalance: Double?,
        payments: Double?,
        minimumPayment: Double?,
        dueDate: Date?,
        periodStart: Date?,
        periodEnd: Date?,
        apr: Double?
    ) {
        var currentBalance: Double?
        var previousBalance: Double?
        var payments: Double?
        var minimumPayment: Double?
        var dueDate: Date?
        var periodStart: Date?
        var periodEnd: Date?
        var apr: Double?

        let lines = text.components(separatedBy: .newlines)

        for line in lines {
            let lower = line.lowercased()

            // Current/New Balance
            if lower.contains("new balance") || lower.contains("current balance") || lower.contains("statement balance") {
                currentBalance = extractAmount(from: line)
            }

            // Previous Balance
            if lower.contains("previous balance") || lower.contains("prior balance") {
                previousBalance = extractAmount(from: line)
            }

            // Payments
            if lower.contains("payment") && (lower.contains("received") || lower.contains("thank you")) {
                payments = extractAmount(from: line).map { -$0 }
            }

            // Minimum Payment
            if lower.contains("minimum payment") || lower.contains("min payment") {
                minimumPayment = extractAmount(from: line)
            }

            // Due Date
            if lower.contains("due date") || lower.contains("payment due") {
                dueDate = extractDate(from: line)
            }

            // APR
            if lower.contains("apr") || lower.contains("annual percentage") {
                if let match = line.range(of: #"(\d+\.?\d*)%"#, options: .regularExpression) {
                    let aprStr = line[match].dropLast()  // Remove %
                    apr = Double(aprStr)
                }
            }

            // Statement Period
            if lower.contains("statement period") || lower.contains("billing period") {
                let dates = extractDateRange(from: line)
                periodStart = dates.start
                periodEnd = dates.end
            }
        }

        return (currentBalance, previousBalance, payments, minimumPayment, dueDate, periodStart, periodEnd, apr)
    }

    // MARK: - Benefits Detection

    private static func detectBenefits(from text: String) -> [DetectedBenefit] {
        var benefits: [DetectedBenefit] = []
        let lines = text.components(separatedBy: .newlines)

        for line in lines {
            let lower = line.lowercased()

            // Uber/travel credits
            if lower.contains("uber") && lower.contains("credit") {
                if let amount = extractAmount(from: line) {
                    benefits.append(DetectedBenefit(name: "Uber Credit", amount: amount, type: .credit))
                }
            }

            // Airline credits
            if (lower.contains("airline") || lower.contains("travel")) && lower.contains("credit") {
                if let amount = extractAmount(from: line) {
                    benefits.append(DetectedBenefit(name: "Travel Credit", amount: amount, type: .credit))
                }
            }

            // Streaming credits
            if lower.contains("streaming") && lower.contains("credit") {
                if let amount = extractAmount(from: line) {
                    benefits.append(DetectedBenefit(name: "Streaming Credit", amount: amount, type: .credit))
                }
            }

            // Dining credits
            if lower.contains("dining") && lower.contains("credit") {
                if let amount = extractAmount(from: line) {
                    benefits.append(DetectedBenefit(name: "Dining Credit", amount: amount, type: .credit))
                }
            }
        }

        return benefits
    }

    // MARK: - Helper Functions

    private static func extractDateFromColumns(_ columns: [String], preferredIndex: Int) -> Date? {
        if preferredIndex >= 0 && preferredIndex < columns.count {
            return parseDate(columns[preferredIndex])
        }
        // Try first column as fallback
        if let date = parseDate(columns[0]) {
            return date
        }
        return nil
    }

    private static func extractDescriptionFromColumns(_ columns: [String], preferredIndex: Int) -> String {
        if preferredIndex >= 0 && preferredIndex < columns.count {
            return columns[preferredIndex]
        }
        // Return the longest non-numeric column as description
        return columns.filter { !$0.isEmpty && Double($0.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "$", with: "")) == nil }
            .max(by: { $0.count < $1.count }) ?? ""
    }

    private static func extractAmountFromColumns(_ columns: [String], preferredIndex: Int) -> Double? {
        if preferredIndex >= 0 && preferredIndex < columns.count {
            return parseAmount(columns[preferredIndex])
        }
        // Find first numeric-looking column from the end
        for col in columns.reversed() {
            if let amount = parseAmount(col) {
                return amount
            }
        }
        return nil
    }

    private static func parseAmount(_ string: String) -> Double? {
        let cleaned = string
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }

    private static func parseDate(_ string: String) -> Date? {
        let formatters: [DateFormatter] = {
            let formats = ["M/d/yyyy", "M/d/yy", "M/d", "MM/dd/yyyy", "MM/dd/yy", "MM/dd", "yyyy-MM-dd"]
            return formats.map { fmt in
                let f = DateFormatter()
                f.dateFormat = fmt
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }
        }()

        for formatter in formatters {
            if let date = formatter.date(from: string) {
                let components = Calendar.current.dateComponents([.year], from: date)
                if components.year == nil || components.year == 2000 {
                    var adjusted = Calendar.current.dateComponents([.month, .day], from: date)
                    adjusted.year = Calendar.current.component(.year, from: Date())
                    return Calendar.current.date(from: adjusted)
                }
                return date
            }
        }
        return nil
    }

    private static func extractAmount(from line: String) -> Double? {
        // Match amounts like $1,234.56 or 1234.56
        if let match = line.range(of: #"\$?[\d,]+\.\d{2}"#, options: .regularExpression) {
            return parseAmount(String(line[match]))
        }
        return nil
    }

    private static func extractDate(from line: String) -> Date? {
        // Match various date formats
        let patterns = [
            #"\b(\d{1,2}/\d{1,2}/\d{2,4})\b"#,
            #"\b(\w+ \d{1,2},? \d{4})\b"#
        ]

        for pattern in patterns {
            if let match = line.range(of: pattern, options: .regularExpression) {
                let dateStr = String(line[match])
                if let date = parseDate(dateStr) {
                    return date
                }
                // Try written format like "January 15, 2024"
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM d, yyyy"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                if let date = formatter.date(from: dateStr) {
                    return date
                }
            }
        }
        return nil
    }

    private static func extractDateRange(from line: String) -> (start: Date?, end: Date?) {
        // Match patterns like "12/01/23 - 12/31/23" or "Dec 1, 2023 to Dec 31, 2023"
        if let match = line.range(of: #"(\d{1,2}/\d{1,2}/\d{2,4})\s*[-–to]+\s*(\d{1,2}/\d{1,2}/\d{2,4})"#, options: .regularExpression) {
            let rangeStr = String(line[match])
            let parts = rangeStr.components(separatedBy: CharacterSet(charactersIn: "-–"))
                .map { $0.replacingOccurrences(of: "to", with: "").trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 {
                return (parseDate(parts[0]), parseDate(parts[1]))
            }
        }
        return (nil, nil)
    }

    private static func categorizeTransaction(_ description: String) -> SpendCategory {
        let desc = description.lowercased()

        let categories: [(SpendCategory, [String])] = [
            (.dining, ["restaurant", "doordash", "grubhub", "uber eats", "mcdonald", "starbucks", "chipotle", "panera", "subway", "pizza", "sushi", "cafe", "diner", "taco", "burger", "wendy", "chick-fil"]),
            (.groceries, ["grocery", "whole foods", "trader joe", "kroger", "safeway", "publix", "aldi", "costco", "walmart supercenter", "target", "heb", "wegmans"]),
            (.gas, ["shell", "chevron", "exxon", "bp ", "gas", "fuel", "mobil", "citgo", "speedway", "marathon", "sunoco"]),
            (.travel, ["airline", "delta", "united", "american air", "southwest", "jetblue", "hotel", "marriott", "hilton", "hyatt", "airbnb", "vrbo", "booking.com", "expedia", "uber", "lyft"]),
            (.streaming, ["netflix", "hulu", "disney+", "spotify", "apple music", "youtube", "hbo", "paramount", "peacock", "amazon prime"]),
            (.drugstores, ["cvs", "walgreens", "rite aid", "pharmacy"]),
            (.homeImprovement, ["home depot", "lowe", "menards", "ace hardware"]),
            (.entertainment, ["cinema", "movie", "theater", "concert", "ticketmaster", "stubhub", "amc"]),
            (.utilities, ["electric", "water", "gas bill", "internet", "comcast", "at&t", "verizon", "t-mobile", "utility"]),
            (.online, ["amazon", "ebay", "etsy", "shopify", "online"])
        ]

        for (category, keywords) in categories {
            if keywords.contains(where: { desc.contains($0) }) {
                return category
            }
        }

        return .other
    }

    // MARK: - Excel Parsing

    /// Parses an Excel (.xlsx, .xls) file into a ParsedStatement
    static func parseExcel(url: URL, fileName: String?) throws -> ParsedStatement {
        // Read the Excel file data
        let data = try Data(contentsOf: url)

        // For xlsx files, extract and parse the XML content
        if url.pathExtension.lowercased() == "xlsx" {
            return try parseXLSX(data: data, fileName: fileName)
        } else {
            // For older xls format, try to read as text (limited support)
            // Modern credit card exports are typically xlsx or csv
            throw ExcelParserError.unsupportedFormat("Legacy .xls format is not fully supported. Please export as .xlsx or .csv instead.")
        }
    }

    private static func parseXLSX(data: Data, fileName: String?) throws -> ParsedStatement {
        // xlsx is a ZIP archive containing XML files
        // We need to extract the worksheet and shared strings

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // Write data to temp file for unzipping
        let tempZip = tempDir.appendingPathComponent("temp.xlsx")
        try data.write(to: tempZip)

        // Unzip using ditto (macOS) or Archive (iOS)
        let unzipDir = tempDir.appendingPathComponent("unzipped")
        try FileManager.default.createDirectory(at: unzipDir, withIntermediateDirectories: true)

        #if os(macOS)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", tempZip.path, "-d", unzipDir.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        #else
        // On iOS, use Foundation's archive capabilities
        try FileManager.default.unzipItem(at: tempZip, to: unzipDir)
        #endif

        // Read shared strings (text values are stored separately)
        let sharedStringsURL = unzipDir.appendingPathComponent("xl/sharedStrings.xml")
        var sharedStrings: [String] = []
        if FileManager.default.fileExists(atPath: sharedStringsURL.path) {
            let sharedStringsData = try Data(contentsOf: sharedStringsURL)
            sharedStrings = parseSharedStrings(data: sharedStringsData)
        }

        // Read the first worksheet
        let worksheetURL = unzipDir.appendingPathComponent("xl/worksheets/sheet1.xml")
        guard FileManager.default.fileExists(atPath: worksheetURL.path) else {
            throw ExcelParserError.worksheetNotFound
        }

        let worksheetData = try Data(contentsOf: worksheetURL)
        let rows = parseWorksheet(data: worksheetData, sharedStrings: sharedStrings)

        // Convert rows to CSV text and use existing CSV parser
        let csvText = rows.map { $0.joined(separator: ",") }.joined(separator: "\n")

        return parse(text: csvText, sourceType: .excelFile, fileName: fileName)
    }

    private static func parseSharedStrings(data: Data) -> [String] {
        var strings: [String] = []

        guard let xmlString = String(data: data, encoding: .utf8) else { return strings }

        // Simple regex-based XML parsing for shared strings
        // Pattern: <t>...</t> or <t ...>...</t>
        let pattern = #"<t[^>]*>([^<]*)</t>"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let matches = regex.matches(in: xmlString, range: NSRange(xmlString.startIndex..., in: xmlString))
            for match in matches {
                if let range = Range(match.range(at: 1), in: xmlString) {
                    let text = String(xmlString[range])
                        .replacingOccurrences(of: "&amp;", with: "&")
                        .replacingOccurrences(of: "&lt;", with: "<")
                        .replacingOccurrences(of: "&gt;", with: ">")
                        .replacingOccurrences(of: "&quot;", with: "\"")
                    strings.append(text)
                }
            }
        }

        return strings
    }

    private static func parseWorksheet(data: Data, sharedStrings: [String]) -> [[String]] {
        var rows: [[String]] = []

        guard let xmlString = String(data: data, encoding: .utf8) else { return rows }

        // Parse rows: <row ...>...</row>
        let rowPattern = #"<row[^>]*>(.*?)</row>"#
        if let rowRegex = try? NSRegularExpression(pattern: rowPattern, options: [.dotMatchesLineSeparators]) {
            let rowMatches = rowRegex.matches(in: xmlString, range: NSRange(xmlString.startIndex..., in: xmlString))

            for rowMatch in rowMatches {
                if let range = Range(rowMatch.range(at: 1), in: xmlString) {
                    let rowContent = String(xmlString[range])
                    let cells = parseRowCells(rowContent, sharedStrings: sharedStrings)
                    if !cells.isEmpty {
                        rows.append(cells)
                    }
                }
            }
        }

        return rows
    }

    private static func parseRowCells(_ rowContent: String, sharedStrings: [String]) -> [String] {
        var cells: [String] = []

        // Parse cells: <c ...>...</c>
        let cellPattern = #"<c[^>]*(?:t="([^"]*)")?[^>]*>(?:<v>([^<]*)</v>)?(?:<is><t>([^<]*)</t></is>)?</c>"#
        if let cellRegex = try? NSRegularExpression(pattern: cellPattern, options: []) {
            let cellMatches = cellRegex.matches(in: rowContent, range: NSRange(rowContent.startIndex..., in: rowContent))

            for cellMatch in cellMatches {
                var cellValue = ""

                // Get type attribute (t="s" means shared string, t="inlineStr" means inline)
                let cellType: String?
                if let typeRange = Range(cellMatch.range(at: 1), in: rowContent) {
                    cellType = String(rowContent[typeRange])
                } else {
                    cellType = nil
                }

                // Get value from <v> tag
                if let valueRange = Range(cellMatch.range(at: 2), in: rowContent) {
                    let value = String(rowContent[valueRange])

                    if cellType == "s", let index = Int(value), index < sharedStrings.count {
                        // Shared string reference
                        cellValue = sharedStrings[index]
                    } else {
                        cellValue = value
                    }
                }

                // Get inline string value
                if let inlineRange = Range(cellMatch.range(at: 3), in: rowContent) {
                    cellValue = String(rowContent[inlineRange])
                }

                cells.append(cellValue)
            }
        }

        return cells
    }
}

enum ExcelParserError: LocalizedError {
    case unsupportedFormat(String)
    case worksheetNotFound
    case parsingFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let msg): return msg
        case .worksheetNotFound: return "Could not find worksheet in Excel file."
        case .parsingFailed(let msg): return "Excel parsing failed: \(msg)"
        }
    }
}

// MARK: - FileManager Unzip Extension (iOS)

#if os(iOS)
extension FileManager {
    func unzipItem(at sourceURL: URL, to destinationURL: URL) throws {
        // For iOS, we need to use a different approach
        // Since iOS doesn't have easy unzip, we'll use a manual approach
        // This is a simplified version - for production, consider using ZIPFoundation

        guard let archive = try? Data(contentsOf: sourceURL) else {
            throw ExcelParserError.parsingFailed("Could not read xlsx file")
        }

        // xlsx files start with PK (ZIP magic bytes)
        guard archive.count > 4,
              archive[0] == 0x50, archive[1] == 0x4B else {
            throw ExcelParserError.parsingFailed("Invalid xlsx file format")
        }

        // For simplicity, extract using a basic ZIP parser
        // In production, use ZIPFoundation or similar library
        try extractBasicZIP(data: archive, to: destinationURL)
    }

    private func extractBasicZIP(data: Data, to destination: URL) throws {
        // This is a simplified ZIP extractor for xlsx files
        // It handles the basic case of xlsx structure

        var offset = 0
        while offset < data.count - 4 {
            // Look for local file header (0x04034b50)
            guard data[offset] == 0x50, data[offset + 1] == 0x4B,
                  data[offset + 2] == 0x03, data[offset + 3] == 0x04 else {
                break
            }

            // Parse local file header
            let compressionMethod = UInt16(data[offset + 8]) | (UInt16(data[offset + 9]) << 8)
            let compressedSize = UInt32(data[offset + 18]) | (UInt32(data[offset + 19]) << 8) | (UInt32(data[offset + 20]) << 16) | (UInt32(data[offset + 21]) << 24)
            let uncompressedSize = UInt32(data[offset + 22]) | (UInt32(data[offset + 23]) << 8) | (UInt32(data[offset + 24]) << 16) | (UInt32(data[offset + 25]) << 24)
            let fileNameLength = UInt16(data[offset + 26]) | (UInt16(data[offset + 27]) << 8)
            let extraFieldLength = UInt16(data[offset + 28]) | (UInt16(data[offset + 29]) << 8)

            let headerSize = 30
            let fileNameStart = offset + headerSize
            let fileNameEnd = fileNameStart + Int(fileNameLength)

            guard fileNameEnd <= data.count else { break }

            let fileNameData = data[fileNameStart..<fileNameEnd]
            guard let fileName = String(data: fileNameData, encoding: .utf8) else {
                offset = fileNameEnd + Int(extraFieldLength) + Int(compressedSize)
                continue
            }

            let dataStart = fileNameEnd + Int(extraFieldLength)
            let dataEnd = dataStart + Int(compressedSize)

            guard dataEnd <= data.count else { break }

            let fileData = data[dataStart..<dataEnd]
            let filePath = destination.appendingPathComponent(fileName)

            // Create directory if needed
            let directory = filePath.deletingLastPathComponent()
            try? createDirectory(at: directory, withIntermediateDirectories: true)

            // Write file (decompress if needed)
            if compressionMethod == 0 {
                // Stored (no compression)
                try Data(fileData).write(to: filePath)
            } else if compressionMethod == 8 {
                // Deflate compression - use Compression framework
                let decompressed = try decompressDeflate(Data(fileData), expectedSize: Int(uncompressedSize))
                try decompressed.write(to: filePath)
            }

            offset = dataEnd
        }
    }

    private func decompressDeflate(_ data: Data, expectedSize: Int) throws -> Data {
        // Use Compression framework for deflate decompression
        var decompressed = Data(count: expectedSize)
        let result = decompressed.withUnsafeMutableBytes { destBuffer in
            data.withUnsafeBytes { srcBuffer in
                compression_decode_buffer(
                    destBuffer.bindMemory(to: UInt8.self).baseAddress!,
                    expectedSize,
                    srcBuffer.bindMemory(to: UInt8.self).baseAddress!,
                    data.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }

        if result == 0 {
            throw ExcelParserError.parsingFailed("Decompression failed")
        }

        return Data(decompressed.prefix(result))
    }
}
#endif

enum PDFParserError: LocalizedError {
    case fileNotFound
    case cannotOpenPDF
    case noTextFound
    case parsingFailed(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound: return "PDF file not found."
        case .cannotOpenPDF: return "Could not open the PDF document."
        case .noTextFound: return "No text could be extracted from the PDF."
        case .parsingFailed(let msg): return "Parsing failed: \(msg)"
        }
    }
}

class PDFParserService {

    func parseStatement(from url: URL) async throws -> ParsedStatement {
        #if canImport(PDFKit)
        guard let document = PDFDocument(url: url) else {
            throw PDFParserError.cannotOpenPDF
        }

        var allText = ""
        var transactions: [ParsedTransaction] = []

        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }

            // Try direct text extraction first
            if let pageText = page.string, !pageText.isEmpty {
                allText += pageText + "\n"
            } else {
                // Fall back to Vision OCR
                let ocrText = try await ocrPage(page)
                allText += ocrText + "\n"
            }
        }

        guard !allText.isEmpty else {
            throw PDFParserError.noTextFound
        }

        transactions = parseTransactions(from: allText)
        let totalSpend = transactions.reduce(0.0) { $0 + $1.amount }
        let lastFour = extractLastFour(from: allText)
        let statementDate = extractStatementDate(from: allText)
        let detectedIssuer = detectIssuer(from: allText)

        return ParsedStatement(
            detectedIssuer: detectedIssuer,
            detectedCardName: nil,
            statementPeriodStart: nil,
            statementPeriodEnd: statementDate,
            previousBalance: nil,
            paymentsReceived: nil,
            newCharges: totalSpend,
            currentBalance: totalSpend,
            minimumPayment: nil,
            paymentDueDate: nil,
            apr: nil,
            transactions: transactions,
            detectedBenefits: [],
            confidence: detectedIssuer != nil ? 0.7 : 0.5,
            sourceType: .pdfFile,
            sourceFileName: url.lastPathComponent,
            cardLastFour: lastFour
        )
        #else
        throw PDFParserError.parsingFailed("PDFKit not available on this platform.")
        #endif
    }

    // MARK: - OCR

    #if canImport(PDFKit)
    private func ocrPage(_ page: PDFPage) async throws -> String {
        let pageRect = page.bounds(for: .mediaBox)
        let scale: CGFloat = 2.0
        let size = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.white.cgColor)
            ctx.cgContext.fill(CGRect(origin: .zero, size: size))
            ctx.cgContext.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
        guard let cgImage = image.cgImage else {
            return ""
        }
        #elseif canImport(AppKit)
        let image = NSImage(size: size)
        image.lockFocus()
        if let ctx = NSGraphicsContext.current?.cgContext {
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            ctx.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: ctx)
        }
        image.unlockFocus()
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let cgImage = bitmap.cgImage else {
            return ""
        }
        #endif

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    #endif

    // MARK: - Transaction Parsing

    private func parseTransactions(from text: String) -> [ParsedTransaction] {
        var transactions: [ParsedTransaction] = []
        let lines = text.components(separatedBy: .newlines)

        // Pattern: MM/DD description $amount or amount
        let patterns = [
            // MM/DD DESCRIPTION $AMOUNT
            #"(\d{1,2}/\d{1,2})\s+(.+?)\s+\$?([\d,]+\.\d{2})\s*$"#,
            // MM/DD/YYYY DESCRIPTION AMOUNT
            #"(\d{1,2}/\d{1,2}/\d{2,4})\s+(.+?)\s+\$?([\d,]+\.\d{2})\s*$"#,
            // DATE DESCRIPTION -$AMOUNT (negative for credits)
            #"(\d{1,2}/\d{1,2})\s+(.+?)\s+-?\$?([\d,]+\.\d{2})\s*$"#
        ]

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            for pattern in patterns {
                if let match = try? NSRegularExpression(pattern: pattern),
                   let result = match.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) {

                    guard let dateRange = Range(result.range(at: 1), in: trimmed),
                          let descRange = Range(result.range(at: 2), in: trimmed),
                          let amountRange = Range(result.range(at: 3), in: trimmed) else { continue }

                    let dateStr = String(trimmed[dateRange])
                    let desc = String(trimmed[descRange]).trimmingCharacters(in: .whitespaces)
                    let amountStr = String(trimmed[amountRange]).replacingOccurrences(of: ",", with: "")

                    if let amount = Double(amountStr), amount > 0 {
                        let date = parseDate(dateStr)
                        let category = categorizeTransaction(desc)

                        transactions.append(ParsedTransaction(
                            date: date,
                            description: desc,
                            amount: amount,
                            category: category
                        ))
                    }
                    break
                }
            }
        }

        return transactions
    }

    // MARK: - Date Parsing

    private func parseDate(_ string: String) -> Date? {
        let formatters: [DateFormatter] = {
            let formats = ["M/d/yyyy", "M/d/yy", "M/d", "MM/dd/yyyy", "MM/dd/yy", "MM/dd"]
            return formats.map { fmt in
                let f = DateFormatter()
                f.dateFormat = fmt
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }
        }()

        for formatter in formatters {
            if let date = formatter.date(from: string) {
                // If no year, assume current year
                let components = Calendar.current.dateComponents([.year], from: date)
                if components.year == nil || components.year == 2000 {
                    var adjusted = Calendar.current.dateComponents([.month, .day], from: date)
                    adjusted.year = Calendar.current.component(.year, from: Date())
                    return Calendar.current.date(from: adjusted)
                }
                return date
            }
        }
        return nil
    }

    // MARK: - Auto-categorization

    private func categorizeTransaction(_ description: String) -> SpendCategory {
        let desc = description.lowercased()

        let categories: [(SpendCategory, [String])] = [
            (.dining, ["restaurant", "doordash", "grubhub", "uber eats", "mcdonald", "starbucks", "chipotle", "panera", "subway", "pizza", "sushi", "cafe", "diner", "taco", "burger", "wendy", "chick-fil"]),
            (.groceries, ["grocery", "whole foods", "trader joe", "kroger", "safeway", "publix", "aldi", "costco", "walmart supercenter", "target", "heb", "wegmans"]),
            (.gas, ["shell", "chevron", "exxon", "bp ", "gas", "fuel", "mobil", "citgo", "speedway", "marathon", "sunoco"]),
            (.travel, ["airline", "delta", "united", "american air", "southwest", "jetblue", "hotel", "marriott", "hilton", "hyatt", "airbnb", "vrbo", "booking.com", "expedia", "uber", "lyft"]),
            (.streaming, ["netflix", "hulu", "disney+", "spotify", "apple music", "youtube", "hbo", "paramount", "peacock", "amazon prime"]),
            (.drugstores, ["cvs", "walgreens", "rite aid", "pharmacy"]),
            (.homeImprovement, ["home depot", "lowe", "menards", "ace hardware"]),
            (.entertainment, ["cinema", "movie", "theater", "concert", "ticketmaster", "stubhub", "amc"]),
            (.utilities, ["electric", "water", "gas bill", "internet", "comcast", "at&t", "verizon", "t-mobile", "utility"]),
            (.online, ["amazon", "ebay", "etsy", "shopify", "online"])
        ]

        for (category, keywords) in categories {
            if keywords.contains(where: { desc.contains($0) }) {
                return category
            }
        }

        return .other
    }

    // MARK: - Helpers

    private func extractLastFour(from text: String) -> String? {
        let pattern = #"(?:ending|last 4|xxxx|account)\s*(?:in\s+)?(\d{4})"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }
        return nil
    }

    private func extractStatementDate(from text: String) -> Date? {
        let pattern = #"(?:statement|closing)\s*(?:date|period)?\s*:?\s*(\w+\s+\d{1,2},?\s+\d{4})"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            let dateStr = String(text[range])
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter.date(from: dateStr)
        }
        return nil
    }

    private func detectIssuer(from text: String) -> Issuer? {
        let lowerText = text.lowercased()

        if lowerText.contains("american express") || lowerText.contains("amex") {
            return .amex
        } else if lowerText.contains("chase") {
            return .chase
        } else if lowerText.contains("capital one") {
            return .capitalOne
        } else if lowerText.contains("citi") || lowerText.contains("citibank") {
            return .citi
        } else if lowerText.contains("discover") {
            return .discover
        } else if lowerText.contains("wells fargo") {
            return .wellsFargo
        } else if lowerText.contains("bank of america") || lowerText.contains("bofa") {
            return .bankOfAmerica
        } else if lowerText.contains("barclays") {
            return .barclays
        } else if lowerText.contains("u.s. bank") || lowerText.contains("us bank") {
            return .usBank
        }

        return nil
    }
}
