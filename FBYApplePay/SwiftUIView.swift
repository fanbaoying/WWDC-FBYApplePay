//
//  SwiftUIView.swift
//  FBYApplePay
//
//  Created by fanbaoying on 2022/6/21.
//

import SwiftUI
import PassKit

struct SwiftUIView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
    
    // Add "Add to Apple Wallet" button
    @State var addedToWallet: Bool
    
    @ViewBuilder private var airlineButton: some View {
        if let pass = createAirlinePass() {
            AddPassToWalletButton([pass]) { added in
                addedToWallet = added
            }
            .frame(width: 350, height: 50)
            .addPassToWalletButtonStyle(.blackOutline)
        } else {
            // Fallback
        }
    }
    
    // Add "Pay with Apple Pay" button
    
    // Create a payment request
    let paymentRequest = PKPaymentRequest()
    
    // Create a payment authorization change method
    func authorizationChange(phase: PayWithApplePayButtonPaymentAuthorizationPhase) {...}
    
    PayWithApplePayButton(
        .plain
        request: paymentRequest,
        onPaymentAuthorizationChange: authorizationChange
    ) {
        // Fallback
    }
    .frame(width: 250, height: 50)
    .payWithApplePayButtonStyle(.automatic)
    
    // Multi-merchant payments
    
    // Set total amount
    paymentRequest.paymentSummaryItems = [
        PKPaymentSummaryItem(label: "Total", amount: 500)
    ]
    
    // Create a multi token context for each additional merchant in the payment
    let multiTokenContexts = [
        PKPaymentTokenContext(
            merchantIdentifier: "com.example.air-travel",
            externalIdentifier: "com.example.air-travel",
            merchantName: "Air Travel",
            merchantDomain: "air-travel.example.com",
            amount: 150
        ),
        PKPaymentTokenContext(
            merchantIdentifier: "com.example.hotel",
            externalIdentifier: "com.example.hotel",
            merchantName: "Hotel",
            merchantDomain: "hotel.example.com",
            amount: 300
        ),
        PKPaymentTokenContext(
            merchantIdentifier: "com.example.car-rental",
            externalIdentifier: "com.example.car-rental",
            merchantName: "Car Rental",
            merchantDomain: "car-rental.example.com",
            amount: 50
        )
    ]
    paymentRequest.multiTokenContexts = multiTokenContexts
    
    // Recurring payments
    
    // Specify the amount and billing periods
    let regularBilling = PKRecurringPaymentSummaryItem(label: "Membership", amount: 20)
    
    let trialBilling = PKRecurringPaymentSummaryItem(label: "Trial Membership", amount: 10)
    
    let trialEndDate = Calendar.current.date(byAdding: .month, value: 1, to: Date.now)
    trialBilling.endDate = trialEndDate
    regularBilling.startDate = trialEndDate
    
    // Create a recurring payment request
    let recurringPaymentRequest = PKRecurringPaymentRequest(
        paymentDescription: "Book Club Membership",
        regularBilling: regularBilling,
        managementURL: URL(string: "https://www.example.com/managementURL")
    )
    recurringPaymentRequest.trialBilling = trialBilling
    
    recurringPaymentRequest.billingAgreement = """
    50% off for the first month. You will be charged $20 every month after that until you cancel. \ You may cancel at any time to avoid future charges. To cancel, go to your Account and click \ Cancel Membership.
    """
    
    recurringPaymentRequest.tokenNotificationURL = URL(string: "https://www.example.com/tokenNotificationURL")!
    
    paymentRequest.recurringPaymentRequest = recurringPaymentRequest
    let total = PKRecurringPaymentSummaryItem(label: "Book Club", amount: 10)
    total.endDate = trialEndDate
    
    paymentRequest.paymentSummaryItems = [trialBilling, regularBilling, total]
    
    // Automatic reload payments
    
    // Specify the reload amount and threshold
    let automaticReloadBilling = PKAutomaticReloadPaymentSummaryItem(
        label: "Coffee Shop Reload",
        amount: 25
    )
    reloadItem.thresholdAmount = 5
    
    // Create an automatic reload payment request
    let automaticReloadPaymentRequest = PKAutomaticReloadPaymentRequest(
        paymentDescription: "Coffee Shop",
        regularBilling: regularBilling,
        managementURL: URL(string: "https://www.example.com/managementURL")
    )
    
    automaticReloadPaymentRequest.billingAgreement = """
    Coffee Shop will and $25.00 to your card immediately, and will automatically reload your \ card with $25.00 whenever the balance falls below $5.00. You may cancel at any time to avoid \ future charges. To cancel, go to your Account and click Cancel Reload.
    """
    automaticReloadPaymentRequest.tokenNotificationURL = URL(string: "https://www.example.com/tokenNotificationURL")!
    
    paymentRequest.automaticReloadPaymentRequest = automaticReloadPaymentRequest
    let total = PKAutomaticReloadPaymentSummaryItem(label: "Coffee Shop", amount: 25)
    total.thresholdAmount = 5
    
    paymentRequest.paymentSummaryItems = [total]
    
    
    // Returning a payment authorization result
    func onAuthorizationChange(phase: PayWithApplePayButtonPaymentAuthorizationPhase) {
        switch phase {
        case .didAuthorize(let payment, let resultHandler):
            server.createOrder(with: payment) { serverResult in
                guard case .success(let orderDetails) = serverResult else {
                    /* handle error */
                }
                let result = PKPaymentAuthorizationResult(status: .success, errors: nil)
                result.orderDetails = PKPaymentOrderDetails(
                    orderTypeIdentifier: orderDetails.orderTypeIdentifier,
                    orderIdentifier: orderDetails.orderIdentifier,
                    webServiceURL: orderDetails.webServiceURL,
                    authenticationToken: orderDetails.authenticationToken
                )
                resultHandler(result)
            }
        }
    }
    
    // Completing a payment with order details on the web
