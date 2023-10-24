import Alamofire
import Foundation
import Moya
import RxSwift

protocol ArtsyAPIType {
    var addXAuth: Bool { get }
}

enum ArtsyAPI {
    case xApp
    case xAuth(email: String, password: String)
    case trustToken(number: String, auctionPIN: String)

    case systemTime
    case ping

    case artwork(id: String)
    case artist(id: String)

    case auctions
    case auctionListings(id: String, page: Int, pageSize: Int)
    case auctionInfo(auctionID: String)
    case auctionInfoForArtwork(auctionID: String, artworkID: String)
    case findBidderRegistration(auctionID: String, phone: String)
    case activeAuctions

    case createUser(email: String, password: String, phone: String, postCode: String, name: String)

    case bidderDetailsNotification(auctionID: String, identifier: String)

    case lostPasswordNotification(email: String)
    case findExistingEmailRegistration(email: String)
}

enum ArtsyAuthenticatedAPI {
    case myCreditCards
    case createPINForBidder(bidderID: String)
    case registerToBid(auctionID: String)
    case myBiddersForAuction(auctionID: String)
    case myBidPositionsForAuctionArtwork(auctionID: String, artworkID: String)
    case myBidPosition(id: String)
    case findMyBidderRegistration(auctionID: String)
    case placeABid(auctionID: String, artworkID: String, maxBidCents: String)

    case updateMe(email: String, phone: String, postCode: String, name: String)
    case registerCard(stripeToken: String, swiped: Bool)
    case me
}

extension ArtsyAPI: TargetType, ArtsyAPIType {
    public var task: Task {
        .request
    }

    var path: String {
        switch self {
        case .xApp:
            "/api/v1/xapp_token"

        case .xAuth:
            "/oauth2/access_token"

        case let .auctionInfo(id):
            "/api/v1/sale/\(id)"

        case .auctions:
            "/api/v1/sales"

        case let .auctionListings(id, _, _):
            "/api/v1/sale/\(id)/sale_artworks"

        case let .auctionInfoForArtwork(auctionID, artworkID):
            "/api/v1/sale/\(auctionID)/sale_artwork/\(artworkID)"

        case .systemTime:
            "/api/v1/system/time"

        case .ping:
            "/api/v1/system/ping"

        case .findBidderRegistration:
            "/api/v1/bidder"

        case .activeAuctions:
            "/api/v1/sales"

        case .createUser:
            "/api/v1/user"

        case let .artwork(id):
            "/api/v1/artwork/\(id)"

        case let .artist(id):
            "/api/v1/artist/\(id)"

        case .trustToken:
            "/api/v1/me/trust_token"

        case .bidderDetailsNotification:
            "/api/v1/bidder/bidding_details_notification"

        case .lostPasswordNotification:
            "/api/v1/users/send_reset_password_instructions"

        case .findExistingEmailRegistration:
            "/api/v1/user"
        }
    }

    var base: String { AppSetup.sharedState.useStaging ? "https://stagingapi.artsy.net" : "https://api.artsy.net" }
    var baseURL: URL { URL(string: base)! }

    var parameters: [String: Any]? {
        switch self {
        case let .xAuth(email, password):
            [
                "client_id": APIKeys.sharedKeys.key as AnyObject? ?? "" as AnyObject,
                "client_secret": APIKeys.sharedKeys.secret as AnyObject? ?? "" as AnyObject,
                "email": email as AnyObject,
                "password": password as AnyObject,
                "grant_type": "credentials" as AnyObject
            ]

        case .xApp:
            [
                "client_id": APIKeys.sharedKeys.key as AnyObject? ?? "" as AnyObject,
                "client_secret": APIKeys.sharedKeys.secret as AnyObject? ?? "" as AnyObject
            ]

        case .auctions:
            ["is_auction": "true" as AnyObject]

        case let .trustToken(number, auctionID):
            ["number": number as AnyObject, "auction_pin": auctionID as AnyObject]

        case let .createUser(email, password, phone, postCode, name):
            [
                "email": email as AnyObject, "password": password as AnyObject,
                "phone": phone as AnyObject, "name": name as AnyObject,
                "location": ["postal_code": postCode] as AnyObject
            ]

        case let .bidderDetailsNotification(auctionID, identifier):
            ["sale_id": auctionID as AnyObject, "identifier": identifier as AnyObject]

        case let .lostPasswordNotification(email):
            ["email": email as AnyObject]

        case let .findExistingEmailRegistration(email):
            ["email": email as AnyObject]

        case let .findBidderRegistration(auctionID, phone):
            ["sale_id": auctionID as AnyObject, "number": phone as AnyObject]

        case let .auctionListings(_, page, pageSize):
            ["size": pageSize as AnyObject, "page": page as AnyObject]

        case .activeAuctions:
            ["is_auction": true as AnyObject, "live": true as AnyObject]

        default:
            nil
        }
    }

    var method: Moya.Method {
        switch self {
        case .lostPasswordNotification,
             .createUser:
            .post
        case .findExistingEmailRegistration:
            .head
        case .bidderDetailsNotification:
            .put
        default:
            .get
        }
    }

