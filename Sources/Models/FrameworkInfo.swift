import Foundation

struct FrameworkInfo {
    let name: String
    let type: String
    let isEmbedded: String
    let count: Int
    
    init(name: String, count: Int) {
        self.name = name
        self.type = ""
        self.isEmbedded = ""
        self.count = count
    }
    
    init(name: String, type: String, isEmbedded: String) {
        self.name = name
        self.type = type
        self.isEmbedded = isEmbedded
        self.count = 1
    }
}
