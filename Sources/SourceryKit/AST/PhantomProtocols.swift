import Foundation

/// Phantom protocol for diffing
protocol AutoDiffable {}

/// Phantom protocol for equality
protocol AutoEquatable {}

/// Phantom protocol for equality
protocol AutoDescription {}

/// Phantom protocol for NSCoding, Equatable and Diffable
protocol SourceryModelWithoutDescription: AutoDiffable, AutoEquatable {}

protocol SourceryModel: SourceryModelWithoutDescription, AutoDescription {}
