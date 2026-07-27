# 설계 결정 기록

## 2026-07-23 · Tuist 도입
`.xcodeproj`가 아니라 `Project.swift`를 진실의 원천으로 둔다.
프로젝트 구조 변경을 코드 리뷰 대상으로 만들기 위함.
대안: 순수 Xcode 프로젝트 — 설정 변경 추적이 불가능해 제외.

## 2026-07-23 · 모듈별 액터 격리 분리
`Domain`/`Data`를 `nonisolated`로 둔다.
`MainActor`로 두면 TaskGroup 병렬 요청이 사실상 직렬화되어
이 프로젝트의 핵심인 병렬 최적화가 무력화된다.

## 2026-07-23 · 네이버 책검색 선택
알라딘 대비 키 즉시 발급, 헤더 기반 인증.
정보나루(쿼리 파라미터)와 인증 방식이 달라
AuthProvider 추상화의 실질적 근거가 된다.

## 2026-07-23 · Swift 6 언어 모드 즉시 적용
나중에 마이그레이션하지 않고 처음부터 적용.
코드가 0줄일 때가 데이터 레이스 경고를 해소하기 가장 싼 시점.

## 2026-07-27 · 네트워킹은 URLSession 직접 구현 (Alamofire 미도입)
Data 레이어의 HTTP 통신을 `URLSession` + Swift Concurrency로 직접 구현한다.

- 이 프로젝트의 정체성이 *모듈별 액터 격리 → TaskGroup 병렬 조회*다.
  `URLSession.data(for:)`는 네이티브 async이며 `nonisolated`에서 그대로 동작해,
  병렬 최적화가 라이브러리가 아닌 설계의 결과로 드러난다.
- `AuthProvider` 추상화(쿼리 vs 헤더 인증)가 Alamofire의
  `RequestInterceptor`/`RequestAdapter`와 정확히 겹친다. 직접 만든 추상화가
  설계 근거인 이상, 그 역할을 대체하는 라이브러리는 자기모순이 된다.
- 테스트를 `URLProtocol` 스텁으로 두기로 했는데, URLSession과 표준 조합이라
  Alamofire 스택을 한 겹 통과하지 않고 매핑만 곧장 검증할 수 있다.
- 실제 요구가 GET 3~4개 + 인증 두 방식뿐이다. retry·요청 큐잉·multipart·
  reachability 같은 Alamofire의 강점이 하나도 등장하지 않아 오버엔지니어링이다.

대안: Alamofire — 실무 팀 표준이거나 재시도/토큰 리프레시/업로드가 예정된
경우엔 정당하나, 현재 스펙엔 근거가 없어 제외.
