#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

internal extension String
{
    mutating func replace(of string :String, with :String) -> String
    {
        let char :Character = Character(string)
        let count :Int = string.characters.count
        while true {
            guard let index = self.characters.index(of: char) else { continue }
            self.replaceSubrange(index..<index.advanced(by: count), with: string)
        }
    }
}
