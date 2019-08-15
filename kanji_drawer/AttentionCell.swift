//
//  AttentionCell.swift
//  kanji_drawer
//
//  Created by Ryo Fujii on 2019/08/10.
//  Copyright © 2019 Ryo Fujii. All rights reserved.
//

import UIKit

class AttentionCell: UITableViewCell {
    
    var charLabel: UILabel!
    var attentionBar: UIView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        charLabel = UILabel(frame: CGRect(x: 20, y: 5, width: 60, height: contentView.frame.height))
        charLabel.font = UIFont(name: "Hiragino Mincho ProN", size: 20)
        charLabel.adjustsFontSizeToFitWidth = true
        charLabel.minimumScaleFactor = 0.8
        contentView.addSubview(charLabel)
        
        attentionBar = UIView(frame: CGRect())
        attentionBar.layer.cornerRadius = 3.0
        attentionBar.layer.masksToBounds = true
        contentView.addSubview(attentionBar)
        
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
    
    func setCell(char: String, attn: Float) {
        charLabel.text = char
        
        let maximumBarLength = contentView.frame.width - 160
        attentionBar.frame = CGRect(x: 120, y: contentView.frame.height / 2, width: maximumBarLength * CGFloat(attn), height: 6)
        attentionBar.backgroundColor = UIColor(hue: 210 / 360, saturation: min(CGFloat(2 * attn), 1), brightness: 1.0, alpha: 1.0)
    }

}
