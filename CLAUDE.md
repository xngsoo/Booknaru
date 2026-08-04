# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

책나루(Booknaru) — 책 제목을 검색하면 주변 도서관 중 어디에 소장돼 있고 지금 대출 가능한지 보여주는 앱.
**ISBN13을 조인 키로 정보나루(소장·대출) + 알라딘(책 소개) 두 API를 통합**하는 것이 프로젝트의 기술적 정체성이다.

- **Platform:** iOS 17.0+, Swift 6.2 (language mode 6), SwiftUI
- **Dependency manager:** Tuist (외부 의존성 없음. 추가 전에 먼저 물어볼 것)
- **Architecture:** MVVM + Repository, `@Observable`

프로젝트 파일은 **커밋하지 않는다.** `Project.swift`가 유일한 진실의 원천이고 `.xcodeproj`는 매번 생성한다.
`Configs/Secrets.xcconfig`(정보나루·알라딘 키)도 커밋 대상이 아니다.

## Commands

빌드·테스트는 **XcodeBuildMCP 도구**를 쓴다 (workspace `Booknaru.xcworkspace`, scheme `Booknaru`).
세션 첫 빌드 전에 `session_show_defaults`로 기본값을 확인하고, 없으면 위 값으로 `session_set_defaults`.

- 프로젝트 생성 (`Project.swift`나 파일 추가/삭제 후 **필수**): `tuist generate --no-open`
- 테스트: `test_sim` — 전체 35개 남짓, 20초면 끝나므로 변경 후 항상 돌린다
- 린터 없음. 컨벤션은 아래 규칙과 주변 코드로 맞춘다

## Module rules

```
App ──> Feature ──> Domain          App: 의존성 조립(CompositionRoot)
 │          └────> DesignSystem     Feature: 화면 + ViewModel
 └──> Data ──────> Domain           Domain: Entity·UseCase·Repository 프로토콜
                                    Data: Repository 구현·네트워크·DTO
```

- **`Feature`는 `Data`를 모른다.** 화면은 Domain 프로토콜에만 의존하고 구현체 주입은 `App`이 한다. 이 방향을 깨는 import는 넣지 말 것.
- **액터 격리는 모듈 단위로 다르다.** App·Feature·DesignSystem은 `MainActor`, Domain·Data는 `nonisolated`.
  Domain/Data를 MainActor로 끌어오면 `TaskGroup` 병렬 조회가 사실상 직렬화된다 — 이 프로젝트의 핵심 최적화가 무력화되므로 의도된 분리다.
- Repository 구현은 `Caching*`이 `Default*`를 감싸는 데코레이터다. 캐시 정책 변경은 `Caching*` 쪽에서.
- 개발계(Debug)는 `DummyRepositories`만 쓴다. 무료 API 호출 제한을 개발 중에 소진하지 않기 위한 것이니, 실제 호출이 필요하면 Release로 확인한다.

## Git

- **`dev`에 직접 커밋하지 않는다.** 항상 `feat/*` `fix/*` `chore/*` `docs/*` 브랜치를 파고 PR로 `dev`에 모은다. 릴리스만 `dev` → `main` → 태그(`vX.Y.Z`) → TestFlight.
- 커밋 메시지는 **제목 한 줄만**. 본문도, `Co-Authored-By` 트레일러도 붙이지 않는다. 형식: `type(scope): 한국어 요약`
- 커밋·푸시·PR 생성은 요청받았을 때만 한다.

## Code conventions

- Target the latest stable Swift and follow current SwiftUI best practices.
- Prefer `async/await` and structured concurrency; avoid completion-handler APIs in new code.
- Handle errors explicitly. Do not swallow failures with `try?` where a failure path matters; surface or propagate errors deliberately.
- Keep comments minimal: document the *why*, not the *what*. Let clear naming carry the rest.
  주석·커밋·PR·문서는 **한국어**로 쓴다. 특히 "왜 이 구조인가"(액터 격리, 캐시 TTL, 폴백 선택 같은 판단)는 코드에 남긴다 — 이 저장소의 기존 주석이 그 톤의 기준이다.
- 새 파일은 기존 파일과 같은 헤더 주석(파일명·모듈·작성자·Copyright)으로 시작한다.
- Every SwiftUI `View` you write or modify must ship with a `#Preview` block backed by mock data.
  Feature의 프리뷰용 스텁은 `PreviewSupport.swift`의 `PreviewFactory`를 쓰고, 프리뷰·스텁 코드는 전부 `#if DEBUG`로 감싼다.
- 분기·정렬·파싱·캐시처럼 틀리면 조용히 잘못 도는 로직에는 Swift Testing 테스트를 하나 남긴다. 테스트 이름은 기존처럼 한국어 문장으로.
- Before writing code for a non-trivial change, state how it will work in one short paragraph, then implement.

## Working style

- Deliver what was asked, at the scope intended. Make routine judgment calls yourself, and check in only when different readings of the request would lead to materially different work. If the request seems mistaken or a better approach exists, say so in a sentence and continue with the task as asked rather than quietly narrowing, widening, or transforming it. Finish the whole task, and stop short of actions that are clearly beyond what was asked.

- Before your first tool call, say in one sentence what you're about to do. While working, give a brief update only when you find something important or change direction. When you finish, lead with the outcome: your first sentence should answer "what happened" or "what did you find," with supporting detail after it.

- Only correct an earlier statement when the error would change the code, conclusions, or decisions. State corrections plainly and briefly, then continue. For slips that change nothing, make the fix and move on without noting it.

- Match the length of written deliverables (PR descriptions, docs, summaries) to what the task needs: cover the substance, but do not pad with filler sections, redundant summaries, or boilerplate.

- Delegate to a subagent only for large tasks that are genuinely independent and parallelizable, such as a wide multi-file investigation. Do not delegate work you can finish yourself in a handful of tool calls, and do not use subagents to verify or double-check your own work. If one subagent can complete the task, use one rather than several, and keep spawn counts low.
