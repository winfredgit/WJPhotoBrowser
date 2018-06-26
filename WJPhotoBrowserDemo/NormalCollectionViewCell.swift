//
//  NormalCollectionViewCell.swift
//  WJPhotoBrowserDemo
//
//  Created by 王炜俊 on 2018/6/2.
//  Copyright © 2018年 王炜俊. All rights reserved.
//

import UIKit

class NormalCollectionViewCell: UICollectionViewCell {
    var imageView: UIImageView!
    var playImageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        settingUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func settingUI() {
        imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        addSubview(imageView)
        playImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        playImageView.image = UIImage(named: "wj_icon_play")
        addSubview(playImageView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        playImageView.center = CGPoint(x: bounds.width/2.0, y: bounds.height/2.0)
    }
    
}
