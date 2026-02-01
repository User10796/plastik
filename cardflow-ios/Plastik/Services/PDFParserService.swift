import Foundation
import Vision
#if canImport(PDFKit)
import PDFKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct ParsedStatement {
    let transactions: [ParsedTransaction]
    let totalSpend: Double
    let statementDate: Date?
    let cardLastFour: String?
}

struct ParsedTransaction: Identifiable {
    let id = UUID()
    let date: Date?
    let description: String
    let amount: Double
    let category: SpendCategory?
}

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

        return ParsedStatement(
            transactions: transactions,
            totalSpend: totalSpend,
            statementDate: statementDate,
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
}
