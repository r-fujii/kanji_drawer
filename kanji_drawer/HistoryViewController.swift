//
//  HistoryViewController.swift
//  kanji_drawer
//
//  Created by Ryo Fujii on 2019/07/28.
//  Copyright © 2019 Ryo Fujii. All rights reserved.
//

import UIKit

var histTableView = UITableView(frame: CGRect(), style: .grouped)
var histEntries = [(kanjiPic: UIImage, phrase: String)]()

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
        let phrase = histEntries[indexPath.row].phrase
        
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
