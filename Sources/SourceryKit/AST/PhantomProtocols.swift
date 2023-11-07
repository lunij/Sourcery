import Foundation

/// Phantom protocol for diffing
protocol AutoDiffable {}

/// Phantom protocol for equality
protocol AutoEquatable {}

/// Phantom protocol for Equatable and Diffable
protocol SourceryModelWithoutDescription: AutoDiffable, AutoEquatable {}

protocol SourceryModel: SourceryModelWithoutDescription {}
