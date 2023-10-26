import Foundation

/// Phantom protocol for diffing
protocol AutoDiffable {}

/// Phantom protocol for equality
protocol AutoEquatable {}

/// Phantom protocol for equality
protocol AutoDescription {}

/// Phantom protocol for NSCoding
protocol AutoCoding {}

/// Phantom protocol for NSCoding, Equatable and Diffable
protocol SourceryModelWithoutDescription: AutoDiffable, AutoEquatable, AutoCoding {}

protocol SourceryModel: SourceryModelWithoutDescription, AutoDescription {}
