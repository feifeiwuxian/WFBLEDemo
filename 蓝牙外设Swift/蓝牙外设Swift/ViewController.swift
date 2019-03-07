//
//  ViewController.swift
//  蓝牙外设Swift
//
//  Created by 王飞 on 2018/1/12.
//  Copyright © 2018年 wuhao. All rights reserved.
//

import UIKit
import CoreBluetooth

public let  MAX_SIZE: Int = 18;

/**开始标志*/
public let START_BYTE: UInt8 = 0x01;
/**继续标志*/
public let CONTINUE_BYTE: UInt8 = 0x02;
/**结束标志*/
public let END_BYTE: UInt8 = 0x00;

private let Service_UUID: String = "CDD1"
private let Characteristic_UUID: String = "CDD2"

class ViewController: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    private var peripheralManager: CBPeripheralManager?
    private var characteristic: CBMutableCharacteristic?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "蓝牙外设"
        peripheralManager = CBPeripheralManager.init(delegate: self, queue: .main)
        // 王飞的一些其它测试
       
    }
    
    @IBAction func didClickPost(_ sender: Any) {
//        peripheralManager?.updateValue((textField.text ?? "empty data!").data(using: .utf8)!, for: characteristic!, onSubscribedCentrals: nil)
        
        //        var a:UInt8 = 0x00
        //        //        let bytes = [UInt8](data!)
        //        var dataAll = Data()
        //        dataAll.append([a], count: 1)
        
        sentData(str: (textField.text ?? "empty data!"))
    }
    
    func sentData(str: String){

        
        let dataArr = encode(strData: str)
        // 分段发送
        var time: TimeInterval = 0
        for data in dataArr {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time) {
                //code
                print("1 秒后输出")
                self.writeData(data: data)
            }
            time += 1
        }
    }
    
    func writeData(data:Data){
        peripheralManager?.updateValue(data, for: characteristic!, onSubscribedCentrals: nil)
        print("发送了1" + (String(data: data, encoding: String.Encoding.utf8) ?? "--"))

    }
    
    func encode(strData: String) -> [Data] {
        var totalData = [Data]()
        
        let originData = strData.data(using: .utf8)
        
        let size = Int(ceilf( Float(originData?.count ?? 0) / Float(MAX_SIZE)))
        
        var start = 0
        var end = 0
        var index = 0
        
        while index < size {
            var data = Data()
            index += 1
            if index == size {
                data.append(Data(bytes: [END_BYTE]))
            }else if index == 1 {
                data.append(Data(bytes: [START_BYTE]))
            } else {
                data.append(Data(bytes: [CONTINUE_BYTE]))
            }
            end = min(start + MAX_SIZE, originData?.count ?? 0);
            
            let addData = originData?.subdata(in: Range<Data.Index>(NSRange(location: start, length: end - start))!)
            data.append(addData!);
            start = end
            totalData.append(data)
        }
        
        
        
        return totalData
    }
}




extension ViewController: CBPeripheralManagerDelegate {
    
    // 蓝牙状态
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unknown:
            print("未知的")
        case .resetting:
            print("重置中")
        case .unsupported:
            print("不支持")
        case .unauthorized:
            print("未验证")
        case .poweredOff:
            print("未启动")
        case .poweredOn:
            print("可用")
            // 创建Service（服务）和Characteristics（特征）
            setupServiceAndCharacteristics()
            // 根据服务的UUID开始广播
            self.peripheralManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [CBUUID.init(string: Service_UUID)]])
        }
    }
    
    /** 创建服务和特征
     注意swift中枚举的按位运算 '|' 要用[.read, .write, .notify]这种形式
     */
    private func setupServiceAndCharacteristics() {
        let serviceID = CBUUID.init(string: Service_UUID)
        let service = CBMutableService.init(type: serviceID, primary: true)
        let characteristicID = CBUUID.init(string: Characteristic_UUID)
        let characteristic = CBMutableCharacteristic.init(type: characteristicID,
                                                          properties: [.read, .write, .notify],
                                                          value: nil,
                                                          permissions: [.readable, .writeable])
        service.characteristics = [characteristic]
        self.peripheralManager?.add(service)
        self.characteristic = characteristic
    }
    
    /** 中心设备读取数据的时候回调 */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        // 请求中的数据，这里把文本框中的数据发给中心设备
        request.value = self.textField.text?.data(using: .utf8)
        // 成功响应请求
        peripheral.respond(to: request, withResult: .success)
    }
    
    /** 中心设备写入数据 */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        let request = requests.last!
        self.textField.text = String.init(data: request.value!, encoding: String.Encoding.utf8)
    }
    
    /** 订阅成功回调 */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("\(#function) 订阅成功回调")
    }
    
    /** 取消订阅回调 */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("\(#function) 取消订阅回调")
    }
    
}



