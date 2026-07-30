# 설계 결정 기록

## 2026-07-23 · Tuist 도입
`.xcodeproj`가 아니라 `Project.swift`를 진실의 원천으로 둔다.
프로젝트 구조 변경을 코드 리뷰 대상으로 만들기 위함.
대안: 순수 Xcode 프로젝트 — 설정 변경 추적이 불가능해 제외.

## 2026-07-23 · 모듈별 액터 격리 분리
`Domain`/`Data`를 `nonisolated`로 둔다.
`MainActor`로 두면 TaskGroup 병렬 요청이 사실상 직렬화되어
이 프로젝트의 핵심인 병렬 최적화가 무력화된다.

## 2026-07-23 · 네이버 책검색 선택 (2026-07-27 알라딘으로 대체됨)
알라딘 대비 키 즉시 발급, 헤더 기반 인증.
정보나루(쿼리 파라미터)와 인증 방식이 달라
AuthProvider 추상화의 실질적 근거가 된다.
> 이후 책 소개·메타데이터 품질을 이유로 알라딘으로 전환. 아래 2026-07-27 항목 참조.

## 2026-07-23 · Swift 6 언어 모드 즉시 적용
나중에 마이그레이션하지 않고 처음부터 적용.
코드가 0줄일 때가 데이터 레이스 경고를 해소하기 가장 싼 시점.

## 2026-07-27 · 네트워킹은 URLSession 직접 구현 (Alamofire 미도입)
Data 레이어의 HTTP 통신을 `URLSession` + Swift Concurrency로 직접 구현한다.

- 이 프로젝트의 정체성이 *모듈별 액터 격리 → TaskGroup 병렬 조회*다.
  `URLSession.data(for:)`는 네이티브 async이며 `nonisolated`에서 그대로 동작해,
  병렬 최적화가 라이브러리가 아닌 설계의 결과로 드러난다.
- `AuthProvider` 추상화가 Alamofire의
  `RequestInterceptor`/`RequestAdapter`와 정확히 겹친다. 직접 만든 추상화가
  설계 근거인 이상, 그 역할을 대체하는 라이브러리는 자기모순이 된다.
- 테스트를 `URLProtocol` 스텁으로 두기로 했는데, URLSession과 표준 조합이라
  Alamofire 스택을 한 겹 통과하지 않고 매핑만 곧장 검증할 수 있다.
- 실제 요구가 GET 3~4개 + 인증 두 방식뿐이다. retry·요청 큐잉·multipart·
  reachability 같은 Alamofire의 강점이 하나도 등장하지 않아 오버엔지니어링이다.

대안: Alamofire — 실무 팀 표준이거나 재시도/토큰 리프레시/업로드가 예정된
경우엔 정당하나, 현재 스펙엔 근거가 없어 제외.

## 2026-07-27 · 2차 도서정보 API를 알라딘으로 변경 (네이버 → 알라딘)
표지·소개 보강 API를 네이버 책검색에서 알라딘 상품 API(`ItemLookUp`)로 교체한다.

- **전환 사유** — 책 소개·메타데이터 품질. 알라딘이 서점 API라
  책 소개·출간 정보 등 도서 메타데이터가 더 풍부하고 정확하다.
- **역할** — 정보나루가 검색·소장 도서관·표지·대출 여부를 담당하고,
  알라딘은 `bookDescription`(책 소개) 보강만 맡는다. ISBN13이 두 API의 조인 키.

영향: 알라딘도 정보나루처럼 쿼리 파라미터(`ttbkey`) 인증이라,
"헤더 vs 쿼리"라는 AuthProvider의 원래 근거(2026-07-23 네이버 항목)는 사라졌다.
그럼에도 AuthProvider는 유지한다 — "인증 키는 endpoint가 아니라 client 설정에
속한다"는 경계와, 향후 헤더/Bearer 인증 API 확장 여지를 위해서다. 다만
추상화가 얇아졌음을 명시해 둔다.
대안: AuthProvider 제거 후 Repository가 직접 키 부착 — 지금 스펙엔 더 단순하나,
확장 여지를 남기려 보류.

## 2026-07-27 · 위치 기반 지역 조회의 레이어 배치
사용자 위치 → 정보나루 지역 코드 변환을 다음처럼 나눈다.

- **Domain** — `RegionProvider` 프로토콜 + `RegionCode(administrativeArea:)` 매핑.
  위치 취득 실패·권한 거부를 `throws`가 아니라 **기본 지역(서울) 폴백**으로 다룬다.
  지역은 화면을 못 그릴 만큼 치명적이지 않아서, 에러 전파보다 폴백이 UX에 맞다.
