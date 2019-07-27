//
//  ViewController.swift
//  kanji_drawer
//
//  Created by Ryo Fujii on 2019/07/07.
//  Copyright © 2019 Ryo Fujii. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Accounts

extension UIColor {
    class var osColorBlue: UIColor {
        return UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 0.8)
    }
    class var osColorRed: UIColor {
        return UIColor(red: 1.0, green: 59.0/255.0, blue: 48.0/255.0, alpha: 0.8)
    }
    
    class var osColorGreen: UIColor {
        return UIColor(red: 76.0/255.0, green: 217.0/255.0, blue: 100.0/255.0, alpha: 1.0)
    }
}

extension UIImage {
    
    // make an image upside-down
    func flipVertical() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let imageRef = self.cgImage
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y:  0)
        context?.scaleBy(x: 1.0, y: 1.0)
        context?.draw(imageRef!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let flipHorizontalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return flipHorizontalImage!
    }
    
    func resizeImage(width: CGFloat, height: CGFloat) -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let resizedImage: UIImage! = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
}

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var phraseField: UITextField!
    @IBOutlet weak var descLabel: UILabel!
    
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    
    @IBOutlet weak var topKanjiLabel: UILabel!
    @IBOutlet var topKanjiButtons: [UIButton]!
    
    @IBOutlet weak var shareButton: UIButton!
    
    var kanjiPath = UIBezierPath()
    var addedView = [UIImageView]()
    
    var topKanjis = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // initial settings
        
        // background
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "washi")!)
        
        // input field
        phraseField.delegate = self
        phraseField.text = "タピオカ"
        phraseField.placeholder = "フレーズを入力"
        phraseField.clearButtonMode = .whileEditing
        phraseField.layer.cornerRadius = 20.0
        
        // buttons
        goButton.setTitleColor(.white, for: .normal)
        goButton.backgroundColor = .osColorBlue
        goButton.layer.cornerRadius = 5.0
        clearButton.setTitleColor(.white, for: .normal)
        clearButton.backgroundColor = .osColorRed
        clearButton.layer.cornerRadius = 5.0
        
        topKanjiLabel.isHidden = true
        for kanjiButton in topKanjiButtons {
            kanjiButton.isHidden = true
            kanjiButton.setTitleColor(UIColor.clear, for: .normal)
            kanjiButton.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5)
            kanjiButton.layer.cornerRadius = 10.0
            kanjiButton.clipsToBounds = true
        }
        
        descLabel.isHidden = true
        
        shareButton.isHidden = true
        shareButton.setTitleColor(.white, for: .normal)
        shareButton.backgroundColor = .osColorBlue
        shareButton.layer.cornerRadius = 25.0
        shareButton.layer.masksToBounds = true
    }
    
    @IBAction func sendPhrase(_ sender: Any) {
        guard let phrase = phraseField.text, phraseField.text!.count > 0 else {
            return
        }
        
        self.clearCanvas(sender)
        // ここでbezier pathの受け取りに成功
        self.getBezierPathFor(phrase: phrase, {kanjiData in
            let kanjiImages = self.drawKanji(CGRect(x: 0, y: 0, width: 300, height: 300), kanjiData: kanjiData)
            
            self.topKanjis = kanjiImages
            
            let kanjiCanvas = UIImageView(image: self.topKanjis[0])
            
            let attrText = NSMutableAttributedString(string: "「\(phrase)」に近い意味の漢字")
            attrText.addAttribute(.foregroundColor, value: UIColor.osColorGreen, range: NSMakeRange(1, phrase.count))
            self.descLabel.attributedText = attrText
            self.descLabel.isHidden = false
            
            kanjiCanvas.frame.origin = CGPoint(x: 100, y: self.descLabel.frame.maxY + 75)
            kanjiCanvas.alpha = 0
            
            self.view.addSubview(kanjiCanvas)
            self.addedView.append(kanjiCanvas)
            
            self.topKanjiLabel.isHidden = false
            // self.shareButton.isHidden = false
            
            for i in 0..<6 {
                let image = self.topKanjis[i].resizeImage(width: 60, height: 60).withRenderingMode(.alwaysTemplate)
                self.topKanjiButtons[i].setImage(image, for: .normal)
                self.topKanjiButtons[i].imageEdgeInsets = UIEdgeInsets(top: 5, left: 25, bottom: 5, right: 25)
                self.topKanjiButtons[i].tintColor = .darkGray
                self.topKanjiButtons[i].isHidden = false
            }
        
        UIView.animate(withDuration: 2.0, animations: {
                kanjiCanvas.alpha = 1.0
            })
        })
        
    }
    
    @IBAction func clearCanvas(_ sender: Any) {
        
        descLabel.isHidden = true
        topKanjiLabel.isHidden = true
        shareButton.isHidden = true
        
        for kanjiButton in topKanjiButtons {
            kanjiButton.isHidden = true
        }
        
        topKanjis = [UIImage]()
        
        if self.addedView.count > 0 {
            self.addedView.forEach {imView in
                imView.removeFromSuperview()
            }
            self.addedView = [UIImageView]()
        }
    
    }
    
    func getBezierPathFor(phrase: String, _ completion:@escaping (([[(score: Float, path: UIBezierPath)]]) -> ())) {
        // receive closure as argument... to resolve the problem of object being returned before response arrives (asynchronous processing)
        
        let request: Parameters = ["data": phrase]
        
        let group = DispatchGroup()
        
        // initialize
        var p1 = [(score: Float, path: UIBezierPath)]() // path for first component
        var p2 = [(score: Float, path: UIBezierPath)]() // for second
        
        group.enter()
        // replace with "http://localhost:2036/post" for testing
        Alamofire.request("http://localhost:2036/post", method: .post, parameters: request).responseJSON {response in
            switch response.result {
            case .success:
                p1 = self.parsePaths(response: response)
            case .failure:
                return
            }
            print("got response from 1st model")
            group.leave()
        }
        
        group.enter()
        Alamofire.request("http://localhost:2037/post", method: .post, parameters: request).responseJSON {response in
            switch response.result {
            case .success:
                p2 = self.parsePaths(response: response)
            case .failure:
                return
            }
            print("got response from 2nd model")
            group.leave()
        }
        
        group.notify(queue: .main) {
            print("received all response")
            completion([p1, p2])
        }
        
    }
    
    func parsePaths(response: DataResponse<Any>) -> [(score: Float, path: UIBezierPath)] {
        
        var paths = [(score: Float, path: UIBezierPath)]()
        guard let result = response.result.value else {
            return paths
        }
        
        // json形式でPython fonttoolsのbezier pathを受け取る
        let json = JSON(result)
        let pathsData = json["paths"]
        
        for rank in 1...pathsData.count {
            // TODO 複数取ってこれるようにしたけどこれをどう返すか
            
            let path = UIBezierPath()
            
            let pathData = pathsData[String(rank)]
            let predScore = pathData["score"].floatValue
            
            for (_, p) in pathData["path"] {
                let type = p[0]
                
                // starting points
                if type == "moveTo" {
                    let coord = p[1][0]
                    let pt1: CGPoint = CGPoint(x: coord[0].intValue, y: coord[1].intValue)
                    path.move(to: pt1)
                }
                    
                    // draw lines linearly
                else if type == "lineTo" {
                    let coord = p[1][0]
                    let pt1: CGPoint = CGPoint(x: coord[0].intValue, y: coord[1].intValue)
                    path.addLine(to: pt1)
                }
                    
                    // curved lines
                else if type == "curveTo" {
                    if var coords = p[1].array, coords.count > 0 {
                        let dest = coords.removeLast()
                        let ptdest: CGPoint = CGPoint(x: dest[0].intValue, y: dest[1].intValue)
                        
                        // control points
                        let pt1: CGPoint = CGPoint(x: coords[0][0].intValue, y: coords[0][1].intValue)
                        let pt2: CGPoint = CGPoint(x: coords[1][0].intValue, y: coords[1][1].intValue)
                        
                        path.addCurve(to: ptdest, controlPoint1: pt1, controlPoint2: pt2)
                    }
                }
                    
                else {
                    path.close()
                }
                
            }
            
            paths.append((predScore, path))
            
        }
        
        return paths
    }
    
    func drawKanji(_ rect: CGRect, kanjiData: [[(score: Float, path: UIBezierPath)]]) -> [UIImage] {
        
        var kanjiCombi = [(score: Float, path1: UIBezierPath, path2: UIBezierPath)]()
        
        let pathsFirst = kanjiData[0] // へんモデルに対応
        let pathsSecond = kanjiData[1]
        
        for i in 0..<pathsFirst.count {
            for j in 0..<pathsSecond.count {
                let score = pathsFirst[i].score + pathsSecond[j].score
                kanjiCombi.append((score: score, path1: pathsFirst[i].path, path2: pathsSecond[j].path))
            }
        }
        
        kanjiCombi.sort{ $0.score > $1.score }
        
        
        var images = [UIImage]()
        
        for i in 0..<6 {
            // とりあえず左右2パーツ('⿰')に配置してみる
            let imageView = UIImageView(frame: rect)
            // へんに対応
            let path1 = kanjiCombi[i].path1
            var pathArea = path1.bounds

            var OriginTransform = CGAffineTransform(translationX: -pathArea.minX, y: -pathArea.minY)

            var scaleFit = min(rect.width / (pathArea.maxX - pathArea.minX), rect.height / (pathArea.maxY - pathArea.minY))
            var fitTransform = CGAffineTransform(scaleX: scaleFit, y: scaleFit)

            var transform = OriginTransform.concatenating(fitTransform)
            path1.apply(transform)

            UIGraphicsBeginImageContextWithOptions(path1.bounds.size, false, 0.0)

            UIColor.black.setFill()
            path1.fill()

            path1.stroke()

            let image1 = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            let imSubView1 = UIImageView(frame: rect)
            var tmpView = UIImageView(image: image1!.flipVertical())
            tmpView.center = imSubView1.center
            imSubView1.addSubview(tmpView)

            var shrinkTransform = CGAffineTransform(scaleX: 0.4, y: 1.0)
            imSubView1.transform = shrinkTransform
            imSubView1.frame.origin = CGPoint(x: 0.0, y: 0.0)
            imageView.addSubview(imSubView1)
            
            // つくりに対応
            let path2 = kanjiCombi[i].path2
            pathArea = path2.bounds
            
            OriginTransform = CGAffineTransform(translationX: -pathArea.minX, y: -pathArea.minY)
            
            scaleFit = min(rect.width / (pathArea.maxX - pathArea.minX), rect.height / (pathArea.maxY - pathArea.minY))
            fitTransform = CGAffineTransform(scaleX: scaleFit, y: scaleFit)
            
            transform = OriginTransform.concatenating(fitTransform)
            path2.apply(transform)
            
            UIGraphicsBeginImageContextWithOptions(path2.bounds.size, false, 0.0)
            
            UIColor.black.setFill()
            path2.fill()
            
            path2.stroke()
            
            let image2 = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            let imSubView2 = UIImageView(frame: rect)
            tmpView = UIImageView(image: image2!.flipVertical())
            tmpView.center = imSubView2.center
            imSubView2.addSubview(tmpView)
            
            shrinkTransform = CGAffineTransform(scaleX: 0.6, y: 1.0)
            imSubView2.transform = shrinkTransform
            imSubView2.frame.origin = CGPoint(x: rect.width * 0.4, y: 0.0)
            imageView.addSubview(imSubView2)
            
            // convert to image
            UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, 0.0)
            let context: CGContext = UIGraphicsGetCurrentContext()!
            
            imageView.layer.render(in: context)
            
            // contextのビットマップをUIImageとして取得する
            let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            
            // contextを閉じる
            UIGraphicsEndImageContext()
            
            images.append(image)
        }
        
        return images
        
    }
    
    @IBAction func switchDisplayedKanji(_ sender: UIButton) {
        guard let labelTapped = sender.titleLabel?.text else {
            return
        }
        
        let idTapped = Int(labelTapped) ?? 0
        
        if self.addedView.count > 0 {
            self.addedView.forEach {imView in
                imView.removeFromSuperview()
            }
            self.addedView = [UIImageView]()
        }
        
        let kanjiCanvas = UIImageView(image: self.topKanjis[idTapped])
        
        kanjiCanvas.frame.origin = CGPoint(x: 100, y: self.descLabel.frame.maxY + 75)
        
        self.view.addSubview(kanjiCanvas)
        self.addedView.append(kanjiCanvas)
    }
    
    
    @IBAction func shareKanjiImage(_ sender: Any) {
        guard let shareImage = topKanjis.first else {
            return
        }
        
        let shareText = "「\(phraseField.text!)」に最も近い意味の感じはこれ！"
        
        let activities = [shareText, shareImage] as [Any]
        let activityVC = UIActivityViewController(activityItems: activities, applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        self.present(activityVC, animated: true, completion: nil)
        
    }
    
    @IBAction func tapView(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        sendPhrase(goButton!)
        return false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
