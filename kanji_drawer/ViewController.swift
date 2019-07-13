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

extension UIColor {
    class var osColorBlue: UIColor {
        return UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 0.8)
    }
    class var osColorRed: UIColor {
        return UIColor(red: 1.0, green: 59.0/255.0, blue: 48.0/255.0, alpha: 0.8)
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
    }
    
    @IBAction func sendPhrase(_ sender: Any) {
        guard let phrase = phraseField.text, phraseField.text!.count > 0 else {
            return
        }
        
        self.clearCanvas(sender)
        // ここでbezier pathの受け取りに成功
        self.getBezierPathFor(phrase: phrase, {kanjiData in
            let kanjiImage = self.drawKanji(CGRect(x: 0, y: 0, width: 300, height: 300), kanjiData: kanjiData)
            
            // TODO: drawKanjiの返り値を複数漢字(list)化
            // 0..<kanjiImage.count, kanjiImage -> kanjiImages[i]に修正
            for _ in 0..<6 {
                self.topKanjis.append(kanjiImage)
            }
            
            let kanjiCanvas = UIImageView(image: kanjiImage)
            
            self.descLabel.text = "「\(phrase)」に近い意味の漢字"
            self.descLabel.isHidden = false
            
            kanjiCanvas.frame.origin = CGPoint(x: 100, y: self.descLabel.frame.maxY + 75)
            kanjiCanvas.alpha = 0
            
            self.view.addSubview(kanjiCanvas)
            self.addedView.append(kanjiCanvas)
            
            self.topKanjiLabel.isHidden = false
            
            for i in 0..<6 {
                self.topKanjiButtons[i].setImage(self.topKanjis[i].resizeImage(width: 60, height: 60), for: .normal)
                self.topKanjiButtons[i].imageEdgeInsets = UIEdgeInsets(top: 5, left: 25, bottom: 5, right: 25)
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
    
    func getBezierPathFor(phrase: String, _ after:@escaping ((Int, [UIBezierPath])) -> ()){
        // receive closure as argument... to resolve the problem of object being returned before response arrives (asynchronous processing)
        
        let request: Parameters = ["data": phrase]
        Alamofire.request("http://localhost:2036/post", method: .post, parameters: request).responseJSON {response in
            switch response.result {
            case .success:
                let kanjiPaths = self.parsePath(response: response)
                after(kanjiPaths)
            case .failure:
                return
            }
        }
        
    }
    
    func parsePath(response: DataResponse<Any>) -> (shape: Int, paths: [UIBezierPath]) {
        
        var kanjiPaths = [UIBezierPath]()
        guard let result = response.result.value else {
            return (0, kanjiPaths)
        }
        
        // json形式でPython fonttoolsのbezier pathを受け取る
        let json = JSON(result)
        
        let shape = json["shape"].intValue
        let paths = json["paths"]
        
        for i in 0..<paths.count {
            let kanjiPath = UIBezierPath()
            
            let pathI = paths[String(i)]
            for (_, path) in pathI["path"] {
                let type = path[0]
                
                // starting points
                if type == "moveTo" {
                    let coord = path[1][0]
                    let p1: CGPoint = CGPoint(x: coord[0].intValue, y: coord[1].intValue)
                    kanjiPath.move(to: p1)
                }
                    
                    // draw lines linearly
                else if type == "lineTo" {
                    let coord = path[1][0]
                    let p1: CGPoint = CGPoint(x: coord[0].intValue, y: coord[1].intValue)
                    kanjiPath.addLine(to: p1)
                }
                    
                    // curved lines
                else if type == "curveTo" {
                    if var coords = path[1].array, coords.count > 0 {
                        let dest = coords.removeLast()
                        let pdest: CGPoint = CGPoint(x: dest[0].intValue, y: dest[1].intValue)
                        
                        // control points
                        let p1: CGPoint = CGPoint(x: coords[0][0].intValue, y: coords[0][1].intValue)
                        let p2: CGPoint = CGPoint(x: coords[1][0].intValue, y: coords[1][1].intValue)
                        
                        kanjiPath.addCurve(to: pdest, controlPoint1: p1, controlPoint2: p2)
                    }
                }
                    
                else {
                    kanjiPath.close()
                }
            }
            kanjiPaths.append(kanjiPath)
        }
        return (shape, kanjiPaths)
        
    }
    
    func drawKanji(_ rect: CGRect, kanjiData: (shape: Int, paths: [UIBezierPath])) -> UIImage {
        
        let imageView = UIImageView(frame: rect)
        
        if kanjiData.shape == 0 {
            // そもそも1パーツで構成されている場合
            
            let path = kanjiData.paths[0]
            let pathArea = path.bounds
            
            let OriginTransform = CGAffineTransform(translationX: -pathArea.minX, y: -pathArea.minY)
            
            let scale = min(rect.width / (pathArea.maxX - pathArea.minX), rect.height / (pathArea.maxY - pathArea.minY))
            let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
            
            let transform = OriginTransform.concatenating(scaleTransform)
            path.apply(transform)
            
            UIGraphicsBeginImageContextWithOptions(path.bounds.size, false, 0.0)
            
            UIColor.black.setFill()
            path.fill()
            
            path.stroke()
            
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            let tmpView = UIImageView(image: image!.flipVertical())
            tmpView.center = imageView.center
            imageView.addSubview(tmpView)
        }
            
        else if kanjiData.shape == 1 {
            // とりあえず左右2パーツ('⿰')に対応する分岐を実装
            
            let ratio: [CGFloat] = [0.0, 0.4, 1.0] // 左右パーツの幅比率 (累積)
            let rects = [CGSize(width: rect.width * (ratio[1] - ratio[0]), height: rect.height), CGSize(width: rect.width * (ratio[2] - ratio[1]), height: rect.height)]
            
            for i in 0..<min(kanjiData.paths.count, rects.count) {
                
                let path = kanjiData.paths[i]
                let pathArea = path.bounds
                let OriginTransform = CGAffineTransform(translationX: -pathArea.minX, y: -pathArea.minY)
                
                let scaleFit = min(rect.width / (pathArea.maxX - pathArea.minX), rect.height / (pathArea.maxY - pathArea.minY))
                let fitTransform = CGAffineTransform(scaleX: scaleFit, y: scaleFit)
                
                let transform = OriginTransform.concatenating(fitTransform)
                path.apply(transform)
                
                UIGraphicsBeginImageContextWithOptions(path.bounds.size, false, 0.0)
                
                UIColor.black.setFill()
                path.fill()
                
                path.stroke()
                
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                let imSubView = UIImageView(frame: rect)
                let tmpView = UIImageView(image: image!.flipVertical())
                tmpView.center = imSubView.center
                imSubView.addSubview(tmpView)
                
                let shrinkTransform = CGAffineTransform(scaleX: ratio[i + 1] - ratio[i], y: 1.0)
                imSubView.transform = shrinkTransform
                imSubView.frame.origin = CGPoint(x: rect.width * ratio[i], y: 0.0)
                imageView.addSubview(imSubView)
            }
        }
            
        else if kanjiData.shape == 2 {
            // 上下2パーツ('⿱')に対応する分岐
            let ratio: [CGFloat] = [0.0, 0.4, 1.0] // 左右パーツの幅比率 (累積)
            let rects = [CGSize(width: rect.width, height: rect.height * (ratio[1] - ratio[0])), CGSize(width: rect.width, height: rect.height * (ratio[2] - ratio[1]))]
            
            for i in 0..<min(kanjiData.paths.count, rects.count) {
                
                let path = kanjiData.paths[i]
                let pathArea = path.bounds
                let OriginTransform = CGAffineTransform(translationX: -pathArea.minX, y: -pathArea.minY)
                
                let scaleFit = min(rect.width / (pathArea.maxX - pathArea.minX), rect.height / (pathArea.maxY - pathArea.minY))
                let fitTransform = CGAffineTransform(scaleX: scaleFit, y: scaleFit)
                
                let transform = OriginTransform.concatenating(fitTransform)
                path.apply(transform)
                
                UIGraphicsBeginImageContextWithOptions(path.bounds.size, false, 0.0)
                
                UIColor.black.setFill()
                path.fill()
                
                path.stroke()
                
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                let imSubView = UIImageView(frame: rect)
                let tmpView = UIImageView(image: image!.flipVertical())
                tmpView.center = imSubView.center
                imSubView.addSubview(tmpView)
                
                let shrinkTransform = CGAffineTransform(scaleX: 1.0, y: ratio[i + 1] - ratio[i])
                imSubView.transform = shrinkTransform
                imSubView.frame.origin = CGPoint(x: 0.0, y: rect.height * ratio[i])
                imageView.addSubview(imSubView)
            }
        }
            
        else {
            print("Not implemented yet.")
        }
        
        // convert to image
        
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, 0.0)
        let context : CGContext = UIGraphicsGetCurrentContext()!
        
        imageView.layer.render(in: context)
        
        // contextのビットマップをUIImageとして取得する
        let image : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        // contextを閉じる
        UIGraphicsEndImageContext()
        
        return image
        
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
