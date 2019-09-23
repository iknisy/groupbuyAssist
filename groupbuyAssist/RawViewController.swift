//
//  RawViewController.swift
//  groupbuyAssist
//
//  Created by 陳昱宏 on 2019/8/15.
//  Copyright © 2019 Mike. All rights reserved.
//

import UIKit
import SwiftyJSON

class RawViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var rawTable: UITableView! {
        didSet{
            rawTable.delegate = self
            rawTable.dataSource = self
        }
    }
//    設定標題
    @IBOutlet weak var nameLabel: UILabel! {
        didSet{
            nameLabel.text = nameStr + " 的原始訊息"
        }
    }
//    關閉View
    @IBAction func close(){
        dismiss(animated: true, completion: nil)
    }
//    從DetailView傳入的變數
    var rawJSON: [JSON] = []
    var nameStr = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return rawJSON.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        設定每個cell的文字內容
//        先宣告cell變數，到switch case內再定義內容
        var cell:UITableViewCell
        switch indexPath.row {
        case 0:
//            第一個row，訊息時間
            cell = tableView.dequeueReusableCell(withIdentifier: "timeCell", for: indexPath)
//            將timestamp轉成double
            guard let stamp = Double(rawJSON[indexPath.section]["Timestamp"].stringValue) else {break}
//            將double轉成date
            let date = Date(timeIntervalSince1970: stamp/1000)
//            設定時間格式
            let dFormate = DateFormatter()
            dFormate.dateFormat = "yyyy/MM/dd HH:mm:ss"
//            cell文字內容
            cell.textLabel?.text = dFormate.string(from: date)
//            文字對齊中間
            cell.textLabel?.textAlignment = .center
        case 1:
//            第二個row，訊息內容
            cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
//            cell文字內容
            cell.textLabel?.text = rawJSON[indexPath.section]["Message"].stringValue
//            設定文字多行顯示
            cell.textLabel?.numberOfLines = 0
        default:
            cell = UITableViewCell.init()
        }
        return cell
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
