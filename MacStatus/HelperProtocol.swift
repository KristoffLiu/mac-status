import Foundation

@objc public protocol HelperProtocol {
    func getRealTimePower(withReply reply: @escaping (Double, Double, Double) -> Void)
}
