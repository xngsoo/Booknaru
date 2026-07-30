import Foundation
import Domain

extension Book {
    /// srchBooks 한 건 -> Book. ISBN13 검증에 실패하면 nil
    init?(_ doc: SrchBooksResponse.BookDoc) {
        guard let isbn = ISBN13(doc.isbn13) else { return nil }
        self.init(isbn13: isbn,
                  title: doc.bookname.htmlUnescaped,
                  author: doc.authors.htmlUnescaped,
                  publisher: doc.publisher.htmlUnescaped,
                  publicationYear: doc.publication_year,
                  volume: doc.vol?.isEmpty == true ? nil : doc.vol,
                  coverURL: doc.bookImageURL.flatMap(Book.coverURL(from:)),
                  bookDescription: nil
        )
    }

    /// 표지 URL. 정보나루는 같은 호스트를 http/https 혼재로 반환하는데, ATS가 http를 차단해
    /// 일부 표지가 안 뜬다. 같은 호스트가 https도 서비스하므로 http는 https로 승격한다.
    static func coverURL(from raw: String) -> URL? {
        guard !raw.isEmpty, var components = URLComponents(string: raw) else { return nil }
        if components.scheme == "http" { components.scheme = "https" }
        return components.url
    }
    
    /// 알라딘 description을 얹어 새 Book 반환(값 타입이라 원본 불변)
    func withDescription(_ description: String?) -> Book {
        Book(
            isbn13: isbn13,
            title: title,
            author: author,
            publisher: publisher,
            publicationYear: publicationYear,
            volume: volume,
            coverURL: coverURL,
            bookDescription: description
        )
    }
}
