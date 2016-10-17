import PackageDescription

let package = Package(
    name: "FluentTester",
    dependencies: [
    	.Package(url: "https://github.com/vapor/fluent.git", versions: Version(1,0,0) ..< Version(2,0,0))
    ]
)
