import Foundation

struct Display: Identifiable, Hashable {
    let id: String
    let index: Int
    let vendorID: String
    let productID: String
    let name: String
    var isAppleSilicon: Bool

    var description: String {
        "\(name) (\(vendorID):\(productID))"
    }
}
