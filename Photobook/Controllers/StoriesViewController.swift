//
//  StoriesViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

class StoriesViewController: UIViewController {

    private struct Constants {
        static let storiesInHeader = 6
        static let rowsInHeader = 4
        static let storiesPerLayoutPattern = 3
        static let rowsPerLayoutPattern = 2
        static let viewStorySegueName = "ViewStorySegue"
    }
    
    @IBOutlet private weak var tableView: UITableView!
    
    private var stories: [Story] {
        return StoriesManager.shared.stories
    }
    
    private var minimumNumberOfStories: Int {
        return stories.count == 1 ? 4 : 3
    }
    private var storiesAreLoading = false
    private var fromBackground = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.shared.trackScreenViewed(.stories)
        
        loadStories()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appRestoredFromBackground), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiptWillDismiss), name: ReceiptNotificationName.receiptWillDismiss, object: nil)
        NotificationCenter.default.addObserver(forName: .UIApplicationDidEnterBackground, object: nil, queue: OperationQueue.main, using: { [weak welf = self] _ in
            welf?.fromBackground = true
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        StoriesManager.shared.currentlySelectedStory = nil
    }
    
    @objc private func receiptWillDismiss() {
         (tabBarController?.tabBar as? PhotobookTabBar)?.isBackgroundHidden = false
    }
    
    @objc private func selectedAssetManagerCountChanged(_ notification: NSNotification) {
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueName = segue.identifier else { return }
        switch segueName {
        case Constants.viewStorySegueName:
            guard let assetPickerController = segue.destination as? AssetPickerCollectionViewController,
                let segue = segue as? ViewStorySegue,
                let sender = sender as? (index: Int, coverImage: UIImage?, sourceView: UIView?, labelsContainerView: UIView?),
                let sourceView = sender.sourceView
                else { return }
            
            let story = stories[sender.index]
            StoriesManager.shared.performAutoSelectionIfNeeded(on: story)
            
            assetPickerController.album = story
            assetPickerController.selectedAssetsManager = StoriesManager.shared.selectedAssetsManager(for: story)
            assetPickerController.delegate = self
            
            segue.coverImage = sender.coverImage
            segue.sourceView = sourceView
            segue.sourceLabelsContainerView = sender.labelsContainerView
        default:
            break
        }
    }
    
    @objc private func appRestoredFromBackground() {
        // There's a possiblibity that we get the notification when this is the first vc shown from application(_:didFinishLaunchingWithOptions:) which we don't care about
        if (fromBackground) {
            loadStories()
        }
    }

    private func loadStories() {
        storiesAreLoading = true
        StoriesManager.shared.loadTopStories(completionHandler: {
            storiesAreLoading = false
            tableView.reloadData()
        })
    }
}

extension StoriesViewController: UITableViewDataSource {
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let numberOfStories = max(stories.count, minimumNumberOfStories)

