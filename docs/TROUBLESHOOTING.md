# 트러블슈팅

1주차 세팅 과정에서 실제로 겪은 문제와 해결 과정. 시간 역순.

---

## 7. `.gitignore`가 이미 추적 중인 파일에 적용되지 않음

**증상** — `.gitignore`에 `*.xcodeproj`, `Derived/`를 추가했는데 `git status`에 계속 잡혔다.

**원인** — `.gitignore`는 **추적되지 않는 파일**에만 적용된다. 한 번이라도 `git add`된 파일은 이후 규칙을 추가해도 소급되지 않는다.

**진단** — `git ls-files | grep xcodeproj`로 인덱스에 이미 등록돼 있음을 확인.

**해결** — 인덱스에서만 제거하고 다시 추가했다.

```bash
git rm -r --cached .
git add .
git commit -m "chore: .gitignore 규칙 소급 적용"
```

`--cached`가 없으면 실제 파일이 지워진다. 반드시 붙인다.

---

## 6. PAT에 `workflow` 스코프가 없어 워크플로 파일 푸시 거부

**증상** — `.github/workflows/ci.yml`을 포함한 커밋을 푸시하자 거부됐다. 다른 파일만 있는 커밋은 정상 푸시됐다.

**원인** — GitHub은 워크플로 파일 변경에 별도 권한(`workflow` 스코프)을 요구한다. CI 정의를 바꾸는 것은 임의 코드 실행 권한과 같기 때문이다. 기존 PAT에는 `repo` 스코프만 있었다.

**진단** — 에러 메시지가 `refusing to allow ... without workflow scope`로 스코프 이름을 직접 명시.

**해결** — PAT를 재발급하는 대신 원격을 SSH로 전환했다. SSH 키는 스코프 개념이 없어 이 문제가 구조적으로 발생하지 않는다.

```bash
git remote set-url origin git@github.com:xngsoo/Booknaru.git
```

---

## 5. CI runner의 Xcode 버전이 낮아 빌드 설정이 조용히 무시됨

**증상** — 로컬에서 액터 격리 위반 에러를 내던 코드가 CI에서는 통과했다. CI 초록불이 아무것도 검증하지 못하는 상태.

**원인** — runner 기본 Xcode가 16.4(Swift 6.1)였다. Swift 6.2에서 도입된 `SWIFT_DEFAULT_ACTOR_ISOLATION`을 인식하지 못하는데, **알 수 없는 빌드 설정은 에러 없이 무시**되므로 빌드는 성공한다.

**진단** — 워크플로에 환경 출력 스텝을 넣어 runner 상태를 먼저 파악했다.

```yaml
- name: Show environment
  run: |
    xcodebuild -version
    ls /Applications | grep Xcode
    xcrun simctl list devices available | grep iPhone
```

`macos` 이미지에 Xcode 16.0부터 26.3까지 다수가 설치돼 있고 기본값만 16.4임을 확인.

**해결** — 로컬과 컴파일러를 일치시켰다.

```yaml
- name: Select Xcode
  run: sudo xcode-select -s /Applications/Xcode_26.3.app
```

**교훈** — 알 수 없는 빌드 설정이 무시된다는 성질 때문에, 설정을 켰다는 사실만으로는 적용을 보장할 수 없다. 로컬과 CI의 툴체인 버전을 명시적으로 고정해야 한다.

---

## 4. 실기기에서 유닛 테스트 실행 실패

**증상** — 시뮬레이터에서는 통과하는 테스트가 iPhone 17 실기기 destination에서 실패했다.

**원인** — 앱 호스트 없이 실행되는 tool-hosted 테스트 번들은 실기기에서 지원되지 않는다. `Domain`, `Data` 모듈 테스트가 여기 해당한다.

**해결** — 테스트 destination을 시뮬레이터로 고정했다. 로컬과 CI가 같은 destination을 쓰게 되어 결과 재현성도 확보됐다.

---

## 3. xcconfig의 Swift 6 설정이 타깃 설정에 덮임

**증상** — `Base.xcconfig`에 Swift 6 언어 모드를 지정했는데 데이터 레이스 위반이 **에러가 아닌 경고**로 나왔다.

**원인** — Tuist의 `defaultSettings: .recommended`가 타깃 레벨에 `SWIFT_VERSION`을 주입한다. Xcode의 설정 우선순위는 **타깃 > 프로젝트 > xcconfig**이므로 프로젝트 레벨 지정이 무력화됐다.

**진단** — 설정이 최종적으로 어떻게 해석되는지 직접 확인했다.

```bash
xcodebuild -showBuildSettings -project Booknaru.xcodeproj -target Domain | grep SWIFT_VERSION
```

xcconfig에 쓴 값과 다른 값이 출력되면서 원인이 특정됐다.

**해결** — 타깃 레벨 base settings에 명시적으로 지정했다.

```swift
settings: .settings(
    base: ["SWIFT_VERSION": "6"],
    defaultSettings: .recommended
)
```

**부수 확인** — `SWIFT_VERSION`은 **언어 모드**이며 유효값은 `4`, `4.2`, `5`, `6`이다. 컴파일러 버전(6.2)을 넣는 것이 아니다. 둘을 혼동하면 값이 무시되고 기본 모드로 빌드된다.

---

## 2. `tuist init` 스캐폴드가 generated 프로젝트가 아님

**증상** — `tuist init` 후 `tuist generate`가 동작하지 않았다.

**원인** — 생성된 `Tuist.swift`의 `project` 값이 `.xcode`였다. 이 모드는 기존 `.xcodeproj`를 그대로 쓰는 방식이라 생성 대상이 없다. 또한 `init`이 프로젝트명 하위 디렉터리를 파고 스캐폴드를 만들어, 수동으로 만든 `Modules/`와 경로가 어긋났다.

**진단** — `Tuist.swift`와 `Project.swift`의 위치, `Modules/`와의 상대 경로를 `find`로 대조.

**해결** — 스캐폴드를 전부 지우고 `Tuist.swift`와 `Project.swift`를 레포 루트에 직접 작성했다. Tuist는 `init` 없이 두 파일만 있으면 동작한다.

```swift
import ProjectDescription

let tuist = Tuist(project: .tuist())
```

**교훈** — 스캐폴드 생성기는 버전마다 산출물이 다르다. 구조를 정확히 통제해야 하는 상황에서는 손으로 두 파일을 놓는 편이 빠르고 재현 가능하다.

---

## 1. `mise use tuist@latest`가 릴리스 에셋 없는 태그로 해석됨

**증상** — Tuist 설치가 실패했다.

**원인** — `latest`가 릴리스 태그가 아닌 브랜치 태그로 해석되어 다운로드할 에셋이 없었다.

**해결** — 명시적 버전으로 고정했다.

```bash
mise use tuist@4.XX.Y
```

레포 루트의 `mise.toml`에 버전이 기록되고, CI의 `jdx/mise-action@v2`가 같은 파일을 읽어 동일 버전을 설치한다. **로컬과 CI의 툴 버전 일치**가 이 파일의 유일한 목적이다.

---

## 무시해도 되는 것

### 시뮬레이터 접근성 번들 중복 클래스 경고

```
objc[...]: Class UIAccessibilityLoaderWebShared is implemented in both
.../WebKit.axbundle/WebKit and .../WebCore.axbundle/WebCore
```

두 경로 모두 시뮬레이터 런타임 내부의 Apple 프레임워크다. 앱 코드와 무관하며 실기기·릴리스 빌드에서는 나타나지 않는다.
