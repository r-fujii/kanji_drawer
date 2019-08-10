//
//  HistoryViewController.swift
//  kanji_drawer
//
//  Created by Ryo Fujii on 2019/07/28.
//  Copyright © 2019 Ryo Fujii. All rights reserved.
//

import UIKit

var histTableView = UITableView(frame: CGRect(), style: .grouped)
var histEntries = [(kanjiPic: UIImage, phrase: String, attValues: [[Float]], neighborStrs: [[String]])]()

class HistoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // initial settings
        histTableView.frame = self.view.frame
        histTableView.delegate = self
        histTableView.dataSource = self
        histTableView.backgroundColor = UIColor(patternImage: UIImage(named: "washi")!)
        histTableView.rowHeight = 120
        self.view.addSubview(histTableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return histEntries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ImageCell(style: .default, reuseIdentifier: "cell")
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        
        let cellData = histEntries[indexPath.row]
        cell.setCell(kanjiPic: cellData.kanjiPic, phrase: cellData.phrase)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let entry = histEntries[indexPath.row]
        let phrase = entry.phrase
        let attnValues = entry.attValues
        let neighborStrs = entry.neighborStrs
        
        let alert = UIAlertController(title: nil,
                                  message: nil,
                                  preferredStyle: .alert)
        
        alert.title = "「\(phrase)」に近い意味の漢字"
        
        alert.addAction(
            UIAlertAction(
                title: "キーワードに設定", style: .default, handler: {(action) -> Void in
                    // TODO: 画面遷移
                    let vc = self.tabBarController?.viewControllers![0] as! ViewController
                    vc.phraseField.text = phrase
                    self.tabBarController?.selectedIndex = 0
            })
        )
        
        alert.addAction(
            UIAlertAction(
                // 画面遷移 (TODO)
                title: "詳細", style: .default, handler: {(action) -> Void in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // execute 0.5 seconds after button is tapped
                        let vc = self.storyboard!.instantiateViewController(withIdentifier: "detailView") as! DetailViewController
                        let _ = vc.view // small hack to access outlet properties on target VC, get nil without this line (from https://qiita.com/fromage-blanc/items/3ea2dfe97d4c2d6f0646)
                        vc.kanjiImageView.image = entry.kanjiPic
                        vc.descLabel.text = phrase
                        
                        // similar phrases in training data
                        for i in 0 ..< min(neighborStrs[0].count, neighborStrs[1].count, 3) {
                            // counts assumed to be same, but for safety
                            vc.neighborStrsLabelsHen[i].text = neighborStrs[0][i]
                            vc.neighborStrsLabelsTukuri[i].text = neighborStrs[1][i]
                        }
                        
                        // attention
                        vc.charAttnValues = []
                        for i in 0 ..< phrase.count {
                            vc.charAttnValues.append((char: String(Array(phrase)[i]), attns: [attnValues[0][i], attnValues[1][i]]))
                        }
                        vc.charAttnValues.append((char: "<EOS>", attns: [attnValues[0][phrase.count], attnValues[1][phrase.count]]))
                        
                        vc.modalTransitionStyle = .partialCurl
                        self.present(vc, animated: true, completion: nil)
                    }
            })
        )
        
        alert.addAction(
            UIAlertAction(title: "中止", style: .cancel, handler: nil)
        )
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            histEntries.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
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
