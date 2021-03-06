//
//  MainViewController.swift
//  TextClassification
//
//  Created by Skafos.ai on 1/7/19.
//  Copyright © 2019 Skafos, LLC. All rights reserved.
//

import Foundation
import UIKit
import Skafos
import CoreML
import SnapKit

class MainViewController : UIViewController {
  private let classifier:TextClassifier! = TextClassifier()
  private let modelName:String = "TextClassifier"
  
  private lazy var label:UILabel = {
    let label           = UILabel()
    label.text          = ""
    label.font          = label.font.withSize(20)
    label.textAlignment = .center
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    
    self.view.addSubview(label)
    return label
  }()
    
  private lazy var field:UITextField = {
    let field                 = UITextField()
    field.placeholder         = "Enter text to classify"
    field.layer.borderColor   = UIColor.gray.cgColor
    field.layer.borderWidth   = 1.0
    field.textAlignment       = .center
    field.layer.cornerRadius  = 6.0

    self.view.addSubview(field)
    return field
  }()

  private lazy var label_explain:UILabel = {
    let label           = UILabel()
    label.text          = "Enter some text into the textbox above to get a sentiment, spam, or topic classification from the model."
    label.font          = label.font.withSize(14)
    label.textAlignment = .left
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
  
    self.view.addSubview(label)
    return label
  }()
  
  private lazy var button:UIButton = {
    let button = UIButton(type: .custom)
    
    button.setTitle("Submit", for: .normal)
    button.setTitleColor(.blue, for: .normal)
    button.addTarget(self, action: #selector(processText(_:)), for: .touchUpInside)
    
    self.view.addSubview(button)
    return button
  }()
  
  override func viewDidLayoutSubviews() {
    label.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(80)
      make.right.left.equalToSuperview()
      make.height.equalTo(80)
    }
    
    field.snp.makeConstraints { make in
      make.top.equalTo(label.snp.bottom).offset(30)
      make.right.left.equalToSuperview().inset(60)
      make.height.equalTo(50)
    }

    label_explain.snp.makeConstraints { make in
        make.top.equalTo(field.snp.bottom).offset(5)
        make.right.left.equalTo(field)
        make.height.equalTo(125)
    }

    button.snp.makeConstraints { make in
      make.top.equalTo(label_explain.snp.bottom)
      make.right.left.equalTo(label_explain).inset(30)
      make.height.equalTo(60)
    }
    
    super.viewDidLayoutSubviews()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .white
    self.title = "Text Classification"
  }
    
  // Check for model updates when UI view appears
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    let _ = field.becomeFirstResponder()
    // Skafos load
    Skafos.load(asset: self.modelName) { (error, asset) in
      // Log the asset in the console
      console.info(asset)
      guard error == nil else {
        console.error("Skafos load error: \(String(describing: error))")
        return
      }
      if let model = asset.model {
        // Assign the updated model
        self.classifier.model = model
      }
    }
  }
  
  @objc func processText(_ sender:Any? = nil) {
    guard let text = field.text else { return }
    
    let tagger    = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)
    let range     = NSRange(location: 0, length: text.utf16.count)
    tagger.string = text.lowercased()
    
    var bagOfWords = [String:Double]()
    let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther]
    tagger.enumerateTags(in: range, unit: .word, scheme: .tokenType, options: options) { (_, tokenRange, _) in
      let word = (text.lowercased() as NSString).substring(with: tokenRange)
      
      if bagOfWords[word] != nil {
        bagOfWords[word]! += 1
      } else {
        bagOfWords[word] = 1
      }
    }

    let prediction = try! classifier.prediction(text: bagOfWords)
    
    label.text = "Classification: \(prediction.label)"
    debugPrint("Classification: \(prediction.label), Probability: \(prediction.labelProbability)")
  }
}
