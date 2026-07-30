//
//  InMemoryCache.swift
//  Data
//
//  Created by SEUNGSOO HAN on 7/30/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

/// 키-값 인메모리 캐시. Data가 nonisolated라 loanStatus가 TaskGroup으로 동시에 들어오므로,
/// 저장소를 actor로 직렬화해 데이터 레이스를 원천 차단한다.
///
/// - `ttl == nil` : 만료 없음(세션 캐시). 서지·소장 도서관처럼 사실상 불변인 값에 쓴다.
/// - `ttl != nil` : 저장 후 지정 시간이 지나면 미스로 취급. 대출 가능 여부처럼 휘발성 값에 쓴다.
public actor InMemoryCache<Key: Hashable & Sendable, Value: Sendable> {
    private struct Entry {
        let value: Value
        let storedAt: ContinuousClock.Instant
    }

    private var storage: [Key: Entry] = [:]
    private let ttl: Duration?
    private let clock = ContinuousClock()

    public init(ttl: Duration? = nil) {
        self.ttl = ttl
    }

    /// 히트면 값을, 미스(부재 또는 TTL 만료)면 nil. 만료 항목은 읽는 김에 제거한다.
    public func value(for key: Key) -> Value? {
        guard let entry = storage[key] else { return nil }
        if let ttl, clock.now - entry.storedAt > ttl {
            storage[key] = nil
            return nil
        }
        return entry.value
    }

    public func insert(_ value: Value, for key: Key) {
        storage[key] = Entry(value: value, storedAt: clock.now)
    }
}
