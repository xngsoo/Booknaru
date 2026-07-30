import ProjectDescription

let bundleIDPrefix = "com.xngsoo.booknaru"
let deploymentTarget: DeploymentTargets = .iOS("17.0")
let sharedBaseSettings: SettingsDictionary = [
    "SWIFT_VERSION": "6",
    "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
    "SWIFT_UPCOMING_FEATURE_EXISTENTIAL_ANY": "YES"
]

func module(
    name: String,
    isolation: String,
    dependencies: [TargetDependency] = []
) -> Target {
    .target(
        name: name,
        destinations: .iOS,
        product: .framework,
        bundleId: "\(bundleIDPrefix).\(name.lowercased())",
        deploymentTargets: deploymentTarget,
        sources: ["Modules/\(name)/Sources/**"],
        dependencies: dependencies,
        settings: .settings(
            base: sharedBaseSettings.merging(
                ["SWIFT_DEFAULT_ACTOR_ISOLATION": .string(isolation)]
            ) { _, new in new }
        )
    )
}

func unitTest(for name: String, isolation: String = "nonisolated") -> Target {
    .target(
        name: "\(name)Tests",
        destinations: .iOS,
        product: .unitTests,
        bundleId: "\(bundleIDPrefix).\(name.lowercased()).tests",
        deploymentTargets: deploymentTarget,
        sources: ["Modules/\(name)/Tests/**"],
        dependencies: [.target(name: name)],
        settings: .settings(
            base: sharedBaseSettings.merging(
                ["SWIFT_DEFAULT_ACTOR_ISOLATION": .string(isolation)]
            ) { _, new in new }
        )
    )
}

let project = Project(
    name: "Booknaru",
    organizationName: "xngsoo",
    options: .options(automaticSchemesOptions: .disabled),
    settings: .settings(
        configurations: [
            .debug(name: "Debug", xcconfig: "Configs/Debug.xcconfig"),
            .release(name: "Release", xcconfig: "Configs/Release.xcconfig")
        ],
    ),
    targets: [
        module(name: "Domain", isolation: "nonisolated"),
        module(name: "Data", isolation: "nonisolated",
               dependencies: [.target(name: "Domain")]),
        module(name: "DesignSystem", isolation: "MainActor"),
        module(name: "Feature", isolation: "MainActor",
               dependencies: [.target(name: "Domain"), .target(name: "DesignSystem")]),

        .target(
            name: "App",
            destinations: [.iPhone],   // iPhone 전용. .iOS는 iPad까지 포함해 iPad 스크린샷을 요구한다.
            product: .app,
            bundleId: bundleIDPrefix,
            deploymentTargets: deploymentTarget,
            infoPlist: .extendingDefault(with: [
                // 홈 화면 표시 이름. 없으면 프로덕트명("App")이 그대로 노출된다(전 구성 공통).
                "CFBundleDisplayName": "책나루",
                "CFBundleName": "책나루",
                // HTTPS(TLS) 외 비면제 암호화를 쓰지 않음 → 수출 규정 면제.
                // 선언해 두면 TestFlight 업로드마다 뜨는 수출 규정 문서 요청이 사라진다.
                "ITSAppUsesNonExemptEncryption": false,
                "UILaunchScreen": [:],
                "NSLocationWhenInUseUsageDescription":
                    "내 주변 도서관을 거리순으로 보여주기 위해 위치 정보를 사용합니다.",
                // xcconfig(Secrets.xcconfig)의 키를 Info.plist로 노출해 런타임에 읽는다.
                // Secrets.xcconfig가 없는 CI에선 빈 문자열로 해석되어 빌드는 통과한다.
                "DATA4LIBRARY_KEY": "$(DATA4LIBRARY_KEY)",
                "ALADIN_TTB_KEY": "$(ALADIN_TTB_KEY)"
            ]),
            sources: ["Modules/App/Sources/**"],
            resources: ["Modules/App/Resources/**"],
            dependencies: [
                .target(name: "Feature"),
                .target(name: "Data")
            ],
            settings: .settings(
                base: sharedBaseSettings.merging([
                    "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
                    // 팀은 모든 구성 공통. 서명 방식은 아래 구성별로 나눈다.
                    "DEVELOPMENT_TEAM": "LX474376F5",
                    // Assets.xcassets의 AppIcon 사용
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon"
                ]) { _, new in new },
                configurations: [
                    // Debug: 자동 서명 → 실기기 연결 시 Xcode가 개발용 프로파일을 자동 생성.
                    .debug(name: "Debug", settings: [
                        "CODE_SIGN_STYLE": "Automatic"
                    ], xcconfig: "Configs/Debug.xcconfig"),
                    // Release: match가 설치하는 App Store 배포 프로파일로 수동 서명(아카이브 전용).
                    .release(name: "Release", settings: [
                        "CODE_SIGN_STYLE": "Manual",
                        "CODE_SIGN_IDENTITY": "Apple Distribution",
                        "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.xngsoo.booknaru"
                    ], xcconfig: "Configs/Release.xcconfig")
                ]
            )
        ),

        unitTest(for: "Domain"),
        unitTest(for: "Data"),
        unitTest(for: "Feature", isolation: "MainActor")
    ],
    schemes: [
        .scheme(
            name: "Booknaru",
            shared: true,
            buildAction: .buildAction(targets: ["App"]),
            testAction: .targets(
                [
                    .testableTarget(target: "DomainTests"),
                    .testableTarget(target: "DataTests"),
                    .testableTarget(target: "FeatureTests")
                ],
                options: .options(coverage: true, codeCoverageTargets: ["Domain", "Data", "Feature"])
            ),
            runAction: .runAction(executable: "App")
        )
    ],
)
