//
//  ViewController.swift
//  WJPhotoBrowserDemo
//
//  Created by 王炜俊 on 2018/6/2.
//  Copyright © 2018年 王炜俊. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, WJPhotoBrowserDelegate {
    let collectionView: UICollectionView!
    private let cvLayout = UICollectionViewFlowLayout()
    var cleanCacheButton: UIButton!
    
    var thumbUrls = [String]()
    var photos = [WJPhoto]()
    var photoBrowser: WJPhotoBrowser?
    
    required init?(coder aDecoder: NSCoder) {
        collectionView = UICollectionView(frame: CGRect(x: 0,
                                                        y: 0,
                                                        width: UIScreen.main.applicationFrame.width,
                                                        height: UIScreen.main.applicationFrame.height),
                                          collectionViewLayout: cvLayout)
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        settingUI()
        setup()
    }
    
    // MARK: - UI
    private func settingUI() {
        let width = (UIScreen.main.applicationFrame.width - (3 * 10)) / 4
        cvLayout.itemSize = CGSize(width: width, height: width)
        cvLayout.minimumInteritemSpacing = 10
        cvLayout.minimumLineSpacing = 10
        collectionView.register(NormalCollectionViewCell.self,
                                forCellWithReuseIdentifier: NSStringFromClass(NormalCollectionViewCell.self))
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.white
        view.addSubview(collectionView)
        cleanCacheButton = UIButton(type: .system)
        cleanCacheButton.frame = CGRect(x: 12,
                                        y: UIScreen.main.applicationFrame.height-100,
                                        width: 80,
                                        height: 30)
        cleanCacheButton.setTitle("清除缓存", for: .normal)
        cleanCacheButton.addTarget(self,
                                   action: #selector(cleanCache),
                                   for: .touchUpInside)
        view.addSubview(cleanCacheButton)
    }
    
    // MARK: -
    private func setup() {
        thumbUrls.append("https://image.cnhnb.com/image/png/head/2018/06/02/ff595e2d38f04437957e7b31139bf383.png?imageView2/0/w/100/h/100/q/75/ignore-error/1")
        thumbUrls.append("https://image.cnhnb.com/image/png/head/2018/06/02/9a9209dd34174b3ab677175bccfd2ed3.png?imageView2/0/w/100/h/100/q/75/ignore-error/1")
        thumbUrls.append("https://image.cnhnb.com/image/png/head/2018/06/02/e51caba718e54a32ac65f611be1f56e4.png?imageView2/0/w/100/h/100/q/75/ignore-error/1")
        thumbUrls.append("https://image.cnhnb.com/image/png/head/2018/06/02/79a771cde48b411c946ba6707e74ff4b.png?imageView2/0/w/100/h/100/q/75/ignore-error/1")
        thumbUrls.append("https://image.cnhnb.com/image/png/head/2018/06/02/1c36aec8ebb94315a9f6a5b43f3c3291.png?imageView2/0/w/100/h/100/q/75/ignore-error/1")
        thumbUrls.append("https://image.cnhnb.com/image/png/head/2018/06/02/7e4ecc93546040c8a75f515783b9c90d.png?imageView2/0/w/100/h/100/q/75/ignore-error/1")
        thumbUrls.append("https://image.cnhnb.com/image/png/head/2018/06/02/043def6b2c684404877a06806b056dea.png?imageView2/0/w/100/h/100/q/75/ignore-error/1")
        thumbUrls.append("https://image.cnhnb.com/image/png/head/2018/06/02/767b3afbdf9e4e649a8f858645ab0f64.png?imageView2/0/w/100/h/100/q/75/ignore-error/1")
        thumbUrls.append("https://image.cnhnb.com/image/png/head/2018/06/26/b950caa0e91041428806fccbd85c4759.png?imageView2/0/w/170/h/170/q/75/ignore-error/1")
        for (index, url) in thumbUrls.enumerated() {
            let photo = WJPhoto()
            if index == thumbUrls.count-1 {
                photo.videoUrl = "https://pl-ali.youku.com/playlist/m3u8?vid=864622807&type=flv&ups_client_netip=71f7e28a&utid=PM%2BwEwRRkVoCAXH34oo%2BDm%2Fu&ccode=050F&psid=e7accf28bd87f6f9bb28eb87dd8e57b4&duration=35&expire=18000&drm_type=1&drm_device=7&ups_ts=1529982600&onOff=0&encr=0&ups_key=30e62da289f1a78be978c78694435f02"
            } else {
                photo.originImageUrl = url.replacingOccurrences(of: "?imageView2/0/w/100/h/100/q/75/ignore-error/1", with: "")
            }
            photos.append(photo)
        }
    }
    
    @objc func cleanCache() {
        SDWebImageManager.shared().imageCache?.clearMemory()
        SDWebImageManager.shared().imageCache?.clearDisk(onCompletion: nil)
    }
    
    // MARK: - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return thumbUrls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(NormalCollectionViewCell.self),
                                                      for: indexPath) as! NormalCollectionViewCell
        if indexPath.row < thumbUrls.count {
            let url = URL(string: thumbUrls[indexPath.row])
            cell.imageView.sd_setImage(with: url)
            cell.playImageView.isHidden = !(indexPath.row == thumbUrls.count-1)
        }
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        photoBrowser = WJPhotoBrowser(photos: photos, index: indexPath.row, delegate: self)
        photoBrowser!.show()
    }
    
    // MARK: - WJPhotoBrowserDelegate
    func photoBrowser(_ photoBrowser: WJPhotoBrowser, thumbImageAt index: Int) -> UIImage {
        let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as! NormalCollectionViewCell
        return cell.imageView.image!
    }
    
    func photoBrowser(_ photoBrowser: WJPhotoBrowser, imageSuperViewAt index: Int) -> UIView {
        let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as! NormalCollectionViewCell
        return cell
    }


}

