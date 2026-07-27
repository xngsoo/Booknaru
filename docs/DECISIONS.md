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
