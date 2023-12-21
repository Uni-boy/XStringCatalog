import StringCatalogEnumLibrary
import ArgumentParser
import Foundation


struct StringCatalogEnum: ParsableCommand {
    enum Error: Swift.Error {
        case unexpectedJSON(message: String? = nil)
    }

    enum Keyword: String, CaseIterable {
        case `continue`, `default`
    }

    // @Argument(help: "Add an new argument.")
    // var argument: String

    // @Flag(help: "Add a new flag.")
    // var flag = false

    @Option(name: .long, help: "Full path and filename of the 'xcstrings' file.")
    var xcstringsPath: String

    @Option(name: .long, help: "Full path and filename of the generated Swift file.")
    var outputFilename: String

    @Option(name: .long, help: "Generated enum name.")
    var enumName: String = "XcodeStringKey"

    @Option(name: .long, help: "A typealias of the generated enum name.")
    var enumTypealias: String = "XCS"

    func run() throws {
        let helper = StringEnumHelper()
        print("LOADING: \(xcstringsPath)")
        let url = URL(fileURLWithPath: xcstringsPath)
        let data = try Data(contentsOf: url)
        print(data)

        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw Error.unexpectedJSON(message: "cannot parse first level object")
        }
            
        guard let strings = json["strings"] as? [String: Any] else {
            throw Error.unexpectedJSON(message: "cannot parse `strings`")
        }

        var output = """
            // This file is generated by XcodeStringEnum. Please do *NOT* update it manually.
            // As a common practice, swiftLint is disabled for generated files.
            // swiftlint:disable all

            import SwiftUI

            /// Makes it a bit easier to type.
            typealias \(enumTypealias) = \(enumName)

            /// Generated by StringCatalogEnum, this enum contains all existing Strin Category keys.
            enum \(enumName): String, CaseIterable {

            """
        let keywordRawValues = getKeywordRawValues()
        let firstCases = helper.createEnumKeys(with: strings, keyNameMatches: true, keywordEnum: keywordRawValues)
        let secondCases = helper.createEnumKeys(with: strings, keyNameMatches: false, keywordEnum: keywordRawValues)

        output += """
                    
        \(firstCases)
                    
        // MARK: - The following cases should be manually replaced in your codebase.
                    
        \(secondCases)

        /// Usage: `SwiftUI.Text(\(enumTypealias).yourStringCatalogKey.key)`
        var key: LocalizedStringKey { LocalizedStringKey(rawValue) }

        var string: String { NSLocalizedString(self.rawValue, comment: "Generated localization from String Catalog key: \\(key)") }

        // var text: String.LocalizationValue { String.LocalizationValue(rawValue) }
        }
        // swiftlint:enable all
        """

        print(output)
        let outputURL = URL(fileURLWithPath: outputFilename)
        try output.write(to: outputURL, atomically: true, encoding: .utf8)
        print("Written to: \(outputFilename)")
    }
    
    func getKeywordRawValues() -> [String] {
        return Keyword.allCases.map { $0.rawValue }
    }

}

StringCatalogEnum.main()
