//
//  WJPhotoBrowser.swift
//  WJPhotoBrowserDemo
//
//  Created by 王炜俊 on 2018/6/2.
//  Copyright © 2018年 王炜俊. All rights reserved.
//

import UIKit

@objc protocol WJPhotoBrowserDelegate {
    func photoBrowser(_ photoBrowser: WJPhotoBrowser, thumbImageAt index: Int) -> UIImage
    func photoBrowser(_ photoBrowser: WJPhotoBrowser, imageSuperViewAt index: Int) -> UIView
}

class WJPhotoBrowser: UIWindow, UICollectionViewDataSource, UICollectionViewDelegate, WJPBCellDelegate {
    private let collectionView: UICollectionView!
    private let cvLayout = UICollectionViewFlowLayout()
    private let pageControl = UIPageControl()
    
    private let mainFrame = UIScreen.main.applicationFrame
    private var photos = [WJPhoto]()
    private var currentPage = 0
    private let pageMargin = 20.0
    weak var delegate: WJPhotoBrowserDelegate?
    // 拖动图片使用属性
    var startLocation = CGPoint(x: 0, y: 0)
    var startCenter = CGPoint(x: 0, y: 0)
    var zoomScale: CGFloat = 0.0
    var isPanGestureChanged = false
    
    // MARK: - LifeCycle
    init(photos: [WJPhoto], index: Int, delegate: WJPhotoBrowserDelegate?) {
        self.photos = photos
        currentPage = index
        self.delegate = delegate
        collectionView = UICollectionView(frame: CGRect(x: 0,
                                                        y: 0,
                                                        width: mainFrame.width+CGFloat(pageMargin),
                                                        height: mainFrame.height+UIApplication.shared.statusBarFrame.height),
                                          collectionViewLayout: cvLayout)
        super.init(frame: UIScreen.main.bounds)
        settingUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        collectionView = UICollectionView()
        super.init(coder: aDecoder)
    }
    
