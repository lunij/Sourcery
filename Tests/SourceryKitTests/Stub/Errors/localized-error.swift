import Foundation

final class Localized: NSObject {
    override fileprivate init() {}
}

extension Localized {
    static func storeEnterRecipientNickname() -> String {
        NSLocalizedString("Please enter the recipient's nickname", comment: "")
    }

    static func storeNameCannotBeEmpty() -> String {
        NSLocalizedString("Sorry, the name can't be empty. Please enter a nickname to send the gift to. You can also send the gift to yourself!", comment: "")
    }

    static func storeSendGiftToUser() -> String {
        NSLocalizedString("Send a gift to ", comment: "")
    }

    static func storeSendStickerPackToUser() -> String {
        NSLocalizedString("Send Free Sticker Pack to ", comment: "label")
    }

    static func storeBuyStickerPackForUser() -> String {
        NSLocalizedString("Buy Sticker Pack for ", comment: "label")
    }

    static func storeAddFreeStickerPackToUser() -> String {
        NSLocalizedString("Add Free Sticker Pack to ", comment: "button")
    }

    static func storeAddFreeStickerPack() -> String {
        NSLocalizedString("Add Free Sticker Pack", comment: "button")
    }

    static func storeNoUserWithNickname() -> String {
        NSLocalizedString("No user exists with that nickname", comment: "")
    }

    static func storeWhosThisGiftGoigTo() -> String {
        NSLocalizedString("Who's this gift going to?", comment: "")
    }

    static func profileGiftFrom(_: String) -> String {
        NSLocalizedString("Gift from %@", comment: "label")
    }

    static func profileGiftFromAnonymous() -> String {
        NSLocalizedString("Gift from Anonymous", comment: "label")
    }

    static func profileInvisibleModeAlert() -> String {
        NSLocalizedString("Invisible mode makes you appear to be offline. To allow special friends to know you are online go to your Settings and add their name to the Visible User List.\nAre you sure you want to do this?", comment: "Alert")
    }

    static func profileNextDateDisplayNameAlert(_: String) -> String {
        NSLocalizedString("Please note that you will not be able to change this until %@", comment: "Warning")
    }

    static func profileGiftSendIMButton() -> String {
        NSLocalizedString("Send IM", comment: "Button")
    }

    static func profileYouHaveNoSubscription() -> String {
        NSLocalizedString("You have no subscription", comment: "Label")
    }

    static func roomSortingMaleFemale() -> String {
        NSLocalizedString("Females/Males", comment: "")
    }

    static func roomSortingAlphabetical() -> String {
        NSLocalizedString("Alphabetical", comment: "")
    }

    static func roomSortingWhosViewingYou() -> String {
        NSLocalizedString("Who's viewing you", comment: "")
    }

    static func roomSortingOnlyAvailableToSubscribers() -> String {
        NSLocalizedString("Sorting features are only available to subscribers", comment: "")
    }

    static func roomSortingUpgradeToChange() -> String {
        NSLocalizedString("Upgrade to change sorting to:", comment: "")
    }

    static func roomPositiveBarUserViewedYourCam(_: String) -> String {
        NSLocalizedString("%@ viewed your webcam", comment: "")
    }

    static func roomPositiveBarUserSentRoomGift(_: String) -> String {
        NSLocalizedString("%@ sent room a gift", comment: "")
    }

    static func roomPositiveBarUserSentUserGift(_: String) -> String {
        NSLocalizedString("%@ sent you a gift", comment: "")
    }

    static func roomPositiveBarYouSentUserGift(_: String) -> String {
        NSLocalizedString("You sent a gift to %@", comment: "")
    }

    static var coinsAreNotAvailableForPurchase: String {
        NSLocalizedString("Sorry, coins aren’t available to be purchased right now. Please try again later", comment: "")
    }
}
