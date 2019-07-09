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
    
}

class ViewController: UIViewController {

    @IBOutlet weak var phraseField: UITextField!
    
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    
    var kanjiPath = UIBezierPath()
    var addedView = [UIImageView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    
    @IBAction func sendPhrase(_ sender: Any) {
        guard let phrase = phraseField.text, phraseField.text!.count > 0 else {
            return
        }
        
        self.clearCanvas(sender)
        // ここでbezier pathの受け取りに成功
        self.getBezierPathFor(phrase: phrase, {kanjiData in
            let kanjiCanvas = self.drawKanji(CGRect(x: 0, y: 0, width: 300, height: 300), kanjiData: kanjiData)
            // let kanjiCanvas = UIImageView(image: image)
            kanjiCanvas.frame.origin = CGPoint(x: 100, y: 300)
            kanjiCanvas.alpha = 0
            self.view.addSubview(kanjiCanvas)
            self.addedView.append(kanjiCanvas)
        
        UIView.animate(withDuration: 2.0, animations: {
                kanjiCanvas.alpha = 1.0
            })
        })
        
    }
    
    @IBAction func clearCanvas(_ sender: Any) {
        
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
    
    func drawKanji(_ rect: CGRect, kanjiData: (shape: Int, paths: [UIBezierPath])) -> UIImageView {
        
        if kanjiData.shape == 0 {
            let imageView = UIImageView(frame: rect)
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
            
            return imageView
        }
            
        else if kanjiData.shape == 1 {
            // とりあえず左右2パーツ('⿰')に対応する分岐を実装
            let imageView = UIImageView(frame: rect)
            
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
            
            return imageView
        }
            
        else if kanjiData.shape == 2 {
            // 上下2パーツ('⿱')に対応する分岐
            let imageView = UIImageView(frame: rect)
            
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
            
            return imageView
        }
            
        else {
            print("Not implemented yet.")
            return UIImageView()
        }
        
    }
    
}
