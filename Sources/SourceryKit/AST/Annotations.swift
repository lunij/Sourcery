import Foundation

public typealias Annotations = [String: NSObject]

/// Describes annotated declaration, i.e. type, method, variable, enum case
public protocol Annotated {
    /**
     All annotations of declaration stored by their name. Value can be `bool`, `String`, float `NSNumber`
     or array of those types if you use several annotations with the same name.
    
     **Example:**
     
     ```
     //sourcery: booleanAnnotation
     //sourcery: stringAnnotation = "value"
     //sourcery: numericAnnotation = 0.5
     
     [
      "booleanAnnotation": true,
      "stringAnnotation": "value",
      "numericAnnotation": 0.5
     ]
     ```
    */
    var annotations: Annotations { get }
}

extension Annotations {
    mutating func append(key: String, value: NSObject) {
        if let oldValue = self[key] {
            if var array = oldValue as? [NSObject] {
                if !array.contains(value) {
                    array.append(value)
                    self[key] = array as NSObject
                }
            } else if var oldDict = oldValue as? [String: NSObject], let newDict = value as? [String: NSObject] {
                newDict.forEach { key, value in
                    oldDict.append(key: key, value: value)
                }
                self[key] = oldDict as NSObject
            } else if oldValue != value {
                self[key] = [oldValue, value] as NSObject
            }
        } else {
            self[key] = value
        }
    }
}
