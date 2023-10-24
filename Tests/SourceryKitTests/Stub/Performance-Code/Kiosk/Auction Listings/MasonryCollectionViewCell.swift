import ORStackView
import RxSwift
import UIKit

let MasonryCollectionViewCellWidth: CGFloat = 254

class MasonryCollectionViewCell: ListingsCollectionViewCell {
    fileprivate lazy var bidView: UIView = {
        let view = UIView()
        for subview in [self.currentBidLabel, self.numberOfBidsLabel] {
            view.addSubview(subview)
            subview.alignTopEdge(with: view, predicate: "13")
            subview.alignBottomEdge(with: view, predicate: "0")
            subview.constrainHeight("18")
        }
        self.currentBidLabel.alignLeadingEdge(with: view, predicate: "0")
        self.numberOfBidsLabel.alignTrailingEdge(with: view, predicate: "0")
        return view
    }()

    private var artworkImageViewHeightConstraint: NSLayoutConstraint?

    private let stackView = ORTagBasedAutoStackView()

    override func setup() {
        super.setup()

        contentView.constrainWidth("\(MasonryCollectionViewCellWidth)")

        contentView.addSubview(stackView)
        stackView.align(to: contentView)

        let whitespaceGobbler = WhitespaceGobbler()

        let stackViewSubviews = [artworkImageView, lotNumberLabel, artistNameLabel, artworkTitleLabel, estimateLabel, bidView, bidButton, moreInfoLabel, whitespaceGobbler]
        for (index, subview) in stackViewSubviews.enumerated() {
            subview.tag = index
        }

        stackView.addSubview(artworkImageView, withTopMargin: "0", sideMargin: "0")
        stackView.addSubview(lotNumberLabel, withTopMargin: "20", sideMargin: "0")
        stackView.addSubview(artistNameLabel, withTopMargin: "20", sideMargin: "0")
        stackView.addSubview(artworkTitleLabel, withTopMargin: "10", sideMargin: "0")
        stackView.addSubview(estimateLabel, withTopMargin: "10", sideMargin: "0")
        stackView.addSubview(bidView, withTopMargin: "13", sideMargin: "0")
        stackView.addSubview(bidButton, withTopMargin: "13", sideMargin: "0")
        stackView.addSubview(moreInfoLabel, withTopMargin: "0", sideMargin: "0")
        stackView.addSubview(whitespaceGobbler, withTopMargin: "0", sideMargin: "0")

        artistNameLabel.constrainHeight("20")
        artworkTitleLabel.constrainHeight("16")
        estimateLabel.constrainHeight("16")

        moreInfoLabel.constrainHeight("44")

        viewModel.flatMapTo(SaleArtworkViewModel.lotNumber)
            .map(\.isNilOrEmpty)
            .subscribe(onNext: removeLabelWhenEmpty(label: lotNumberLabel, topMargin: "20"))
            .addDisposableTo(rx_disposeBag)

        viewModel
            .map(\.estimateString)
            .map(\.isEmpty)
            .subscribe(onNext: removeLabelWhenEmpty(label: estimateLabel, topMargin: "10"))
            .addDisposableTo(rx_disposeBag)

        viewModel
            .map(\.artistName)
            .map(\.isNilOrEmpty)
            .subscribe(onNext: removeLabelWhenEmpty(label: artistNameLabel, topMargin: "20"))
            .addDisposableTo(rx_disposeBag)

        // Binds the imageView to always be the correct aspect ratio
        viewModel.subscribe(onNext: { [weak self] viewModel in
            if let artworkImageViewHeightConstraint = self?.artworkImageViewHeightConstraint {
                self?.artworkImageView.removeConstraint(artworkImageViewHeightConstraint)
            }
            let imageHeight = heightForImage(withAspectRatio: viewModel.thumbnailAspectRatio)
            self?.artworkImageViewHeightConstraint = self?.artworkImageView.constrainHeight("\(imageHeight)").first as? NSLayoutConstraint
            self?.layoutIfNeeded()
        })
        .addDisposableTo(rx_disposeBag)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bidView.drawTopDottedBorder(with: .artsyGrayMedium())
    }

    func removeLabelWhenEmpty(label: UIView, topMargin: String) -> (Bool) -> Void {
        { [weak self] isEmpty in
            guard let self else { return }
            if isEmpty {
                stackView.removeSubview(label)
            } else {
                stackView.addSubview(label, withTopMargin: topMargin, sideMargin: "0")
            }
        }
    }
}

extension MasonryCollectionViewCell {
    class func heightForCellWithImageAspectRatio(_ aspectRatio: CGFloat?, hasEstimate: Bool) -> CGFloat {
        let imageHeight = heightForImage(withAspectRatio: aspectRatio)
        let estimateHeight =
            16 + // estimate
            13 // padding
        let remainingHeight =
            20 + // padding
            20 + // artist name
            10 + // padding
            16 + // artwork name
            10 + // padding
            13 + // padding
            16 + // bid
            13 + // padding
            44 + // more info button
            12 // padding

        return imageHeight + ButtonHeight + CGFloat(remainingHeight) + CGFloat(hasEstimate ? estimateHeight : 0)
    }
}

private func heightForImage(withAspectRatio aspectRatio: CGFloat?) -> CGFloat {
    if let ratio = aspectRatio {
        if ratio != 0 {
            return CGFloat(MasonryCollectionViewCellWidth) / ratio
        }
    }
    return CGFloat(MasonryCollectionViewCellWidth)
}
