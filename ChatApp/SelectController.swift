//
//  SelectController.swift
//  ChatApp
//
//  Created by 西谷恭紀 on 2019/06/17.
//  Copyright © 2019 西谷恭紀. All rights reserved.
//

import UIKit
//import FirebaseStorage
//import SDWebImage

class SelectController: UIViewController {
    
    @IBOutlet var gorillaImage1: UIButton!
    @IBOutlet var gorillaImage2: UIButton!
    @IBOutlet var gorillaImage3: UIButton!
    @IBOutlet var gorillaImage4: UIButton!
    @IBOutlet var gorillaImage5: UIButton!
    @IBOutlet var gorillaImage6: UIButton!
    
    var selectedImage:UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ボタンの設定
        gorillaImage1.setImage(UIImage.init(named: "gorilla1"), for: UIControl.State.normal)
        gorillaImage1.layer.cornerRadius = 30
        gorillaImage1.layer.shadowOpacity = 0.5
        gorillaImage1.layer.shadowRadius = 30
        gorillaImage1.layer.shadowColor = UIColor.black.cgColor
        gorillaImage1.layer.shadowOffset = CGSize(width: 5, height: 5)
        
        gorillaImage2.setImage(UIImage.init(named: "gorilla4"), for: UIControl.State.normal)
        gorillaImage2.layer.cornerRadius = gorillaImage2.frame.size.width * 0.1
        gorillaImage2.clipsToBounds = true
        gorillaImage2.layer.cornerRadius = 30
        gorillaImage2.layer.shadowOpacity = 0.5
        gorillaImage2.layer.shadowRadius = 30
        gorillaImage2.layer.shadowColor = UIColor.black.cgColor
        gorillaImage2.layer.shadowOffset = CGSize(width: 5, height: 5)
        
        gorillaImage3.setImage(UIImage.init(named: "gorilla6"), for: UIControl.State.normal)
        gorillaImage3.layer.cornerRadius = gorillaImage3.frame.size.width * 0.1
        gorillaImage2.clipsToBounds = true
        gorillaImage3.layer.cornerRadius = 30
        gorillaImage3.layer.shadowOpacity = 0.5
        gorillaImage3.layer.shadowRadius = 30
        gorillaImage3.layer.shadowColor = UIColor.black.cgColor
        gorillaImage3.layer.shadowOffset = CGSize(width: 5, height: 5)
        
        gorillaImage4.setImage(UIImage.init(named: "comingsoon"), for: UIControl.State.normal)
        gorillaImage4.layer.cornerRadius = 30
        gorillaImage4.layer.shadowOpacity = 0.5
        gorillaImage4.layer.shadowRadius = 30
        gorillaImage4.layer.shadowColor = UIColor.black.cgColor
        gorillaImage4.layer.shadowOffset = CGSize(width: 5, height: 5)
        
        gorillaImage5.setImage(UIImage.init(named: "comingsoon"), for: UIControl.State.normal)
        gorillaImage5.layer.cornerRadius = 30
        gorillaImage5.layer.shadowOpacity = 0.5
        gorillaImage5.layer.shadowRadius = 30
        gorillaImage5.layer.shadowColor = UIColor.black.cgColor
        gorillaImage5.layer.shadowOffset = CGSize(width: 5, height: 5)
        
        gorillaImage6.setImage(UIImage.init(named: "comingsoon"), for: UIControl.State.normal)
        gorillaImage6.layer.cornerRadius = 30
        gorillaImage6.layer.shadowOpacity = 0.5
        gorillaImage6.layer.shadowRadius = 30
        gorillaImage6.layer.shadowColor = UIColor.black.cgColor
        gorillaImage6.layer.shadowOffset = CGSize(width: 5, height: 5)
        
        
        
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // 遷移先にDetailViewControllerがあるかを確認
        if let chatVC = segue.destination as? ChatViewController {
            // 選択したセルが持つIDを取得し、遷移先に渡す
            if selectedImage != nil {
                chatVC.img = selectedImage
            }
        }
    }
    
    @IBAction func tappedGorilla(_ sender: UIButton) {
        selectedImage = sender.imageView?.image
        performSegue(withIdentifier: "chatRoom", sender: self)
    }
    
}
