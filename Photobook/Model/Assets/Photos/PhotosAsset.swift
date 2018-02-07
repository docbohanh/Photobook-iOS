//
//  PhotosAsset.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

// Photos asset subclass with stubs to be used in testing
class TestPhotosAsset: PhotosAsset {
    override var size: CGSize { return CGSize(width: 10.0, height: 20.0) }
    override init(_ asset: PHAsset, albumIdentifier: String) {
        super.init(asset, albumIdentifier: albumIdentifier)
        self.identifier = "id"
    }
    
    required init(from decoder: Decoder) throws {
        super.init(PHAsset(), albumIdentifier: "")
        self.identifier = "id"
    }
}

class PhotosAsset: Asset {
    
    var assetType: String {
        return NSStringFromClass(PhotosAsset.self)
    }
    
    var photosAsset: PHAsset! {
        didSet {
            identifier = photosAsset.localIdentifier
        }
    }
    
    var identifier: String! {
        didSet {
            if photosAsset == nil || photosAsset.localIdentifier != identifier,
               let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: PHFetchOptions()).firstObject {
                    photosAsset = asset
            }
        }
    }
    
    var date: Date? {
        return photosAsset.creationDate
    }
    
    var albumIdentifier: String

    var size: CGSize { return CGSize(width: photosAsset.pixelWidth, height: photosAsset.pixelHeight) }
    var isLandscape: Bool {
        return self.size.width > self.size.height
    }
    var uploadUrl: String?
    
    init(_ asset: PHAsset, albumIdentifier: String) {
        photosAsset = asset
        identifier = photosAsset.localIdentifier
        self.albumIdentifier = albumIdentifier
    }
    
    func uneditedImage(size: CGSize, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        
        let imageSize = CGSize(width: size.width * UIScreen.main.usableScreenScale(), height: size.height * UIScreen.main.usableScreenScale())
        DispatchQueue.global(qos: .background).async { [weak welf = self] in
            guard let asset = welf?.photosAsset else { return }
            PHImageManager.default().requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: options) { (image, _) in
                completionHandler(image, nil)
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case albumIdentifier, identifier, uploadUrl
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(albumIdentifier, forKey: .albumIdentifier)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(uploadUrl, forKey: .uploadUrl)
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        uploadUrl = try values.decodeIfPresent(String.self, forKey: .uploadUrl)
        albumIdentifier = try values.decode(String.self, forKey: .albumIdentifier)
        
        let assetId = try values.decode(String.self, forKey: .identifier)
        if let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil).firstObject {
            photosAsset = asset
        }
        else {
            throw AssetLoadingException.notFound
        }
        
    }
    
}
