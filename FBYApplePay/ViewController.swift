//
//  ViewController.swift
//  FBYApplePay
//
//  Created by fanbaoying on 2021/6/21.
//

import UIKit
import PassKit

class ViewController: UIViewController {
    
    var remindLab1: UILabel!
    var remindLab2: UILabel!
    var remindLab3: UILabel!
    var whiteOutlineButton: PKPaymentButton!
    var blackButton: PKPaymentButton!
    var shippingContact: PKContact {
        let address = CNMutablePostalAddress()
        address.street = "1 Apple Park Way"
        address.city = "Cupertino"
        address.state = "CA"
        address.postalCode = "95014"
        address.isoCountryCode = "US"
        
        let contact = PKContact()
        contact.postalAddress = address
        
        return contact
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if !PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: [PKPaymentNetwork.visa, PKPaymentNetwork.chinaUnionPay]) {
            print("跳转到 Wallet 页面添加银行卡")
            remindLab1 = UILabel(frame: CGRect(x: 50, y: 230, width: view.frame.width - 100, height: 30))
            remindLab1.text = "跳转到 Wallet 页面添加银行卡"
            remindLab1.textAlignment = NSTextAlignment.center
            self.view.addSubview(remindLab1)

            whiteOutlineButton = PKPaymentButton(paymentButtonType: .plain, paymentButtonStyle: .whiteOutline)
            whiteOutlineButton.frame = CGRect(x: 50, y: 270, width: view.frame.width - 100, height: 50)
            whiteOutlineButton.addTarget(self, action: #selector(jump), for: .touchUpInside)
            self.view.addSubview(whiteOutlineButton)
        }
        
        remindLab2 = UILabel(frame: CGRect(x: 50, y: 380, width: view.frame.width - 100, height: 30))
        remindLab2.text = "点击按钮直接唤起支付购买"
        remindLab2.textAlignment = NSTextAlignment.center
        self.view.addSubview(remindLab2)
        
        blackButton = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        blackButton.frame = CGRect(x: 50, y: 420, width: view.frame.width - 100, height: 50)
        blackButton.addTarget(self, action: #selector(buy), for: .touchUpInside)
        self.view.addSubview(blackButton)

        if !PKPaymentAuthorizationViewController.canMakePayments() {
            remindLab3 = UILabel(frame: CGRect(x: 50, y: 230, width: view.frame.width - 100, height: 30))
            remindLab3.text = "当前设备不支持支付"
            remindLab3.textAlignment = NSTextAlignment.center
            self.view.addSubview(remindLab3)
            
            remindLab1.isHidden = true
            remindLab2.isHidden = true
            whiteOutlineButton.isHidden = true
            blackButton.isHidden = true
            print("当前设备不支持支付")
            return
        }
    }
    
    @objc func jump() {
        let pl = PKPassLibrary()
        pl.openPaymentSetup()
    }
    
    @objc func buy() {
        print("开始创建支付账单")
        
        // 1. 创建支付请求
        let payRequest = PKPaymentRequest()
        // 1.1 配置支付请求
        // 商家 ID
        payRequest.merchantIdentifier = "merchant.fbyapplepay.com"
        // 货币代码以及国家代码
        payRequest.countryCode = "CN"
        payRequest.currencyCode = "CNY"
        
        // 配置支持的支付网络
        payRequest.supportedNetworks = [PKPaymentNetwork.visa, PKPaymentNetwork.chinaUnionPay]
        
        // 配置商户的处理方式
        payRequest.merchantCapabilities = PKMerchantCapability.capability3DS
        
        // 配置购买的商品列表
        let price1 = NSDecimalNumber(string: "10.0")
        let item1 = PKPaymentSummaryItem(label: "iPhone 12", amount: price1)
        
        let price2 = NSDecimalNumber(string: "20.0")
        let item2 = PKPaymentSummaryItem(label: "iPhone 12 Pro", amount: price2)
        
        let price3 = NSDecimalNumber(string: "30.0")
        let item3 = PKPaymentSummaryItem(label: "iPhone 12 Pro Max", amount: price3)
        
        var totalAmount = NSDecimalNumber()
        totalAmount = totalAmount.adding(price1)
        totalAmount = totalAmount.adding(price2)
        totalAmount = totalAmount.adding(price3)
        
        let total = PKPaymentSummaryItem.init(label: "FBY账单总金额", amount: totalAmount, type: PKPaymentSummaryItemType.pending)
        
        payRequest.paymentSummaryItems = [item1, item2, item3, total]
        
        // 1.2 配置快递方式
        let price5 = NSDecimalNumber(string: "18.0")
        let method = PKShippingMethod(label: "SF快递", amount: price5)
        method.detail = "24 小时内送到"
        method.identifier = "SF"
//        let today = Date()
//        let calendar = Calendar.current
//
//        let shippingStart = calendar.date(byAdding: .day, value: 3, to: today)!
//        let shippingEnd = calendar.date(byAdding: .day, value: 7, to: today)!
//
//        let components: Set<Calendar.Component> = [.calendar, .year, .month, .day]
//        let start = calendar.dateComponents(components, from: shippingStart)
//        let end = calendar.dateComponents(components, from: shippingEnd)
//        method.dateComponentsRange = PKDateComponentsRange(start: start, end: end)
        let price6 = NSDecimalNumber(string: "10.0")
        let method1 = PKShippingMethod(label: "YD快递", amount: price6)
        method1.detail = "送货上门"
        method1.identifier = "YD"
        
        payRequest.shippingMethods = [method, method1]
        payRequest.shippingType = PKShippingType.storePickup
        payRequest.shippingContact = shippingContact
        
        payRequest.supportsCouponCode = true
        
        // 2 验证用户的支付授权
        let avc = PKPaymentAuthorizationViewController(paymentRequest: payRequest)
        if avc == nil {
            print("授权控制器创建失败")
        }
        avc!.delegate = self
        self.present(avc!, animated: true, completion: nil)
    }


}

extension ViewController:PKPaymentAuthorizationViewControllerDelegate {
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {

        print("payment token:\(payment.token)")
        // 一般在此处,拿到支付信息, 发送给服务器处理, 处理完毕之后, 服务器会返回一个状态, 告诉客户端,是否支付成功, 然后由客户端进行处理
        completion(PKPaymentAuthorizationResult.init(status: .success, errors: nil))

    }
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        print("取消或者交易完成")
        self.dismiss(animated: true, completion: nil)
    }
    
//    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didChangeCouponCode couponCode: String, handler completion: @escaping (PKPaymentRequestCouponCodeUpdate) -> Void) {
//
//        func appleDiscount (items: [PKPaymentSummaryItem]) -> [PKPaymentSummaryItem] {
//            let subtotal = items.first!
//            let couponDiscountItem = PKPaymentSummaryItem(label: "Coupon code Applied", amount: NSDecimalNumber(string: "-5.00"))
//            let updatedTax = PKPaymentSummaryItem(label: "Tax", amount: NSDecimalNumber(string: "1.84"))
//            let updatedTotal = PKPaymentSummaryItem(label: "Food Festival", amount: NSDecimalNumber(string: "24.84"))
//            let discountedItems = [subtotal, couponDiscountItem, updatedTax, updatedTotal]
//            return discountedItems
//        }
//        if couponCode.isEmpty {
//            completion(PKPaymentRequestCouponCodeUpdate(paymentSummaryItems: paymentSummaryItems))
//        } else if couponCode.uppercased() == "FESTIVAL" {
//            completion(PKPaymentRequestCouponCodeUpdate(paymentSummaryItems: appleDiscount(items: paymentSummaryItems)))
//        } else {
//            let error = PKPaymentRequest.paymentCouponCodeInvalidError(localizedDescription: "Coupon code is not valid.")
//            completion(PKPaymentRequestCouponCodeUpdate(errors: [error], paymentSummaryItems: summaryItems, shippingMethods: []))
//        }
//    }
}
