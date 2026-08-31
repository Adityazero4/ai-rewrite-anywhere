import Foundation

// Run with `make test` (or `swift run PencilMarkCoreTests`).
runRewriteModeTests()
runShortcutTests()
await runOpenAIClientTests()
runAppSettingsTests()
runKeychainTests()
await runClipboardTests()
await runRewriteCoordinatorTests()
await runGuardrailTests()

exit(t.summarize())
