//
//  PhotosAlbumTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 03/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
import Photos
@testable import Photobook

class PhotosAlbumTests: XCTestCase {
    
    let assetCollection = PHAssetCollectionMock()
    var photosAlbum: PhotosAlbum!
    
    var assets: [PHAssetMock]!
    
    override func setUp() {
        super.setUp()

        assets = [PHAssetMock]()
        for i in 0 ..< 10 {
            let asset = PHAssetMock()
            asset.localIdentifierStub = "local\(i)"
            asset.listIdentifier = assetCollection.localIdentifier
            assets.append(asset)
        }

        photosAlbum = PhotosAlbum(assetCollection)
        
        let assetManager = AssetManagerMock()
        assetManager.phAssetsStub = assets
        
        photosAlbum.assetManager = assetManager
    }
    
    func testInitialisation() {
        XCTAssertEqual(assetCollection.localIdentifier, photosAlbum.assetCollection.localIdentifier)
    }
    
    func testLoadAssetsFromPhotoLibrary() {
        photosAlbum.loadAssetsFromPhotoLibrary()
        
        // Check that identifiers match (same asset)
        for i in 0 ..< assets.count {
            XCTAssertEqualOptional(assets[i].localIdentifier, (photosAlbum.assets[i] as? PhotosAsset)?.photosAsset.localIdentifier)
        }
    }
    
    func testLoadAssets() {
        photosAlbum.loadAssets { (error) in
            // Check that identifiers match (same asset)
            
            for i in 0 ..< self.assets.count {
                self.XCTAssertEqualOptional(self.assets[i].localIdentifier, (self.photosAlbum.assets[i] as? PhotosAsset)?.photosAsset.localIdentifier)
            }
        }
    }
    
    func testChangedAssets() {
        let newAsset = PHAssetMock()
        newAsset.localIdentifierStub = "local11"
        newAsset.listIdentifier = assetCollection.localIdentifier
        
        photosAlbum.loadAssetsFromPhotoLibrary()
        
        let phChange = ChangeManagerMock()
        phChange.phInsertedAssetsStub = [ newAsset ]
        phChange.phRemovedAssetsStub = [ assets[0] ]
        
        let (inserted, removed) = photosAlbum.changedAssets(for: phChange)
        XCTAssertEqualOptional(inserted?.first?.identifier, newAsset.localIdentifier)
        XCTAssertEqualOptional(removed?.first?.identifier, assets[0].localIdentifier)
    }
}