    var sampleData: Data {
        switch self {
        case .xApp:
            stubbedResponse("XApp")

        case .xAuth:
            stubbedResponse("XAuth")

        case .trustToken:
            stubbedResponse("XAuth")

        case .auctions:
            stubbedResponse("Auctions")

        case .auctionListings:
            stubbedResponse("AuctionListings")

        case .systemTime:
            stubbedResponse("SystemTime")

        case .activeAuctions:
            stubbedResponse("ActiveAuctions")

        case .createUser:
            stubbedResponse("Me")

        case .artwork:
            stubbedResponse("Artwork")

        case .artist:
            stubbedResponse("Artist")

        case .auctionInfo:
            stubbedResponse("AuctionInfo")

        // This API returns a 302, so stubbed response isn't valid
        case .findBidderRegistration:
            stubbedResponse("Me")

        case .bidderDetailsNotification:
            stubbedResponse("RegisterToBid")

        case .lostPasswordNotification:
            stubbedResponse("ForgotPassword")

        case .findExistingEmailRegistration:
            stubbedResponse("ForgotPassword")

        case .auctionInfoForArtwork:
            stubbedResponse("AuctionInfoForArtwork")

        case .ping:
            stubbedResponse("Ping")
        }
    }

    var addXAuth: Bool {
        switch self {
        case .xApp: false
        case .xAuth: false
        default: true
        }
    }
}

extension ArtsyAuthenticatedAPI: TargetType, ArtsyAPIType {
    public var task: Task {
        .request
    }

    var path: String {
        switch self {
        case .registerToBid:
            "/api/v1/bidder"

        case .myCreditCards:
            "/api/v1/me/credit_cards"

        case let .createPINForBidder(bidderID):
            "/api/v1/bidder/\(bidderID)/pin"

        case .me:
            "/api/v1/me"

        case .updateMe:
            "/api/v1/me"

        case .myBiddersForAuction:
            "/api/v1/me/bidders"

        case .myBidPositionsForAuctionArtwork:
            "/api/v1/me/bidder_positions"

        case let .myBidPosition(id):
            "/api/v1/me/bidder_position/\(id)"

        case .findMyBidderRegistration:
            "/api/v1/me/bidders"

        case .placeABid:
            "/api/v1/me/bidder_position"

        case .registerCard:
            "/api/v1/me/credit_cards"
        }
    }

    var base: String { AppSetup.sharedState.useStaging ? "https://stagingapi.artsy.net" : "https://api.artsy.net" }
    var baseURL: URL { URL(string: base)! }

    var parameters: [String: Any]? {
        switch self {
        case let .registerToBid(auctionID):
            ["sale_id": auctionID as AnyObject]

        case let .myBiddersForAuction(auctionID):
            ["sale_id": auctionID as AnyObject]

        case let .placeABid(auctionID, artworkID, maxBidCents):
            [
                "sale_id": auctionID as AnyObject,
                "artwork_id": artworkID as AnyObject,
                "max_bid_amount_cents": maxBidCents as AnyObject
            ]

        case let .findMyBidderRegistration(auctionID):
            ["sale_id": auctionID as AnyObject]

        case let .updateMe(email, phone, postCode, name):
            [
                "email": email as AnyObject, "phone": phone as AnyObject,
                "name": name as AnyObject, "location": ["postal_code": postCode]
            ]

        case let .registerCard(token, swiped):
            ["provider": "stripe" as AnyObject, "token": token as AnyObject, "created_by_trusted_client": swiped as AnyObject]

        case let .myBidPositionsForAuctionArtwork(auctionID, artworkID):
            ["sale_id": auctionID as AnyObject, "artwork_id": artworkID as AnyObject]

        default:
            nil
        }
    }

    var method: Moya.Method {
        switch self {
        case .placeABid,
             .registerCard,
             .registerToBid,
             .createPINForBidder:
            .post
        case .updateMe:
            .put
        default:
            .get
        }
    }

    var sampleData: Data {
        switch self {
        case .createPINForBidder:
            stubbedResponse("CreatePINForBidder")

        case .myCreditCards:
            stubbedResponse("MyCreditCards")

        case .registerToBid:
            stubbedResponse("RegisterToBid")

        case .myBiddersForAuction:
            stubbedResponse("MyBiddersForAuction")

        case .me:
            stubbedResponse("Me")

        case .updateMe:
            stubbedResponse("Me")

        case .placeABid:
            stubbedResponse("CreateABid")

        case .findMyBidderRegistration:
            stubbedResponse("FindMyBidderRegistration")

        case .registerCard:
            stubbedResponse("RegisterCard")

        case .myBidPositionsForAuctionArtwork:
            stubbedResponse("MyBidPositionsForAuctionArtwork")

        case .myBidPosition:
            stubbedResponse("MyBidPosition")
        }
    }

    var addXAuth: Bool {
        true
    }
}

// MARK: - Provider support

func stubbedResponse(_ filename: String) -> Data! {
    @objc class TestClass: NSObject {}

    let bundle = Bundle(for: TestClass.self)
    let path = bundle.path(forResource: filename, ofType: "json")
    return (try? Data(contentsOf: URL(fileURLWithPath: path!)))
}

private extension String {
    var URLEscapedString: String {
        addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)!
    }
}

func url(_ route: TargetType) -> String {
    route.baseURL.appendingPathComponent(route.path).absoluteString
}