    // MARK: - UI
    private func settingUI() {
        backgroundColor = UIColor.black
        cvLayout.itemSize = collectionView.frame.size
        cvLayout.minimumInteritemSpacing = 0
        cvLayout.minimumLineSpacing = 0
        cvLayout.scrollDirection = .horizontal  // 横向布局
        collectionView.backgroundColor = UIColor.clear
        collectionView.isPagingEnabled = true
        collectionView.register(WJPBCollectionViewCell.self,
                                forCellWithReuseIdentifier: NSStringFromClass(WJPBCollectionViewCell.self))
        collectionView.dataSource = self
        collectionView.delegate = self
        addSubview(collectionView)
        pageControl.frame = CGRect(x: 0, y: mainFrame.height-60, width: mainFrame.width, height: 10)
        pageControl.numberOfPages = self.photos.count
        pageControl.currentPage = currentPage
        if self.photos.count < 1 || self.photos.count > 19 {
            pageControl.isHidden = true
        } else {
            pageControl.isHidden = false
        }
        addSubview(pageControl)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(drag(_:)))
        self.addGestureRecognizer(panGesture)
    }
    
    // MARK: -
    func show() {
        windowLevel = UIWindowLevelAlert
        isHidden = false
        makeKeyAndVisible()
        self.collectionView.scrollToItem(at: IndexPath(row: currentPage, section: 0),
                                         at: .centeredHorizontally,
                                         animated: false)
    }
    
    private func hidden() {
        if delegate != nil && collectionView.visibleCells.count > 0 {
            // 获取当前可见的cell
            let pbCell = self.collectionView.visibleCells.first as! WJPBCollectionViewCell
            pbCell.playButton.isHidden = true
            // 图片被放大隐藏时，重设图片相关frame
            if pbCell.isZoom {
                pbCell.browserScrollView.contentSize = CGSize(width: pbCell.browserScrollView.frame.width, height: pbCell.browserScrollView.frame.height)
                if pbCell.originImageFrame != nil { pbCell.imageView.frame = pbCell.originImageFrame! }
                pbCell.imageView.center = CGPoint(x: pbCell.browserScrollView.frame.width/2.0,
                                                  y: pbCell.browserScrollView.frame.height/2.0)
                pbCell.browserScrollView.contentOffset = CGPoint(x: 0, y: 0)
            }
            // 获取来源view
            let indexPath = self.collectionView.indexPath(for: pbCell)
            let imageSuperView = delegate!.photoBrowser(self, imageSuperViewAt: indexPath!.row)
            if imageSuperView.frame.width > 0 && imageSuperView.frame.height > 0 {
                // 转换来源view相对在window的frame
                let finalFrame = imageSuperView.convert(imageSuperView.bounds, to: UIApplication.shared.keyWindow)
                UIView.animate(withDuration: 0.25,
                               delay: 0,
                               options: [.beginFromCurrentState, .curveEaseInOut],
                               animations: {
                                pbCell.imageView.frame = finalFrame
                                pbCell.playerLayer?.frame = finalFrame
                }) {
                    (isFinished) in
                    self.dismiss()
                }
            } else {
                self.dismiss()
            }
        } else {
            self.dismiss()
        }
    }
    
    private func dismiss() {
        UIView.animate(withDuration: 0.1, animations: {
            self.alpha = 0.1
        }) { (isFinished) in
            self.isHidden = true
            self.resignKey()
        }
    }
    
    @objc private func drag(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        let point = gesture.translation(in: self)
        let cell = collectionView.visibleCells.first as! WJPBCollectionViewCell
        switch gesture.state {
        case .began:
            startLocation = location
            startCenter = cell.imageView.center
            zoomScale = cell.browserScrollView.zoomScale
            isPanGestureChanged = false
        case .changed:
            // 控制首次触发手势时，往上拖动图片。不影响拖动中时，往上的拖动
            if (location.y - startLocation.y < 0 && isPanGestureChanged == false) { return }
            let percent = 1 - (fabs(point.y) / mainFrame.height)
            var scalePercent = max(percent, 0.3)
            if (location.y - startLocation.y < 0) {
                scalePercent = zoomScale * 1;
            } else {
                scalePercent = zoomScale * scalePercent;
            }
            cell.imageView.transform = CGAffineTransform(scaleX: scalePercent, y: scalePercent)
            cell.imageView.center = CGPoint(x: startCenter.x+point.x, y: startCenter.y+point.y)
            cell.playButton.isHidden = true
            // 拖动视频时暂停播放
            cell.player?.pause()
            cell.playerLayer?.frame = cell.imageView.frame
            backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: scalePercent/zoomScale)
            isPanGestureChanged = true
        case .ended:
            fallthrough
        case .cancelled:
            // 临界点
            if point.y > 100 {
                hidden()
            } else {
                let scale = CGAffineTransform(scaleX: zoomScale, y: zoomScale)
                UIView.animate(withDuration: 0.25, animations: {
                    cell.imageView.transform = scale
                    cell.imageView.center = self.startCenter
                    // 如果拖动的是视频帧图，还原后重新显示播放按钮
                    if cell.playUrl != nil && cell.player == nil { cell.playButton.isHidden = false }
                    // 如果拖动了已经正在播放的视频，还原后继续播放
                    cell.player?.play()
                    cell.playerLayer?.frame = CGRect(x: 0,
                                                     y: 0,
                                                     width: cell.browserScrollView.frame.width,
                                                     height: cell.browserScrollView.frame.height)
                    self.backgroundColor = UIColor.black
                }) {
                    (isFinished) in
                    
                }
            }
        default:
            break
        }
    }
    
    // MARK: - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(WJPBCollectionViewCell.self),
                                                      for: indexPath) as! WJPBCollectionViewCell
        cell.delegate = self
        if indexPath.row < photos.count {
            let photo = photos[indexPath.row]
            var thumbImage: UIImage?
            if delegate != nil {
                thumbImage = delegate!.photoBrowser(self, thumbImageAt: indexPath.row)
            }
            if let originImageUrl = photo.originImageUrl {
                cell.loadImage(originImageUrl, thumbImage: thumbImage)
            } else if let videoUrl = photo.videoUrl {
                cell.playVideo(videoUrl, thumbImage: thumbImage)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // cell还未展示，才显示动画
        if delegate != nil && collectionView.visibleCells.count == 0 {
            let imageSuperView = delegate!.photoBrowser(self, imageSuperViewAt: indexPath.row)
            if imageSuperView.frame.width > 0 && imageSuperView.frame.height > 0 {
                let pbCell = cell as! WJPBCollectionViewCell
                let originFrame = imageSuperView.convert(imageSuperView.bounds, to: UIApplication.shared.keyWindow)
                let finalFrame = pbCell.imageView.frame
                pbCell.imageView.frame = originFrame
                UIView.animate(withDuration: 0.25,
                               delay: 0,
                               options: [.beginFromCurrentState, .curveEaseInOut],
                               animations: {
                                pbCell.imageView.frame = finalFrame
                }) {
                    (isFinished) in
                    
                }
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentPage = (scrollView.contentOffset.x - CGFloat(pageMargin)) / mainFrame.width
        self.currentPage = Int(currentPage)
        pageControl.currentPage = self.currentPage
    }
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        hidden()
    }
    
    // MARK: - WJPBCellDelegate
    func cellTouchBrowserScrollView(_ cell: WJPBCollectionViewCell) {
        hidden()
    }
    
}
