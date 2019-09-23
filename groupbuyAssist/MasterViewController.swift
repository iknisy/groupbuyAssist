//
//  MasterViewController.swift
//  groupbuyAssist
//
//  Created by 陳昱宏 on 2019/7/30.
//  Copyright © 2019 Mike. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
//    儲存GET回來的JSON
    var objects : JSON = []
//    儲存keywords
    var indexObj : [String] = []



    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        讀取存在UserDefaults的keywords
        if let keyWords = (UserDefaults.standard.array(forKey: "keyWords")) as? [String] {
            self.indexObj = keyWords
        }
//        連到google apps script的api
        let url = "https://"
//        使用Alamofire做http GET
        Alamofire.request(url).responseJSON(completionHandler: {response in
            print(response.result)
            guard let result = response.result.value else {return}
//            將讀取到的JSON存入objects
            self.objects = JSON(result)
//            將keywords從JSON轉成array
            self.indexObj = self.objects["Index"].arrayValue.map({$0[0].stringValue})
//            第一格是欄位名，所以要remove
            self.indexObj.removeFirst()
//            將keywords和undefined存到UserDefaults
            UserDefaults.standard.set(self.indexObj, forKey: "keyWords")
            if let undefinedObj = self.objects["undefined"].arrayObject {
                print(undefinedObj)
                UserDefaults.standard.set(undefinedObj, forKey: "undefined")
            }
//            重整tableview使其符合實際存放在DB的keywords list
            self.tableView.reloadData()
//            若是分割畫面則自動點選第一項
            if self.splitViewController != nil {
                let indexPath = IndexPath(row: 0, section: 0)
//                顯示已點選
                self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .top)
//                程式碼觸發點選
                self.performSegue(withIdentifier: "showDetail", sender: self)
            }
        })
        
//        設定導覽列的刪除鈕
        editButtonItem.title = nil
        editButtonItem.image = UIImage(named: "delete")
        navigationItem.leftBarButtonItem = editButtonItem

//        Xcode預設
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
//        分割畫面的MasterView設定成固定顯示不隱藏
        splitViewController?.preferredDisplayMode = .allVisible
    }

//    Xcode預設
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
//    新增MasterView的cell物件(關鍵字)
    @objc
    func insertNewObject(_ sender: Any) {
//        objects.insert(NSDate(), at: 0)
        var text = ""
//        設定對話框
        let keyInput = UIAlertController(title: "新增", message: "請輸入要開團的關鍵字", preferredStyle: .alert)
//        增加textfield
        keyInput.addTextField(configurationHandler: {textField in
            textField.placeholder = "keyWord"
//            textField.keyboardType = .webSearch
        })
//        點OK後的動作
        let okAction = UIAlertAction(title: "OK", style: .default, handler: {_ in
//            獲得textfield的內容
            text = keyInput.textFields![0].text!
//            因為DB上已經有"Index","undefined","Keywords"的Sheet名稱，所以keywords不可以是這些詞
            if (text == "Index")||(text == "undefined")||(text == "Keywords") {return}
//            Keyword不可為空字串
            if text == "" {return}
//            使用Alamofire做http POST
            let url = "https://"
            Alamofire.request(url, method: .post, parameters: ["method": "POST", "sheet": "Index", "value": text], encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: {(response) in
//                print(response)
//                如果response有問題則print
                if response.result.isFailure {
                    print(response.result)
                    return
                }
//                如果result狀態不是success則print
                let result = JSON(response.result.value!)
                if result["executeResult"].stringValue != "success" {
                    print("result ERROR:" + result["reason"].stringValue)
                    return
                }
//                DB新增成功後，新增MasterView的項目
                self.indexObj.append(text)
                let indexPath = IndexPath(row: self.indexObj.count, section: 0)
                self.tableView.insertRows(at: [indexPath], with: .automatic)
                if let textlabel = self.tableView.cellForRow(at: indexPath)?.textLabel {
                    textlabel.text = text
                }
            })
        })
        keyInput.addAction(okAction)
//        取消動作
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        keyInput.addAction(cancelAction)
//        顯示以上設定的對話框
        present(keyInput, animated: true, completion: nil)
    }

    // MARK: - Segues
