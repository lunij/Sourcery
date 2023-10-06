
import Foundation

protocol AutoLenses {}

struct House: AutoLenses {
    let rooms: Room
    let address: String
    let size: Int
}

struct Room: AutoLenses {
    let people: [Person]
    let name: String
}

struct Person: AutoLenses {
    let name: String
}

// swiftlint:disable identifier_name
struct Rectangle: AutoLenses {
    let x: Int
    let y: Int

    var area: Int {
        return x*y
    }
}
