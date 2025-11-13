import Foundation
import WebKit

struct Grade {
    let date: Date
    let value: Double
}

enum NetworkError: Error {
    case sessionExpired
    case networkError(Error)
    case noData
    case parsingError
}

class NetworkManager {
    static let shared = NetworkManager()
    private var cookies: [HTTPCookie] = []
    
    private let cookieStorage = HTTPCookieStorage.shared

    private init() {
        loadCookies()
    }
    
    var isLoggedIn: Bool {
        return !cookies.isEmpty
    }

    func setCookies(_ cookies: [HTTPCookie]) {
        self.cookies = cookies
        saveCookies()
    }
    
    func logout() {
        cookies.removeAll()
        UserDefaults.standard.removeObject(forKey: "savedCookies")
    }
    
    private func saveCookies() {
        let cookieData = cookies.map { $0.properties }
        UserDefaults.standard.set(cookieData, forKey: "savedCookies")
    }
    
    private func loadCookies() {
        guard let cookieData = UserDefaults.standard.array(forKey: "savedCookies") as? [[HTTPCookiePropertyKey: Any]] else { return }
        cookies = cookieData.compactMap {
            guard let cookie = HTTPCookie(properties: $0) else { return nil }
            if let expiresDate = cookie.expiresDate, expiresDate < Date() {
                return nil
            }
            return cookie
        }
    }

    private let gradesURL = URL(string: "https://web.spaggiari.eu/cvv/app/default/genitori_note.php?ordine=materia&filtro=tutto")!

    func fetchGrades(completion: @escaping (Result<[String: [Grade]], NetworkError>) -> Void) {
        var request = URLRequest(url: gradesURL)
        let headers = HTTPCookie.requestHeaderFields(with: cookies)
        request.allHTTPHeaderFields = headers
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }

            if let htmlString = String(data: data, encoding: .utf8) {
                if htmlString.contains("Codice Personale / Email") {
                    self.logout()
                    completion(.failure(.sessionExpired))
                    return
                }
                
                let grades = self.parseGrades(from: htmlString)
                completion(.success(grades))
            } else {
                completion(.failure(.parsingError))
            }
        }
        task.resume()
    }

    private func parseGrades(from html: String) -> [String: [Grade]] {
        var grades: [String: [Grade]] = [:]
        
        let subjectPattern = #"<td colspan="48" class="registro redtext open_sans_condensed_bold font_size_20" align="center" style="padding:20px;" >\s*([^<]+?)\s*</td>"#
        
        guard let subjectRegex = try? NSRegularExpression(pattern: subjectPattern, options: []) else {
            return [:]
        }
        
        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
        let subjectMatches = subjectRegex.matches(in: html, options: [], range: nsRange)
        
        for i in 0..<subjectMatches.count {
            let match = subjectMatches[i]
            let subjectRange = match.range(at: 1)
            
            if let subjectR = Range(subjectRange, in: html) {
                let subject = String(html[subjectR]).trimmingCharacters(in: .whitespacesAndNewlines)
                var subjectGrades: [Grade] = []
                
                let startIdx = html.index(html.startIndex, offsetBy: match.range.upperBound)
                let endIdx = (i + 1 < subjectMatches.count) ? html.index(html.startIndex, offsetBy: subjectMatches[i + 1].range.lowerBound) : html.endIndex
                
                let content = String(html[startIdx..<endIdx])
                
                let rowPattern = #"<tr.*?>(.*?)</tr>"#
                guard let rowRegex = try? NSRegularExpression(pattern: rowPattern, options: .dotMatchesLineSeparators) else { continue }
                
                let rowNsRange = NSRange(content.startIndex..<content.endIndex, in: content)
                rowRegex.enumerateMatches(in: content, options: [], range: rowNsRange) { rowMatch, _, _ in
                    guard let rowMatch = rowMatch, rowMatch.numberOfRanges > 1 else { return }
                    
                    let rowHtmlRange = rowMatch.range(at: 1)
                    if let rowR = Range(rowHtmlRange, in: content) {
                        let rowHtml = String(content[rowR])
                        
                        let datePattern = #"<span class="voto_data cella_data font_size_11" style="">(\d{2}\/\d{2}\/\d{4})</span>"#
                        let gradePattern = #"<p align="center" class="s_reg_testo cella_trattino" style="height:40px; line-height:40px; border:0; margin:0; padding:0;font-weight:bold; font-size:22px;">\s*([^<]+?)\s*</p>"#
                        
                        guard let dateRegex = try? NSRegularExpression(pattern: datePattern), let gradeRegex = try? NSRegularExpression(pattern: gradePattern) else { return }
                        
                        let dateNsRange = NSRange(rowHtml.startIndex..<rowHtml.endIndex, in: rowHtml)
                        let gradeNsRange = NSRange(rowHtml.startIndex..<rowHtml.endIndex, in: rowHtml)
                        
                        if let dateMatch = dateRegex.firstMatch(in: rowHtml, options: [], range: dateNsRange), let gradeMatch = gradeRegex.firstMatch(in: rowHtml, options: [], range: gradeNsRange) {
                            let dateStrRange = dateMatch.range(at: 1)
                            let gradeStrRange = gradeMatch.range(at: 1)
                            
                            if let dateR = Range(dateStrRange, in: rowHtml), let gradeR = Range(gradeStrRange, in: rowHtml) {
                                let dateString = String(rowHtml[dateR])
                                let gradeString = String(rowHtml[gradeR]).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
                                
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "dd/MM/yyyy"
                                if let date = dateFormatter.date(from: dateString), let gradeValue = Double(gradeString) {
                                    subjectGrades.append(Grade(date: date, value: gradeValue))
                                }
                            }
                        }
                    }
                }
                
                if !subjectGrades.isEmpty {
                    grades[subject] = subjectGrades.sorted(by: { $0.date < $1.date })
                }
            }
        }
        
        return grades
    }
}
