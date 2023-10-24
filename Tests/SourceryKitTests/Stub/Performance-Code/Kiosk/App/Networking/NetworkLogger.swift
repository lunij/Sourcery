import Foundation
import Moya
import Result

/// Logs network activity (outgoing requests and incoming responses).
class NetworkLogger: PluginType {
    typealias Comparison = (TargetType) -> Bool

    let whitelist: Comparison
    let blacklist: Comparison

    init(whitelist: @escaping Comparison = { _ -> Bool in true }, blacklist: @escaping Comparison = { _ -> Bool in true }) {
        self.whitelist = whitelist
        self.blacklist = blacklist
    }

    func willSendRequest(_ request: RequestType, target: TargetType) {
        // If the target is in the blacklist, don't log it.
        guard blacklist(target) == false else { return }
        logger.log("Sending request: \(request.request?.url?.absoluteString ?? String())")
    }

    func didReceiveResponse(_ result: Result<Moya.Response, Moya.Error>, target: TargetType) {
        // If the target is in the blacklist, don't log it.
        guard blacklist(target) == false else { return }

        switch result {
        case let .success(response):
            if 200 ..< 400 ~= (response.statusCode), whitelist(target) == false {
                // If the status code is OK, and if it's not in our whitelist, then don't worry about logging its response body.
                logger.log("Received response(\(response.statusCode)) from \(response.response?.url?.absoluteString ?? String()).")
            }
        case let .failure(error):
            // Otherwise, log everything.
            logger.log("Received networking error: \(error)")
        }
    }
}
