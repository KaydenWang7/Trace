import UIKit

let symbols = ["pencil.and.list.clipboard", "folder", "square.and.pencil", "hand.draw", "map"]
for symbol in symbols {
    if UIImage(systemName: symbol) != nil {
        print("\(symbol): YES")
    } else {
        print("\(symbol): NO")
    }
}
