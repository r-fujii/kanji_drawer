//
//  DetailViewController.swift
//  kanji_drawer
//
//  Created by Ryo Fujii on 2019/08/08.
//  Copyright © 2019 Ryo Fujii. All rights reserved.
//

import UIKit

extension UIFont {
    func withTraits(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return UIFont(descriptor: descriptor!, size: 0) //size 0 means keep the size as it is
    }
    
    func bold() -> UIFont {
        return withTraits(traits: .traitBold)
    }
}

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var kanjiImageView: UIImageView!
    @IBOutlet weak var descLabel: UILabel!
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var henView: UIView!
    @IBOutlet weak var tukuriView: UIView!
    
    // using 'repeating' and 'count' will generate referential information of a class instance ...
    var neighborStrsLabelsHen = [UILabel(), UILabel(), UILabel()]
    var neighborStrsLabelsTukuri = [UILabel(), UILabel(), UILabel()]
    
    var charAttnValues = [(char: String, attns: [Float])]()
    var henTableView = UITableView(frame: CGRect(), style: .grouped)
    var tukuriTableView = UITableView(frame: CGRect(), style: .grouped)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "washi")!)
        
        descLabel.textColor = .darkGray
        
        backButton.setTitleColor(.white, for: .normal)
        backButton.backgroundColor = .osColorBlue
        backButton.layer.cornerRadius = 5.0
        
        let henViewOrigin = self.view.convert(CGPoint(x: 0, y: 0), from: henView)
        let tukuriViewOrigin = self.view.convert(CGPoint(x: 0, y: 0), from: tukuriView)
        let subViewWidth = min(self.henView.frame.width, self.tukuriView.frame.width) - 40
        
        // for showing similar examples
        let labelFont = UIFont(name: "Hiragino Mincho ProN", size: 16)
        for i in 0 ..< 3 {
            // numbers
            neighborStrsLabelsHen[i].frame = CGRect(x: henViewOrigin.x + 20, y: henViewOrigin.y + CGFloat((i + 1) * 40), width: subViewWidth, height: 20)
            neighborStrsLabelsHen[i].font = labelFont
            neighborStrsLabelsHen[i].adjustsFontSizeToFitWidth = true
            neighborStrsLabelsHen[i].minimumScaleFactor = 0.8
            self.view.addSubview(neighborStrsLabelsHen[i])
            
            neighborStrsLabelsTukuri[i].frame = CGRect(x: tukuriViewOrigin.x + 20, y: tukuriViewOrigin.y + CGFloat((i + 1) * 40), width: subViewWidth, height: 20)
            neighborStrsLabelsTukuri[i].font = labelFont
            neighborStrsLabelsTukuri[i].adjustsFontSizeToFitWidth = true
            neighborStrsLabelsTukuri[i].minimumScaleFactor = 0.8
            self.view.addSubview(neighborStrsLabelsTukuri[i])
        }
        
        neighborStrsLabelsHen[0].font = labelFont!.bold()
        neighborStrsLabelsTukuri[0].font = labelFont!.bold()
        
        // attentions
        let henTableViewOrigin = self.view.convert(CGPoint(x: 20, y: 200), from: henView)
        let tukuriTableViewOrigin = self.view.convert(CGPoint(x: 20, y: 200), from: tukuriView)
        
        henTableView.delegate = self
        henTableView.dataSource = self
        tukuriTableView.delegate = self
        tukuriTableView.dataSource = self
        
        henTableView.frame = CGRect(origin: henTableViewOrigin, size: CGSize(width: subViewWidth, height: henView.frame.height - 220))
        tukuriTableView.frame = CGRect(origin: tukuriTableViewOrigin, size: CGSize(width: subViewWidth, height: tukuriView.frame.height - 220))
        henTableView.backgroundColor = .clear
        tukuriTableView.backgroundColor = .clear
        
        self.view.addSubview(henTableView)
        self.view.addSubview(tukuriTableView)
        
    }
    
    func checkID(_ tableView: UITableView) -> Int {
        if (tableView.isEqual(henTableView)) {
            return 0
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // assume numbers of hen / tukuri cells to be the same
        return charAttnValues.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellID = checkID(tableView)
        
        var cellIdentifier : String
        if cellID == 0 {
            cellIdentifier = "cellHen"
        } else {
            cellIdentifier = "cellTukuri"
        }
        
        let cell = AttentionCell(style: .default, reuseIdentifier: cellIdentifier)
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        
        let cellData = charAttnValues[indexPath.row]
        cell.setCell(char: cellData.char, attn: cellData.attns[cellID])
        
        return cell
    }
    
    
    @IBAction func backPrevScreen(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
