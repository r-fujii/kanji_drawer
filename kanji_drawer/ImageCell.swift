//
//  ImageCell.swift
//  kanji_drawer
//
//  Created by Ryo Fujii on 2019/07/28.
//  Copyright © 2019 Ryo Fujii. All rights reserved.
//

import UIKit

class ImageCell: UITableViewCell {
    
    var kanjiImageView: UIImageView!
    var descLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        kanjiImageView = UIImageView(frame: CGRect(x: 80, y: 20, width: 80, height: 80))
        contentView.addSubview(kanjiImageView)
        
        descLabel = UILabel(frame: CGRect(x: 480, y: 50, width: 200, height: 20))
        descLabel.textColor = .darkGray
        descLabel.font = UIFont(name: "Hiragino Mincho ProN", size: 24)
        contentView.addSubview(descLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            contentView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.2)
        } else {
            contentView.backgroundColor = .clear
        }
    }
    
    func setCell(kanjiPic: UIImage, phrase: String) {
        kanjiImageView.image = kanjiPic
        descLabel.text = phrase
    }

}
