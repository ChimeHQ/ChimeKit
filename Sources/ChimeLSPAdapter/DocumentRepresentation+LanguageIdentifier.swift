import Foundation

import ChimeExtensionInterface
import LanguageServerProtocol
import UniformTypeIdentifiers

public extension UTType {
    static let goSource = UTType(importedAs: "public.go-source")
    static let goModFile = UTType(importedAs: "public.go-module")
    static let goSumFile = UTType(importedAs: "public.go-sum")
}

extension DocumentContext {
    var languageIdentifier: LanguageIdentifier? {
        if uti.conforms(to: .rubyScript) {
            return .ruby
        }

        if uti.conforms(to: .goSource) || uti.conforms(to: .goModFile) {
            return .go
        }

        return nil
    }
}