        if numberOfStories <= Constants.storiesInHeader {
            switch numberOfStories {
            case 3, 4: return Constants.rowsInHeader - 1
            case 5, 6: return Constants.rowsInHeader
            default: return 0
            }
        } else {
            let withoutHeadStories = numberOfStories - Constants.storiesInHeader
            let baseOffset = (withoutHeadStories - 1) / Constants.storiesPerLayoutPattern
            let repeatedLayoutIndex = withoutHeadStories % Constants.storiesPerLayoutPattern
            return baseOffset * Constants.rowsPerLayoutPattern + (repeatedLayoutIndex == 1 ? 1 : 2) + Constants.rowsInHeader
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var isDouble = false
        var storyIndex = 0
        let numberOfStories = max(stories.count, minimumNumberOfStories)
        
        switch indexPath.row {
        case 0, 1: // Single cells for the first and second rows
            storyIndex = indexPath.row
        case 2, 3: // Double cells for the second and third rows
            storyIndex = indexPath.row == 2 ? 2 : 4 // Indexes corresponding to the first story of the third and fourth rows
            isDouble = numberOfStories >= (indexPath.row * 2) // Check if we have enough stories for a double cell
        default:
            let minusHeaderRows = indexPath.row - Constants.rowsInHeader
            let numberOfLayouts = minusHeaderRows / Constants.rowsPerLayoutPattern
            let potentialDouble = minusHeaderRows % Constants.rowsPerLayoutPattern == 1 // First row in the layout pattern is a single & the second a double
            
            storyIndex = numberOfLayouts * Constants.storiesPerLayoutPattern + (potentialDouble ? 1 : 0) + Constants.storiesInHeader
            isDouble = (potentialDouble && storyIndex < numberOfStories - 1)
        }
        
        if isDouble {
            // Double cell
            let story = storyIndex < stories.count ? stories[storyIndex] : nil
            let secondStory = storyIndex + 1 < stories.count ? stories[storyIndex + 1] : nil
            
            let doubleCell = tableView.dequeueReusableCell(withIdentifier: DoubleStoryTableViewCell.reuseIdentifier(), for: indexPath) as! DoubleStoryTableViewCell
            doubleCell.title = story?.title
            doubleCell.dates = story?.subtitle
            doubleCell.secondTitle = secondStory?.title
            doubleCell.secondDates = secondStory?.subtitle
            doubleCell.localIdentifier = story?.identifier
            doubleCell.storyIndex = storyIndex
            doubleCell.delegate = self
            doubleCell.containerView.backgroundColor = story == nil ? UIColor(white: 0, alpha: 0.04) : .groupTableViewBackground
            doubleCell.secondContainerView.backgroundColor = secondStory == nil ? UIColor(white: 0, alpha: 0.04) : .groupTableViewBackground
            doubleCell.overlayView.isHidden = story == nil
            doubleCell.secondOverlayView.isHidden = secondStory == nil
            
            story?.coverAsset(completionHandler:{ (asset, _) in
                doubleCell.coverImageView.setImage(from: asset, size: doubleCell.coverImageView.bounds.size, validCellCheck: {
                    return doubleCell.localIdentifier == story?.identifier
                })
            })
            secondStory?.coverAsset(completionHandler: { (asset, _) in
                doubleCell.secondCoverImageView.setImage(from: asset, size: doubleCell.secondCoverImageView.bounds.size, validCellCheck: {
                    return doubleCell.localIdentifier == story?.identifier
                })
            })
            
            return doubleCell
        }
        
        guard storyIndex < stories.count else {
            return tableView.dequeueReusableCell(withIdentifier: "EmptyStoryTableViewCell", for: indexPath)
        }
        
        let story = stories[storyIndex]

        let singleCell = tableView.dequeueReusableCell(withIdentifier: StoryTableViewCell.reuseIdentifier(), for: indexPath) as! StoryTableViewCell
        singleCell.title = story.title
        singleCell.dates = story.subtitle
        singleCell.localIdentifier = story.identifier
        singleCell.storyIndex = storyIndex
        singleCell.delegate = self

        story.coverAsset(completionHandler: { (asset, _) in
            singleCell.coverImageView.setImage(from: asset, size: singleCell.coverImageView.bounds.size, validCellCheck: {
                return singleCell.localIdentifier == story.identifier
            })
        })

        return singleCell
    }
}

extension StoriesViewController: StoryTableViewCellDelegate {
    // MARK: StoryTableViewCellDelegate
    
    func didTapOnStory(index: Int, coverImage: UIImage?, sourceView: UIView?, labelsContainerView: UIView?) {
        guard !storiesAreLoading, index < stories.count, !stories[index].assets.isEmpty else {
            // For a moment after the app has resumed, while the stories are reloading, if the user taps on a story just ignore it. It's unlikely to happen anyway, and even if it does, it's not worth trying to handle it gracefully.
            return
        }
        
        StoriesManager.shared.currentlySelectedStory = stories[index]
        performSegue(withIdentifier: Constants.viewStorySegueName, sender: (index: index, coverImage: coverImage, sourceView: sourceView, labelsContainerView: labelsContainerView))
    }
}

extension StoriesViewController: AssetPickerCollectionViewControllerDelegate {
    func viewControllerForPresentingOn() -> UIViewController? {
        return tabBarController
    }
    
}