- **Data** — `CoreLocationRegionProvider`(actor). CoreLocation은 네트워크와 마찬가지로
  "외부 데이터 취득" 어댑터이므로 Data에 둔다. 별도 Location 모듈은 오버엔지니어링이라 제외.
  한 번 확정한 지역은 actor에 캐시한다.

iOS 17 제약: `CLLocationUpdate`의 권한 거부 프로퍼티(`authorizationDenied`,
`locationUnavailable`)가 iOS 18+ 전용이라, 배포 타깃 17.0에서는 거부/지연을
구분할 API가 없다. → 측위 스트림과 sleep을 `withTaskGroup`으로 레이스시켜
5초 타임아웃으로 끊고 폴백한다. (iOS 18 상향 시 조기 감지로 대체 가능)

## 2026-07-30 · 캐싱은 데코레이터 Repository로, 대출 여부만 TTL
같은 ISBN 재조회 비용을 캐싱으로 흡수하되, 배치와 정책을 다음처럼 정한다.

- **배치 — 데코레이터** — `Default*Repository`를 고치지 않고 같은 프로토콜을 구현하는
  `Caching*Repository`로 감싼다. `Domain`/`Feature`는 `any …Repository`에만 의존하므로
  화면·UseCase 코드가 바뀌지 않고, 조립은 `CompositionRoot` 한 곳에서만 래핑을 더한다.
  캐싱을 명시적·교체 가능·독립 테스트 가능한 한 겹으로 드러내려는 선택 —
  `AuthProvider`를 "인증은 client 설정에 속한다"며 분리한 것과 같은 결이다.
- **동시성 — actor 캐시** — `loanStatus`가 `TaskGroup`으로 N개 동시에 들어오므로
  저장소(`InMemoryCache`)를 actor로 두어 데이터 레이스를 원천 차단한다.
  Data를 nonisolated로 둔 결정과 맞물린다.
- **정책 — 휘발성으로 나눔** — 서지(`detail`)·소장 도서관(`holdingLibraries`)은
  사실상 불변이라 세션 캐시(TTL 없음). 대출 가능 여부(`loanStatus`)는 반납/대출로
  자주 바뀌므로 **60초 TTL**. 세션 내내 캐싱하면 "반납됐는데 대출 중으로 표시"되는
  정합성 버그가 생긴다. 60초는 상세 화면 내 이동·재진입 구간을 흡수하면서
  반납 반영도 놓치지 않는 절충값이다. `search`는 재조회 패턴이 약해 패스스루.

대안: HTTPClient(URL) 레벨 캐싱 — 범용이지만 "대출 여부만 짧은 TTL" 같은
도메인 의미 기반 정책을 표현할 수 없어 제외.
대안: in-flight 요청 병합·LRU 용량 제한 — 현재 규모엔 과설계라 확장 여지로만 남김.

## 2026-07-30 · 배포 자동화는 fastlane, 테스트는 xcodebuild 유지 (하이브리드)
TestFlight 배포를 fastlane으로 자동화하되, 테스트 CI는 기존 `xcodebuild`를 그대로 둔다.

- **하이브리드 근거** — 이미 `xcodebuild test` CI가 잘 돈다. 이를 fastlane `scan`으로 감싸도
  실익이 없고 레이어만 는다. fastlane은 그 강점인 **코드 서명·아카이브·업로드**(match·gym·pilot)에만 쓴다.
- **서명은 match** — Distribution 인증서·프로파일을 암호화해 별도 private repo에 두고 로컬·CI가
  동일하게 복호화해 쓴다. 인증서를 사람이 주고받지 않고, CI 러너가 빈 키체인이어도 재현된다.
- **인증은 App Store Connect API Key** — Apple ID+2FA는 CI에서 사람이 코드를 못 넣어 막힌다.
  API Key는 2FA 없이 서버 인증이 되어 자동화의 전제.
- **구성별 서명 분리** — Debug 자동 서명(로컬 실기기 개발), Release 수동 서명(match, 배포).
  프로젝트 전역 xcconfig가 아니라 **App 타깃 Release 구성에만** 건다. 전역에 두면 프레임워크
  서명까지 깨지고, Debug에 두면 로컬 개발·시뮬레이터 테스트가 깨진다.

대안: Xcode Cloud — 설정은 간단하나 서명·비밀 관리가 블랙박스라 학습 가치가 낮아 제외.
대안: fastlane으로 테스트까지 일원화 — 현재 테스트 CI를 대체할 이유가 없어 보류.
