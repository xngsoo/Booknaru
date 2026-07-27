//
//  URLProtocolStub.swift
//  Data
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
@testable import Data

/// URLSession이 실제 네트워크로 나가기 직전에 가로채, 우리가 심은 응답을 돌려준다.
/// detail()처럼 한 흐름에서 두 API(정보나루·알라딘)를 동시에 부르는 경우가 있어,
/// 요청 URL의 host로 응답을 골라 준다.
final class URLProtocolStub: URLProtocol {
    struct Stub { let data: Data; let statusCode: Int }

    // host -> stub. nonisolated(unsafe)는 테스트 직렬 실행(@Suite(.serialized)) 전제.
    nonisolated(unsafe) static var stubs: [String: Stub] = [:]

    /// 테스트 시작마다 초기화해 이전 테스트의 등록이 새지 않게 한다.
    static func reset() { stubs = [:] }

    /// host별 응답 등록. json 문자열을 그대로 바디로 돌려준다.
    static func register(host: String, json: String, statusCode: Int = 200) {
        stubs[host] = Stub(data: Data(json.utf8), statusCode: statusCode)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let host = request.url?.host, let stub = Self.stubs[host] else {
            client?.urlProtocol(self, didFailWithError: NetworkError.invalidResponse)
            return
        }
        let response = HTTPURLResponse(
            url: request.url!, statusCode: stub.statusCode,
            httpVersion: nil, headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    /// 스텁을 등록한 URLSession을 만들어 준다
    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: config)
    }
}
