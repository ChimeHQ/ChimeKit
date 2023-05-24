import Foundation

import ChimeExtensionInterface
import LanguageServerProtocol

extension DocumentContext {
    var languageIdentifier: String? {
		if uti.conforms(to: .cSource) || uti.conforms(to: .cHeader) {
			return LanguageIdentifier.c.rawValue
		}

		if uti.conforms(to: .cPlusPlusSource) || uti.conforms(to: .cPlusPlusHeader) {
			return LanguageIdentifier.cpp.rawValue
		}

		if uti.conforms(to: .cSharpSource) {
			return LanguageIdentifier.csharp.rawValue
		}

		if uti.conforms(to: .cssSource) {
			return LanguageIdentifier.css.rawValue
		}

		if uti.conforms(to: .elixirSource) {
			return LanguageIdentifier.elixir.rawValue
		}

		if uti.conforms(to: .goSource) || uti.conforms(to: .goModFile) || uti.conforms(to: .goWorkFile) {
			return LanguageIdentifier.go.rawValue
		}

		if uti.conforms(to: .haskellSource) {
			return "haskell"
		}

		if uti.conforms(to: .html) {
			return LanguageIdentifier.html.rawValue
		}

		if uti.conforms(to: .javaSource) {
			return LanguageIdentifier.java.rawValue
		}

		if uti.conforms(to: .javaScript) {
			return LanguageIdentifier.javascript.rawValue
		}

		if uti.conforms(to: .json) {
			return LanguageIdentifier.json.rawValue
		}

		if uti.conforms(to: .juliaSource) {
			return "julia"
		}

		if uti.conforms(to: .luaSource) {
			return LanguageIdentifier.lua.rawValue
		}

		if uti.conforms(to: .markdown) {
			return LanguageIdentifier.markdown.rawValue
		}

		if uti.conforms(to: .perlScript) {
			return LanguageIdentifier.perl.rawValue
		}

		if uti.conforms(to: .phpScript) {
			return LanguageIdentifier.php.rawValue
		}

		if uti.conforms(to: .pythonScript) {
			return LanguageIdentifier.python.rawValue
		}

		if uti.conforms(to: .rubyScript) {
			return LanguageIdentifier.ruby.rawValue
		}

		if uti.conforms(to: .rustSource) {
			return LanguageIdentifier.rust.rawValue
		}

		if uti.conforms(to: .sqlSource) {
			return LanguageIdentifier.sql.rawValue
		}

		if uti.conforms(to: .swiftSource) {
			return LanguageIdentifier.swift.rawValue
		}

		if uti.conforms(to: .typescriptSource) {
			return LanguageIdentifier.typescript.rawValue
		}

		if uti.conforms(to: .typescriptJSXSource) {
			return LanguageIdentifier.typescriptreact.rawValue
		}

		if uti.conforms(to: .yaml) {
			return LanguageIdentifier.yaml.rawValue
		}

		if uti.conforms(to: .zigSource) {
			return "zig"
		}

        return nil
    }
}
