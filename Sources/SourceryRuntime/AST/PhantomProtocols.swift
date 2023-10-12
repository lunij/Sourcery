import Foundation

/// Phantom protocol for diffing
protocol AutoDiffable {}

/// Phantom protocol for equality
protocol AutoEquatable {}

/// Phantom protocol for equality
protocol AutoDescription {}

/// Phantom protocol for NSCoding
protocol AutoCoding {}

protocol AutoJSExport {}

/// Phantom protocol for NSCoding, Equatable and Diffable
protocol SourceryModelWithoutDescription: AutoDiffable, AutoEquatable, AutoCoding, AutoJSExport {}

protocol SourceryModel: SourceryModelWithoutDescription, AutoDescription {}
