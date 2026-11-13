import Foundation
import Kingfisher
import LivetexCore

final class LivetexImageChallengeResponder: AuthenticationChallengeResponsible {

    static let shared = LivetexImageChallengeResponder()

    func downloader(_ downloader: ImageDownloader,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        LivetexTrust.handle(challenge, completionHandler: completionHandler)
    }

    func downloader(_ downloader: ImageDownloader,
                    task: URLSessionTask,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        LivetexTrust.handle(challenge, completionHandler: completionHandler)
    }
}
