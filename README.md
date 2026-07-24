# 책나루 (Booknaru)

![CI](https://github.com/xngsoo/Booknaru/actions/workflows/ci.yml/badge.svg)

읽고 싶은 책을 검색하면, 내 주변 도서관 중 어디에 있고 지금 빌릴 수 있는지 한 화면에 보여주는 iOS 앱.

> 개발 중 · 2026.07 ~

---

## 왜 이 앱인가

도서관에 특정 책이 있는지 확인하려면 각 도서관 홈페이지를 하나씩 돌아야 한다. 이 앱은 정보나루 공공 API로 소장 도서관을 한 번에 조회하고, 네이버 책 검색 API로 표지·소개를 채워 하나의 화면에서 보여준다.

**ISBN13을 조인 키로 두 개의 외부 API를 통합**하는 것이 이 프로젝트의 기술적 정체성이다.

## 기술 스택

| 영역 | 선택 |
|---|---|
| 언어 | Swift 6.2 (language mode 6) |
| UI | SwiftUI, iOS 17.0+ |
| 아키텍처 | MVVM + Repository, `@Observable` |
| 동시성 | Swift Concurrency, 모듈별 액터 격리 |
| 모듈화 | Tuist |
| 테스트 | Swift Testing, URLProtocol 스텁 |
| CI | GitHub Actions |

## 모듈 구조

```
App           진입점, 의존성 조립
Feature       화면 (MainActor)
Domain        엔티티, UseCase, Repository 프로토콜 (nonisolated)
Data          Repository 구현, 네트워크, DTO 매핑 (nonisolated)
DesignSystem  컬러, 타이포, 공통 컴포넌트 (MainActor)
```

의존성 방향:

```
App ──> Feature ──> Domain
 │          └────> DesignSystem
 └──> Data ──────> Domain
```

**`Feature`는 `Data`를 모른다.** 화면 코드는 `Domain`이 선언한 Repository 프로토콜에만 의존하고, 실제 구현체 주입은 `App`이 담당한다. 테스트에서 Mock을 주입할 수 있는 근거이자, 네트워크 구현이 바뀌어도 화면 코드가 영향받지 않는 구조.

### 모듈별 액터 격리

Swift 6.2의 `SWIFT_DEFAULT_ACTOR_ISOLATION`을 모듈 단위로 다르게 지정했다.

| 모듈 | 격리 | 이유 |
|---|---|---|
| App, Feature, DesignSystem | `MainActor` | 어차피 전부 메인 스레드. `@MainActor` 표기 제거 |
| Domain, Data | `nonisolated` | 도서관 N곳 병렬 조회가 메인 스레드에 묶이면 안 됨 |

`Data`까지 `MainActor`로 두면 `TaskGroup`으로 동시 요청을 보내도 각 작업 본문이 메인에서 실행되어 사실상 직렬화된다. 이 프로젝트의 핵심인 병렬 최적화가 무력화되므로 의도적으로 분리했다.

## 사용 API

| API | 용도 | 인증 방식 |
|---|---|---|
| 정보나루 (data4library.kr) | 도서 검색, 소장 도서관, 대출 가능 여부 | 쿼리 파라미터 |
| 네이버 책 검색 | 표지, 저자, 출판사, 책 소개 | HTTP 헤더 |

인증 방식이 서로 달라 `AuthProvider` 프로토콜로 추상화했다. 호출부는 어느 API인지 신경 쓰지 않는다.

## 실행 방법

```bash
mise install
cp Configs/Secrets.sample.xcconfig Configs/Secrets.xcconfig
# Secrets.xcconfig에 발급받은 키 입력
tuist install
tuist generate
```

필요한 키

- `DATA4LIBRARY_KEY` — 정보나루
- `NAVER_CLIENT_ID`, `NAVER_CLIENT_SECRET` — 네이버 개발자센터

`.xcodeproj`는 커밋하지 않는다. `Project.swift`가 유일한 진실의 원천이며 프로젝트 파일은 매번 생성한다.

## 성능 개선 기록

<!-- 도서 상세 진입 시 순차 vs 병렬 조회 수치 -->
<!-- 캐싱 적용 전후 -->
_측정 예정_

## 트러블슈팅

### CI runner의 Xcode 버전이 낮아 빌드 설정이 조용히 무시됨

**문제** — 로컬에서 격리 위반 에러를 내던 코드가 CI에서는 통과했다.

**원인** — runner 기본 Xcode가 16.4(Swift 6.1)였다. Swift 6.2에서 도입된 `SWIFT_DEFAULT_ACTOR_ISOLATION`을 인식하지 못하는데, 알 수 없는 빌드 설정은 에러 없이 무시되므로 빌드는 성공했다. CI 초록불이 실제로는 아무것도 검증하지 못한 상태.

**해결** — `xcode-select`로 26.3을 명시해 로컬과 컴파일러를 일치시켰다.

### 프로젝트 xcconfig 설정이 타깃 설정에 덮임

**문제** — `Base.xcconfig`에 `SWIFT_VERSION = 6`을 썼는데 데이터 레이스 위반이 에러가 아닌 경고로 나왔다.

**원인** — Tuist의 `defaultSettings: .recommended`가 타깃 레벨에 `SWIFT_VERSION`을 주입하고, 타깃 설정이 프로젝트 설정보다 우선한다.

**해결** — `xcodebuild -showBuildSettings`로 실제 해석값을 확인해 원인을 특정하고, 타깃 레벨에 명시적으로 지정했다.

### 그 외

- mise의 `tuist@latest`가 릴리스 자산 없는 브랜치 태그를 가리켜 설치 실패 → 버전 명시 후 `mise.toml`에 고정
- `tuist init`이 기존 프로젝트 연결 모드로 스캐폴드를 생성해 `generate` 사용 불가 → 매니페스트 직접 작성
- 호스트 앱 없는 유닛 테스트는 실기기에서 실행 불가 → 시뮬레이터로 전환. 순수 로직 테스트이므로 호스트 앱은 의도적으로 부착하지 않음

## 검증

- Swift 6 언어 모드 + 모듈별 액터 격리가 의도대로 적용되는지 프로브 코드로 확인
- `Feature`에서는 컴파일 에러, `Data`에서는 통과 — 이 비대칭이 설정이 걸렸다는 증거
- PR마다 GitHub Actions에서 빌드·테스트 자동 실행
- `main` 브랜치는 CI 통과를 머지 조건으로 강제

## 문서

- [설계 결정 기록](docs/DECISIONS.md) — 무엇을 왜 선택했고 무엇을 버렸는가
- [트러블슈팅](docs/TROUBLESHOOTING.md) — 세팅·빌드 과정에서 겪은 문제와 해결
