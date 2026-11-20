import Foundation
import SplitLogging

var printed: [String] = []

struct CapturePrinter: LogPrinter {
    func stdout(_ items: Any...) {
        let line = items.map { "\($0)" }.joined(separator: " ")
        printed.append(line)
        print(line)
    }
}

Logger.shared.printer = CapturePrinter()
Logger.shared.level = .info
Logger.i("Cloud Agent smoke: SplitLogging")
Logger.w("warning path", "ctx")

guard printed.contains(where: { $0.contains("Cloud Agent smoke") }) else {
    fputs("smoke: expected log line missing\n", stderr)
    exit(1)
}

print("OK: SplitLogging smoke passed")
