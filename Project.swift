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
            destinations: .iOS,
            product: .app,
            bundleId: bundleIDPrefix,
            deploymentTargets: deploymentTarget,
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
                "NSLocationWhenInUseUsageDescription":
                    "내 주변 도서관을 거리순으로 보여주기 위해 위치 정보를 사용합니다."
            ]),
            sources: ["Modules/App/Sources/**"],
            dependencies: [
                .target(name: "Feature"),
                .target(name: "Data")
            ],
            settings: .settings(
                base: sharedBaseSettings.merging(
                    ["SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor"]
                ) { _, new in new }
            )
        ),

        unitTest(for: "Domain"),
        unitTest(for: "Data")
    ],
    schemes: [
        .scheme(
            name: "Booknaru",
            shared: true,
            buildAction: .buildAction(targets: ["App"]),
            testAction: .targets(
                [
                    .testableTarget(target: "DomainTests"),
                    .testableTarget(target: "DataTests")
                ],
                options: .options(coverage: true, codeCoverageTargets: ["Domain", "Data"])
            ),
            runAction: .runAction(executable: "App")
        )
    ],
)