//    點選cell的準備動作
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
//                點選第一項需要特別處理
                if indexPath.row == 0 {
                    let object = JSON(["raw": "undefined", "content": "undefined",  "index": indexObj])
                    controller.navigationItem.title = "系統無法判斷的訊息"
                    controller.detailItem = object
//                    Xcode預設
                    controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                    controller.navigationItem.leftItemsSupplementBackButton = true
                }else{
//                    var object = JSON()
//                    使用Alamofire讀取sheet內容
                    let url = "https://"
                    Alamofire.request(url, method: .post, parameters: ["method": "GET", "sheet": indexObj[indexPath.row-1]], encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: {response in
//                        print(response.result.value)
                        guard let result = response.result.value else {return}
                        let content = JSON(result).arrayValue
//                        獲得content內容以後再使用Alamofire讀取rawSheet的內容
                        Alamofire.request(url, method: .post, parameters: ["method": "GET", "sheet": self.indexObj[indexPath.row-1]+"_RAW"], encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: {response in
//                            print(response.result.value)
                            guard let rawresult = response.result.value else{return}
                            let raw = JSON(rawresult).arrayValue
                            let object = JSON(["raw": raw, "content": content])
//                            設定DetailView標題
                            controller.navigationItem.title = self.indexObj[indexPath.row-1]
//                            傳值給DetailView
                            controller.detailItem = object
//                            Xcode預設
                            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                            controller.navigationItem.leftItemsSupplementBackButton = true
//                            重整DetailView的tableview
                            controller.detailTable.reloadData()
                        })
                    })
//                    let object = objects[indexPath.row]
//                    let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
//                    controller.detailItem = object
//                    controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
//                    controller.navigationItem.leftItemsSupplementBackButton = true
                }
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return indexObj.count+1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "masterCell", for: indexPath)
//        設定cell顯示Keyword
        if indexPath.row == 0 {
            cell.textLabel?.text = "系統無法判斷的訊息"
        }else{
            cell.textLabel!.text = indexObj[indexPath.row-1]
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath.row == 0 {return}
//            objects.remove(at: indexPath.row)
//            tableView.deleteRows(at: [indexPath], with: .fade)
            let url = "https://"
            guard let keyWord = tableView.cellForRow(at: indexPath)?.textLabel?.text else {return}
//            防誤刪對話框
            let delAct = UIAlertController(title: "確認刪除", message: "刪除後無法復原\n請輸入\"delete\"確認刪除", preferredStyle: .alert)
            delAct.addTextField(configurationHandler: nil)
//            確認有輸入"delete"才執行刪除動作
            let okAct = UIAlertAction(title: "確定", style: .default, handler: {_ in
                if delAct.textFields?[0].text != "delete" {
                    delAct.textFields?[0].text = ""
                    return
                }
//                使用Alamofire送出delete的request
                Alamofire.request(url, method: .post, parameters: ["method": "DELETE", "sheet": "Index", "value": keyWord], encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: {response in
                    print(response)
                    let result = JSON(response.result.value!)
                    if result["executeResult"].stringValue != "success" {
                        print("result ERROR:" + result["reason"].stringValue)
                        return
                    }
//                    確認DB端已刪除後，刪除MasterView上的項目
                    self.indexObj.remove(at: indexPath.row-1)
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                })
            })
            delAct.addAction(okAct)
            let cancelAct = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            delAct.addAction(cancelAct)
            self.present(delAct, animated: true, completion: nil)
        }
//        Xcode預設的insert功能
//        else if editingStyle == .insert {
//            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
//        }
    }
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
//        若Edit功能啟動時，按鈕設定為"OK"，禁止新增功能
        if self.isEditing {
            self.editButtonItem.image = nil
            self.editButtonItem.title = "OK"
            navigationItem.rightBarButtonItem?.isEnabled = false
//            若Edit功能未啟動，按鈕顯示為小圖，新增功能可用
        }else{
            self.editButtonItem.title = nil
            self.editButtonItem.image = UIImage(named: "delete")
            navigationItem.rightBarButtonItems![0].isEnabled = true
        }
    }
    
//    關閉DetailView時的動作
//    @IBAction func close(segue: UIStoryboardSegue){
//        print("close")
//        dismiss(animated: true, completion: {
//            let url = ""
//            Alamofire.request(url).responseJSON(completionHandler: {response in
//                print(response.result)
//                guard let result = response.result.value else {return}
//                self.objects = JSON(result)
//                print(self.objects)
//                self.indexObj = self.objects["Index"].arrayValue.map({$0[0].stringValue})
//                self.indexObj.removeFirst()
//                //            print(self.indexObj)
//                UserDefaults.standard.set(self.indexObj, forKey: "keyWords")
//                self.tableView.reloadData()
//            })
//        })
//    }

}

