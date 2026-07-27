import Foundation
import Domain

extension Book {
    /// srchBooks 한 건 -> Book. ISBN13 검증에 실패하면 nil
    init?(_ doc: SrchBooksResponse.BookDoc) {
        guard let isbn = ISBN13(doc.isbn13) else { return nil }
        self.init(isbn13: isbn,
                  title: doc.bookname,
                  author: doc.authors,
                  publisher: doc.publisher,
                  publicationYear: doc.publication_year,
                  volume: doc.vol?.isEmpty == true ? nil : doc.vol,
                  coverURL: doc.bookImageURL.flatMap(URL.init(string: )),
                  bookDescription: nil
        )
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
