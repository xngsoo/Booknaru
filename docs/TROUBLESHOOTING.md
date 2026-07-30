# 트러블슈팅

1주차 세팅 과정에서 실제로 겪은 문제와 해결 과정. 시간 역순.

---

## 14. CI에서 codesign이 키체인 확인을 기다리며 무한 대기

**증상** — `fastlane beta`가 CI에서 `Signing DesignSystem.framework`에 멈춰 30분 넘게 진행되지 않았다. 로컬에선 잘 됐다.

**원인** — `match`가 서명키를 키체인에 설치하지만, codesign이 그 키에 접근할 때 **"키체인 접근 허용" 확인**을 요구한다. 로컬은 다이얼로그를 클릭하면 되지만, **헤드리스 CI 러너는 눌러줄 사람이 없어** 영원히 대기한다.

**해결** — `beta` 레인 시작에 `setup_ci`를 추가했다. CI에서 임시 키체인을 만들어 unlock하고 **partition list(ACL)** 를 설정해, codesign이 확인 없이 바로 서명하게 한다. 로컬 실행에선 자동으로 건너뛴다.

**교훈** — "로컬에서 되니 CI도 되겠지"가 안 통하는 대표 사례. CI는 헤드리스라 **사람의 클릭을 전제한 동작**이 전부 멈춘다.

---

## 13. CI의 match가 certs repo 접근에 실패 (403 → 400)

**증상** — CI `match`가 인증서 repo clone에서 실패했다. 값을 고칠 때마다 에러 코드가 **403 → 400**으로 오갔다.

**원인**
- **SSH vs HTTPS** — Matchfile git_url이 SSH(`git@...`)인데 CI 러너엔 SSH 키가 없다. → deploy.yml에 `MATCH_GIT_URL`(https)을 주입해 HTTPS로 전환.
- **403** — HTTPS 토큰(`MATCH_GIT_BASIC_AUTHORIZATION`)이 그 private repo 접근 권한이 없음.
- **400** — 헤더가 깨진 것. macOS `base64`가 76자마다 넣는 **줄바꿈**이 섞여 `Authorization: Basic ...` 값이 망가졌다.

**해결** — match가 쓰는 헤더를 로컬에서 그대로 재현해 먼저 검증한 뒤, 검증된 값을 그대로 시크릿에 주입했다.

```bash
AUTH=$(printf 'x-access-token:%s' "$PAT" | base64 | tr -d '\n')   # 줄바꿈 제거가 핵심
git clone https://github.com/xngsoo/booknaru-certificates /tmp/cc \
  -c http.extraheader="Authorization: Basic $AUTH"                 # match와 동일한 방식으로 검증
printf '%s' "$AUTH" | gh secret set MATCH_GIT_BASIC_AUTHORIZATION  # 검증된 값을 그대로
```

**교훈** — 에러 코드를 구분해 읽어야 한다. **401(토큰 무효) / 403(권한 없음) / 400(형식 오류)** 는 원인이 완전히 다르다. 하나로 뭉뚱그리면 엉뚱한 데를 고친다.

---

## 12. 스텁으론 안 보이던 실데이터 이슈 (실기기 스모크 테스트)

**증상** — 실기기에서 실제 API로 돌리자 (1) 일부 표지가 회색으로 안 뜨고, (2) 운영시간·책 소개에 `&middot;` `&lt;` `&gt;` 같은 HTML 엔티티가 그대로 노출됐다.

**원인**
- **표지** — 정보나루가 같은 호스트를 http/https **혼재**로 반환한다. ATS가 http를 차단해 http 표지만 안 떴다.
- **텍스트** — API가 일부 필드를 HTML 이스케이프해 주는데, 매핑이 그대로 화면에 전달했다.

**왜 CI/스텁에서 못 잡았나** — 모든 테스트가 내가 작성한 응답 스텁 기반이라, 실제 응답의 스킴 혼재·엔티티가 재현되지 않았다. **스텁은 내가 아는 것만 검증한다.**