//    paymentRequest.show().then((response) => {
//        server.createOrder(response).then((orderDetails) => {
//            let details = {};
//            if (response.methodName === "https://apple.com/apple-pay") {
//                details.data = {
//                    "orderDetails": {
//                        "orderTypeIdentifier": orderDetails.orderTypeIdentifier,
//                        "orderIdentifier": orderDetails.orderIdentifier,
//                        "webServiceURL": orderDetails.webServiceURL,
//                        "authenticationToken": orderDetails.authenticationToken
//                    }
//                };
//            }
//            response.complete("success", datails);
//        });
//    });
    
    // SwiftUI VerifyIdentityWithWalletButton
    
    @ViewBuilder var verifyIdentityButton: some View {
        verifyIdentityWithWalletButton(
            .verifyIdentity,
            request: createRequest()
        ) { result in
            switch result {
            case .success(let document):
                // send document to server for decryption and verification
            case .failure(let error):
                switch error {
                case PKIdentityError.cancelled:
                    // handle cancellation
                default:
                    // handle other errors
                }
            }
        } fallback: {
            // verify identity another way
        }
    }
    
    // Create a PKIdentityRequest
    
    func createRequest() -> PKIdentityRequest {
        let descriptor = PKIdentityDriversLicenseDescriptor()
        descriptor.addElements([.age(atLeast: 18)],
                               intentToStore: .willNotStore)
        descriptor.addElements([.givenName, .familyName, .portrait],
                               intentToStore: .mayStore(days: 30))
        
        let request = PKIdentityRequest()
        request.descriptor = descriptor
        request.merchantIdentifier = // configured in Developer account
        request.nonce = // bound to user session
        return request
    }
    
    // Swift API
    
    let authorizationController = PKIdentityAuthorizationController()
    let canRequest = await self.authorizationController.canRequestDocument(descriptor)
    if canRequest {
        let button = PKIdentityButton(label: .verifyIdentity, style: .black)
        // ...
    } else {
        // verify identity another way
    }
    
    // ...
    
    do {
        let document = try await self.authorizationController.requestDocument(request)
        // send document to server for decryption and verification
    } catch {
        // handle errors
    }
}
