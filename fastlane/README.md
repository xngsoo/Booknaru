fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios certificates

```sh
[bundle exec] fastlane ios certificates
```

서명 자산 최초 생성/갱신 (로컬에서 1회) — 인증서·프로파일을 만들어 certs repo에 push

### ios test

```sh
[bundle exec] fastlane ios test
```

테스트 실행 (자격증명 불필요 — 지금 바로 검증 가능)

### ios beta

```sh
[bundle exec] fastlane ios beta
```

TestFlight 베타 배포

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
