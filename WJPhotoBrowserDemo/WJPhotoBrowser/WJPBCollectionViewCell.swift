//
//  WJPBCollectionViewCell.swift
//  WJPhotoBrowserDemo
//
//  Created by 王炜俊 on 2018/6/2.
//  Copyright © 2018年 王炜俊. All rights reserved.
//

import UIKit
import AVKit

protocol WJPBCellDelegate {
    func cellTouchBrowserScrollView(_ cell: WJPBCollectionViewCell)
}

class WJPBCollectionViewCell: UICollectionViewCell, UIScrollViewDelegate {
    let browserScrollView = UIScrollView()
    let imageView = UIImageView()
    let loadingView = UIActivityIndicatorView()
    let playButton = UIButton(type: UIButtonType.custom)
    var playerLayer: AVPlayerLayer?
    
    private let mainFrame = UIScreen.main.applicationFrame
    var delegate: WJPBCellDelegate?
    var originImageFrame: CGRect?
    var playUrl: String?
    var playerItem: AVPlayerItem?
    var player: AVPlayer?
    var isZoom = false          // 图片是否放大
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        settingUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        playerItem?.removeObserver(self, forKeyPath: "status")
    }
    
    // MARK: - UI
    private func settingUI() {
        backgroundColor = UIColor.clear
        browserScrollView.frame = CGRect(x: 0, y: -20, width: mainFrame.width, height: mainFrame.height+40)
        browserScrollView.contentSize = CGSize(width: browserScrollView.frame.width, height: browserScrollView.frame.height)
        browserScrollView.backgroundColor = UIColor.clear
        browserScrollView.showsHorizontalScrollIndicator = false
        browserScrollView.showsVerticalScrollIndicator = false
        // 设置缩放比例
        browserScrollView.minimumZoomScale = 1
        browserScrollView.maximumZoomScale = 3
        browserScrollView.delegate = self
        imageView.frame = CGRect(x: 0, y: 0, width: browserScrollView.frame.size.width, height: 300)
        imageView.center = CGPoint(x: browserScrollView.frame.width/2.0, y: browserScrollView.frame.height/2.0)
        browserScrollView.addSubview(imageView)
        // 单击隐藏
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(touchBrowserScrollView))
        browserScrollView.addGestureRecognizer(tapGesture)
        // 双击放大
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTouchImage))
        doubleTapGesture.numberOfTapsRequired = 2
        browserScrollView.addGestureRecognizer(doubleTapGesture)
        tapGesture.require(toFail: doubleTapGesture)
        addSubview(browserScrollView)
        loadingView.activityIndicatorViewStyle = .white
        loadingView.center = CGPoint(x: mainFrame.width/2.0, y: mainFrame.height/2.0)
        addSubview(loadingView)
        playButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        playButton.center = CGPoint(x: mainFrame.width/2.0, y: mainFrame.height/2.0)
        playButton.setImage(UIImage(named: "wj_icon_play"), for: .normal)
        playButton.addTarget(self, action: #selector(play), for: .touchUpInside)
        addSubview(playButton)
    }
    
    private func updateImageHeight(_ height: CGFloat) {
        imageView.frame = CGRect(x: 0, y: 0, width: browserScrollView.frame.width, height: height)
        // 图片小于屏幕则居中
        if height < mainFrame.height {
            imageView.center = CGPoint(x: browserScrollView.frame.width/2.0,
                                       y: browserScrollView.frame.height/2.0)
            browserScrollView.contentSize.height = browserScrollView.frame.height
        } else {
            browserScrollView.contentSize.height = height
        }
    }
    
    private func resetScrollView() {
        browserScrollView.contentSize.width = browserScrollView.frame.width
        browserScrollView.contentOffset = CGPoint(x: 0, y: 0)
        browserScrollView.zoomScale = 1
    }
    
    // MARK: -
    func loadImage(_ urlStr: String, thumbImage: UIImage?) {
        playButton.isHidden = true
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        player = nil
        imageView.isHidden = false
        loadingView.startAnimating()
        loadingView.isHidden = false
        if let image = thumbImage {
            // 按比例计算高度
            let height = mainFrame.width * (image.size.height / image.size.width)
            updateImageHeight(height)
        }
        let url = URL(string: urlStr)
        imageView.sd_setImage(with: url,
                              placeholderImage: thumbImage) {
                                (image, error, type, url) in
                                self.loadingView.stopAnimating()
                                self.loadingView.isHidden = true
                                if image != nil {
                                    // cell复用时，重置scrollView相关设置(可能复用的cell scrollView zoomScale>1，因此需要重置)
                                    // ⚠️顺序必须在imageView设置正确的frame之前，因为resetScrollView()重置zoomScale=1时，viewForZooming代理会将imageView frame设置成错误的，需在这之后再设置正确的
                                    self.resetScrollView()
                                    // 按比例计算高度
                                    let height = self.mainFrame.width * (image!.size.height / image!.size.width)
                                    self.updateImageHeight(height)
                                    self.originImageFrame = self.imageView.frame
                                }
        }
    }
    
    func playVideo(_ urlStr: String, thumbImage: UIImage?) {
        // 加载的视频时，重置复用cell originImageFrame
        originImageFrame = nil
        if let image = thumbImage {
            self.resetScrollView()
            imageView.image = image
            // 按比例计算高度
            let height = mainFrame.width * (image.size.height / image.size.width)
            updateImageHeight(height)
        }
        playUrl = urlStr
        playButton.isHidden = false
    }
    
    @objc private func play() {
        // 视频暂停播放中，继续播放
        if player != nil && player!.rate == 0.0 {
            player!.play()
            playButton.isHidden = true
        } else {
            // 开始第一次播放
            if playUrl != nil {
                if let url = URL(string: playUrl!) {
                    playButton.isHidden = true
                    loadingView.startAnimating()
                    loadingView.isHidden = false
                    playerItem = AVPlayerItem(url: url)
                    player = AVPlayer(playerItem: playerItem)
                    playerLayer = AVPlayerLayer(player: player!)
                    playerLayer!.frame = CGRect(x: 0,
                                                y: 0,
                                                width: browserScrollView.frame.width,
                                                height: browserScrollView.frame.height)
                    browserScrollView.layer.addSublayer(playerLayer!)
                    player!.play()
                    // 观察视频播放状态
                    playerItem!.addObserver(self,
                                            forKeyPath: "status",
                                            options: .new,
                                            context: nil)
                    // 观察视频播放结束
                    NotificationCenter.default.addObserver(self,
                                                           selector: #selector(playOver),
                                                           name: Notification.Name.AVPlayerItemDidPlayToEndTime,
                                                           object: nil)
                }
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if (object != nil && object! is AVPlayerItem) && (keyPath != nil && keyPath! == "status") {
            if change != nil {
                let status = change![NSKeyValueChangeKey.newKey] as! Int
                // 视频即将播放时，隐藏loading、帧图
                if status == AVPlayerStatus.readyToPlay.rawValue {
                    loadingView.stopAnimating()
                    loadingView.isHidden = true
                    imageView.isHidden = true
                }
            }
        }
    }
    
    @objc private func playOver() {
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil
        playerItem?.removeObserver(self, forKeyPath: "status")
        playerItem = nil
        playButton.isHidden = false
        imageView.isHidden = false
        NotificationCenter.default.removeObserver(self,
                                                  name: Notification.Name.AVPlayerItemDidPlayToEndTime,
                                                  object: nil)
    }
    
    @objc private func touchBrowserScrollView() {
        // 视频正在播放中，暂停播放
        if player?.rate == 1.0 {
            player?.pause()
            playButton.isHidden = false
        } else {
            if delegate != nil {
                delegate!.cellTouchBrowserScrollView(self)
            }
        }
    }
    
    @objc private func doubleTouchImage(gesture: UITapGestureRecognizer) {
        if player?.rate == 1.0 || originImageFrame == nil { return }   // 正在播放视频 || 没有加载大图
        let zoomScale = browserScrollView.zoomScale
        // 放大
        if zoomScale <= 1 {
            let width = self.mainFrame.size.width / 3;
            let height = self.mainFrame.size.height / 3;
            let point = gesture.location(in: self)
            let x = point.x - (width / 2.0);
            let y = point.y - (height / 2.0);
            browserScrollView.zoom(to: CGRect(x: x, y: y, width: width, height: height),
                                   animated: true)
        } else if zoomScale >= 3 || (zoomScale > 1 && zoomScale < 3) {  // 缩小
            browserScrollView.setZoomScale(1, animated: true)
        }
    }
    
    // MARK: - UIScrollViewDelegate
    // 缩放时被调用多次
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        // 返回需要缩放的view，视频则返回nil
        return playUrl == nil ? imageView : nil
    }
    
    // 缩放结束时调用
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let boundsSize = mainFrame.size
        var frameToCenter = imageView.frame
        // Horizontally
        if (frameToCenter.size.width < boundsSize.width) {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2.0
        } else {
            frameToCenter.origin.x = 0
        }
        // Vertically
        if (frameToCenter.size.height < boundsSize.height) {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2.0
        } else {
            frameToCenter.origin.y = 0
        }
        // Center
        if imageView.frame != frameToCenter {
            // 缩放过程中，保持图片居中
            imageView.frame = frameToCenter
            self.isZoom = imageView.frame.size.width > self.mainFrame.size.width
        }
    }
    
}
