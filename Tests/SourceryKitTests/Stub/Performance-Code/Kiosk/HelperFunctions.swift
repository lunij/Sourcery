import Foundation

// Collection of stanardised mapping funtions for Rx work

func stringIsEmailAddress(_ text: String) -> Bool {
    let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
    let testPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
    return testPredicate.evaluate(with: text)
}

func centsToPresentableDollarsString(_ cents: Int) -> String {
    guard let dollars = NumberFormatter.currencyString(forDollarCents: cents as NSNumber!) else {
        return ""
    }

    return dollars
}

func isZeroLength(string: String) -> Bool {
    string.isEmpty
}

func isStringLength(in range: Range<Int>) -> (String) -> Bool {
    { string in
        range.contains(string.count)
    }
}

func isStringOf(length: Int) -> (String) -> Bool {
    { string in
        string.count == length
    }
}

func isStringLengthAtLeast(length: Int) -> (String) -> Bool {
    { string in
        string.count >= length
    }
}

func isStringLength(oneOf lengths: [Int]) -> (String) -> Bool {
    { string in
        lengths.contains(string.count)
    }
}

// Useful for mapping an Observable<Whatever> into an Observable<Void> to hide details.
func void(_: some Any) {
    ()
}