**해결**
- 표지 URL을 매핑에서 http → https로 승격(같은 호스트가 https도 서비스). ATS를 약화하는 예외 대신 스킴만 올렸다.
- `String.htmlUnescaped`(이름·숫자·16진 엔티티 디코더)를 만들어 서지·운영시간·소개 매핑에 적용. 디코딩 테스트를 함께 추가.

**교훈** — 통합 지점은 실데이터로 한 번은 반드시 눈으로 확인해야 한다. 스텁 그린은 매핑이 맞다는 증거가 아니다.

---

## 11. 홈 화면 앱 이름이 "App"으로 표기됨

**증상** — 실기기에 설치하니 아이콘 아래 이름이 "책나루"가 아니라 "App"이었다.

**원인** — 표시 이름을 지정하지 않아 프로덕트명(타깃명 `App`)이 그대로 노출됐다. 구성(Debug/Release)과 무관하며 TestFlight 빌드도 마찬가지다.

**해결** — `Info.plist`에 `CFBundleDisplayName`·`CFBundleName`을 `책나루`로 지정.

---

## 10. 실기기 빌드가 프로비저닝 프로파일을 요구함

**증상** — 시뮬레이터·TestFlight 아카이브는 되는데, 실기기 빌드에서 *"App requires a provisioning profile"* 로 실패했다.

**원인** — 배포용으로 App 타깃 **Release만 수동 서명(match)** 을 걸고 Debug는 서명 방식을 비워뒀다. 시뮬레이터는 서명이 필요 없어 통과했지만, 실기기는 프로파일이 필요하다.

**해결** — Debug 구성에 `CODE_SIGN_STYLE = Automatic`을 명시했다. Debug는 자동 서명(로컬 개발), Release는 match 수동 서명(배포)으로 **구성별 분리**. 팀은 공통(base)으로 둔다.

**교훈** — 시뮬레이터 빌드 성공은 서명이 맞다는 증거가 아니다. 서명은 실기기·아카이브에서만 드러난다.

---

## 9. TestFlight 업로드가 앱 아이콘 누락으로 거부됨 (90022)

**증상** — `fastlane beta`가 아카이브·업로드까지 갔다가 검증에서 실패했다.
*"Missing required icon file ... '120x120' ... (90022)"*

**원인** — asset catalog에 `AppIcon`이 없었다. 그동안 아이콘 없이도 시뮬레이터 빌드·테스트는 통과해 눈치채지 못했다.

**해결** — 1024×1024 단일 아이콘(알파 없음)을 `AppIcon.appiconset`에 넣고, App 타깃에 `resources`와 `ASSETCATALOG_COMPILER_APPICON_NAME`을 지정. actool이 120×120 포함 전 크기를 생성한다.

**부수 확인** — App Store 아이콘은 **알파 채널을 허용하지 않는다**. SVG→PNG 변환 후 CoreGraphics로 불투명 평탄화해 `hasAlpha: no`를 확인했다.

---

## 8. CI 시뮬레이터 destination 이름 불일치

**증상** — `-destination "name=iPhone 17"`로 지정한 테스트가
"no available devices matched the request"로 실패했다.

**원인** — Xcode 26.3에 마운트된 런타임은 iOS 26.2이고,
해당 런타임의 기기는 `iPhone 17 Pro`였다.
destination의 name 매칭은 완전 일치라 `Pro` 누락으로 실패했다.

**진단 과정의 오류** — 에러 메시지의 "Available destinations"에
placeholder만 나열된 것을 런타임 부재로 오독했다.
`xcrun simctl list runtimes`로 확인하자 런타임은 정상 존재했고,
기기 이름만 달랐다. **에러 메시지가 나열하지 않는 것과
존재하지 않는 것은 다르다.**

**해결** — 이름 하드코딩을 제거하고
런타임 조회 → iPhone 기기 UDID 해석 → `-destination "id=$UDID"` 방식으로 전환했다.
기기가 없으면 `simctl create`로 생성하는 폴백도 함께 넣었다.

**교훈** — 시뮬레이터 이름은 Xcode 버전에 따라 바뀌는 값이다.
CI에 고정값으로 넣으면 runner 이미지 갱신마다 깨진다.

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
