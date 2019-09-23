//
//  DetailViewController.swift
//  groupbuyAssist
//
//  Created by 陳昱宏 on 2019/7/30.
//  Copyright © 2019 Mike. All rights reserved.
//

import UIKit
import SwiftyJSON
import NVActivityIndicatorView
import Alamofire

class DetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var detailTable: UITableView! {
        didSet{
            detailTable.delegate = self
            detailTable.dataSource = self
        }
    }
//    讀取中的顯示動畫，此動畫使用第三方套件
//    @IBOutlet weak var actIndicator: UIActivityIndicatorView!
    @IBOutlet weak var nvActIndicat: NVActivityIndicatorView!
    
//    由MasterView傳入的資料
    var detailItem: JSON? {
        didSet {
            // Update the view.
            configureView()
        }
    }
//    存放團購人資訊及購買數量
    var content: [JSON] = []
//    存放原始訊息
    var raw: [JSON] = []
    
    func configureView() {
        // Update the user interface for the detail item.
//        將MasterView傳入的資料拆成content及raw
        guard let detail = detailItem else {return}
//        將undefined例外處理
        if detail["raw"].stringValue == "undefined" {
//            content = detail["content"].arrayValue
//            從userdefaults讀取undefined資訊
            if let undefObj = UserDefaults.standard.array(forKey: "undefined"), content.count == 0 {
                for i in undefObj {
                    content.append(JSON(i))
                }
//                print(content)
            }
        }else{
//        將MasterView傳入的資料拆成content及raw
            raw = detail["raw"].arrayValue
            content = detail["content"].arrayValue
//            停止動畫並隱藏
            nvActIndicat.stopAnimating()
            nvActIndicat.isHidden = true
//            actIndicator.stopAnimating()
//            actIndicator.isHidden = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        設定動畫模式和顏色
//        actIndicator.transform = CGAffineTransform(scaleX: 5, y: 5)
        nvActIndicat.color = UIColor.darkGray
        nvActIndicat.type = .lineScalePulseOutRapid
        
//        若沒有讀到資料就讓動畫開始運作
        if content.count == 0 {
//            actIndicator.startAnimating()
            nvActIndicat.startAnimating()
        }
        configureView()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return content.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        設定每個cell的文字內容
//        先宣告cell變數，到switch case內再定義內容
        var cell:UITableViewCell
        switch indexPath.row {
        case 0:
            cell = tableView.dequeueReusableCell(withIdentifier: "nameCell", for: indexPath)
//            宣告cell文字內容
            var text = content[indexPath.section]["Name"].stringValue
//            將undefined與其他Detail分開處理
            if detailItem?["raw"].stringValue != "undefined" {
                text = text + "\t\t\t»數量：" + content[indexPath.section]["Quantity"].stringValue
                cell.textLabel?.textAlignment = .justified
            }else{
                cell.textLabel?.textAlignment = .center
            }
            cell.textLabel?.text = text
        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: "remarkCell", for: indexPath)
//            宣告cell文字內容
            var text = ""
//            將undefined與其他Detail分開處理
            if detailItem?["raw"].stringValue != "undefined" {
                text = text + "備註： "
//                無remark時標註"(無)"
                if content[indexPath.section]["Remark"].stringValue == "" {
                    text = text + "(無)"
                }else{
                    text = text + content[indexPath.section]["Remark"].stringValue
                }
            }else {
                text = content[indexPath.section]["Message"].stringValue
            }
            cell.textLabel?.text = text
            cell.textLabel?.numberOfLines = 0
        case 2:
            cell = tableView.dequeueReusableCell(withIdentifier: "funcCell", for: indexPath)
            cell.textLabel?.text = "功能表"
        default:
            cell = UITableViewCell.init()
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        點選功能表以外的cell
        if indexPath.row != 2 {
            detailTable.deselectRow(at: indexPath, animated: false)
            return
        }
//        由於每次在送出request到獲得response的期間都會啟動動畫，因此需要確認動畫未啟動才會有反應
        if nvActIndicat.isAnimating {
            detailTable.deselectRow(at: indexPath, animated: false)
            return
        }
//        google apps script的API網址
        let url = "https://"
//        功能表actionSheet
        let detailFunc = UIAlertController(title: "功能表", message: "", preferredStyle: .actionSheet)
//        undefined的actionSheet
        if detailItem?["raw"].stringValue == "undefined" {
//            將無法解析的訊息手動移到其他頁籤的action
            let moveAct = UIAlertAction(title: "歸檔", style: .default, handler: {action in
//                第二層actionSheet
//                讓user選擇要移到哪個頁籤
                let classfyAct = UIAlertController(title: "歸檔", message: "將此訊息移至何處？", preferredStyle: .actionSheet)
                guard let index = self.detailItem?["index"].array else {return}
//                用迴圈加action選項，達到選頁籤的目的
                for i in index {
                    let keywordAct = UIAlertAction(title: i.stringValue, style: .default, handler: {_ in
//                        啟動動畫播放，直到獲得response
                        self.nvActIndicat.isHidden = false
                        self.nvActIndicat.startAnimating()
//                        選擇頁籤(keyword)以後，呼叫Alamofire做移動的request
                        Alamofire.request(url, method: .post, parameters: ["method": "PATCH", "sheet": "undefined", "target": i.stringValue, "value": indexPath.section+2], encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: {response in
                            print(response)
//                            處理回傳值
                            guard let value = response.result.value else {return}
                            let result = JSON(value)
                            if result["executeResult"].stringValue != "success" {
                                print("result ERROR:" + result["reason"].stringValue)
                                return
                            }
//                            移除本地端的訊息
                            self.content.remove(at: indexPath.section)
                            self.detailTable.deleteSections([indexPath.section], with: .fade)
//                            回存UserDefaults前先將[[String:JSON]]整理成[[String:String]]
                            let undefinedObj = self.content.map({$0.dictionaryValue})
                            var udObj : [[String: String]] = []
                            for j in undefinedObj {
                                var tempDic : [String: String] = [:]
                                for k in j {
                                    tempDic[k.key] = k.value.stringValue
                                }
                                udObj.append(tempDic)
                            }
//                            print(undefinedObj)
//                            回存UserDefaults
                            UserDefaults.standard.set(udObj, forKey: "undefined")
//                            停止動畫並隱藏
                            self.nvActIndicat.stopAnimating()
                            self.nvActIndicat.isHidden = true
                        })
                    })
                    classfyAct.addAction(keywordAct)
                }
//                取消的action
                let cancelAct = UIAlertAction(title: "取消", style: .cancel, handler: nil)
                classfyAct.addAction(cancelAct)
//                若為popover模式，則需指定一個pop source
                classfyAct.popoverPresentationController?.sourceView = self.view
                classfyAct.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.minY, width: 0, height: 0)
                self.present(classfyAct, animated: true, completion: nil)
            })
            detailFunc.addAction(moveAct)
//            將無法解析的訊息手動刪除
            let deleteAct = UIAlertAction(title: "刪除", style: .default, handler: {action in
//                第二層對話框
//                讓user輸入"delete"的防誤刪機制
                let delAct = UIAlertController(title: "確認刪除", message: "刪除後無法復原\n請輸入\"delete\"確認刪除", preferredStyle: .alert)
                delAct.addTextField(configurationHandler: nil)
//                確認刪除的action
                let okAct = UIAlertAction(title: "確定", style: .default, handler: {_ in
                    if delAct.textFields?[0].text != "delete" {
//                        delAct.textFields?[0].text = ""
                        return
                    }
//                    啟動動畫播放，直到獲得response
                    self.nvActIndicat.isHidden = false
                    self.nvActIndicat.startAnimating()
//                    確認user有輸入"delete"以後，呼叫Alamofire做刪除的request
                    Alamofire.request(url, method: .post, parameters:["method": "DELETE", "sheet": "undefined", "value": indexPath.section+2], encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: {response in
                        print(response)
//                        處理回傳值
                        let result = JSON(response.result.value!)
                        if result["executeResult"].stringValue != "success" {
                            print("result ERROR:" + result["reason"].stringValue)
                            return
                        }
//                        移除本地端的訊息
                        self.content.remove(at: indexPath.section)
                        self.detailTable.deleteSections([indexPath.section], with: .fade)
//                      回存UserDefaults前先整理成[[String:String]]
                        var undefinedObj: [[String: String]] = []
                        for i in self.content {
                            var dicObj: [String: String] = [:]
                            for j in i {
                                dicObj[j.0] = j.1.stringValue
                            }
                            undefinedObj.append(dicObj)
                        }
//                        print(undefinedObj)
                        UserDefaults.standard.set(undefinedObj, forKey: "undefined")
//                        停止動畫並隱藏
                        self.nvActIndicat.stopAnimating()
                        self.nvActIndicat.isHidden = true
                    })
                })
                delAct.addAction(okAct)
//                取消的action
                let cancelAct = UIAlertAction(title: "取消", style: .cancel, handler: nil)
                delAct.addAction(cancelAct)
                self.present(delAct, animated: true, completion: nil)
            })
            detailFunc.addAction(deleteAct)
        }else{
//            非undefined的actionSheet
//            修改數量的action
            let modifyAct = UIAlertAction(title: "修改數量", style: .default, handler: {action in
//                第二層對話框
//                讓user輸入數量
                let remarkController = UIAlertController(title: "數量", message: "", preferredStyle: .alert)
                remarkController.addTextField(configurationHandler: {textField in
                    textField.text = self.content[indexPath.section]["Quantity"].stringValue
//                    設定輸入鍵盤樣式
//                    textField.keyboardType = .numberPad
                })
                let okAct = UIAlertAction(title: "OK", style: .default, handler: {_ in
//                    第二層，確認的action
                    if let quant = remarkController.textFields?[0].text {
//                        guard let _ = Int(quant) else{return}
//                        確認textfield有修改過
                        if quant == self.content[indexPath.section]["Quantity"].stringValue {return}
//                        啟動動畫播放，直到獲得response
                        self.nvActIndicat.isHidden = false
                        self.nvActIndicat.startAnimating()
//                        呼叫Alamofire做修改的request
                        Alamofire.request(url, method: .post, parameters: ["method": "PATCH", "sheet": self.navigationItem.title!, "target": self.content[indexPath.section]["ID"].stringValue, "value": ["Quantity": quant]], encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: {response in
                            print(response)
//                            處理回傳值
                            let result = JSON(response.result.value!)
                            if result["executeResult"].stringValue != "success" {
                                print("result ERROR:" + result["reason"].stringValue)
                                return
                            }
//                            修改本地端的資訊
                            self.content[indexPath.section]["Quantity"].string = quant
                            let text = self.content[indexPath.section]["Name"].stringValue + "\t\t\t»數量：" + self.content[indexPath.section]["Quantity"].stringValue
                            let quantIndex = IndexPath.init(row: indexPath.row-2, section: indexPath.section)
                            self.detailTable.cellForRow(at: quantIndex)?.textLabel?.text = text
//                            停止動畫並隱藏
                            self.nvActIndicat.stopAnimating()
                            self.nvActIndicat.isHidden = true
                        })
                    }
                })
                remarkController.addAction(okAct)
//                第二層，取消修改的action
                let cancelAct = UIAlertAction(title: "取消", style: .cancel, handler: nil)
                remarkController.addAction(cancelAct)
                self.present(remarkController, animated: true, completion: nil)
            })
            detailFunc.addAction(modifyAct)
//            修改備註的action
            let remarkAct = UIAlertAction(title: "修改備註", style: .default, handler: {action in
//                第二層對話框
//                讓user修改備註
                let remarkController = UIAlertController(title: "備註", message: "", preferredStyle: .alert)
                remarkController.addTextField(configurationHandler: {textField in
//                    初始textField內的文字，若無備註文字則設定placeholder
                    if self.content[indexPath.section]["Remark"].stringValue != "" {
                        textField.text = self.content[indexPath.section]["Remark"].stringValue
                    }else{
                        textField.placeholder = "(無)"
                    }
                })
//                第二層，確認的action
                let okAct = UIAlertAction(title: "OK", style: .default, handler: {_ in
                    if let remark = remarkController.textFields?[0].text {
//                        確認textfield內容有修改過
                        if remark == self.content[indexPath.section]["Remark"].stringValue {return}
//                        啟動動畫播放，直到獲得response
                        self.nvActIndicat.isHidden = false
                        self.nvActIndicat.startAnimating()
//                        呼叫Alamofire做修改的request
                        Alamofire.request(url, method: .post, parameters: ["method": "PATCH", "sheet": self.navigationItem.title!, "target": self.content[indexPath.section]["ID"].stringValue, "value": ["Remark": remark]], encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: {response in
                            print(response)
                            let result = JSON(response.result.value!)
                            if result["executeResult"].stringValue != "success" {
                                print("result ERROR:" + result["reason"].stringValue)
                                return
                            }
//                            修改本地端的資訊
                            self.content[indexPath.section]["Remark"].string = remark
                            var text = "備註： "
                            if self.content[indexPath.section]["Remark"].stringValue == "" {
                                text = text + "(無)"
                            }else{
                                text = text + self.content[indexPath.section]["Remark"].stringValue
                            }
                            let remarkIndex = IndexPath.init(row: indexPath.row-1, section: indexPath.section)
                            self.detailTable.cellForRow(at: remarkIndex)?.textLabel?.text = text
//                            停止動畫並隱藏
                            self.nvActIndicat.stopAnimating()
                            self.nvActIndicat.isHidden = true
                        })
                    }
                })
                remarkController.addAction(okAct)
//                第二層，取消的action
                let cancelAct = UIAlertAction(title: "取消", style: .cancel, handler: nil)
                remarkController.addAction(cancelAct)
                self.present(remarkController, animated: true, completion: nil)
            })
            detailFunc.addAction(remarkAct)
//            第一層，查看raw message的action
            let rawAct = UIAlertAction(title: "查看原始訊息", style: .default, handler: {action in
//                定義一個用來看raw message的controller
                if let controller = self.storyboard?.instantiateViewController(withIdentifier: "RawViewController") as! RawViewController? {
//                    傳送發訊人的ID給controller作為標題使用
                    controller.nameStr = self.content[indexPath.section]["Name"].stringValue
//                    宣告一個新的[JSON]
                    var rawJSON: [JSON] = []
//                    檢查存放原始訊息的JSON
                    for i in self.raw {
//                        發現是此ID的訊息就加入新的[JOSN]
                        if i["ID"].stringValue == self.content[indexPath.section]["ID"].stringValue {
                            rawJSON.append(i)
                        }
                    }
//                    將新的[JSON]傳給controller
                    controller.rawJSON = rawJSON
//                    呼叫這個controller
                    self.present(controller, animated: true, completion: nil)
                }
            })
            detailFunc.addAction(rawAct)
        }
//        第一層，取消的action
        let cancelAct = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        detailFunc.addAction(cancelAct)
//      若為popover模式，則需指定一個pop source
        detailFunc.popoverPresentationController?.sourceView = self.view
        let popHeight = (self.navigationController?.navigationBar.bounds.maxY ?? 0) + tableView.rectForRow(at: indexPath).offsetBy(dx: -tableView.contentOffset.x, dy: -tableView.contentOffset.y).maxY
        detailFunc.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: popHeight, width: 0, height: 0)
        present(detailFunc, animated: true, completion: nil)
        detailTable.deselectRow(at: indexPath, animated: false)
    }
    

}



