//
//  ViewController.m
//  ApplePayTest
//
//  Created by 崔林豪 on 2018/8/28.
//  Copyright © 2018年 崔林豪. All rights reserved.
//

#import "ViewController.h"

#import <PassKit/PassKit.h>//用户绑定的银行卡信息
#import <PassKit/PKPaymentAuthorizationViewController.h>//Apple pay的展示控件
#import <AddressBook/AddressBook.h>//用户联系信息相关

@interface ViewController ()<PKPaymentAuthorizationViewControllerDelegate>
{
    NSMutableArray *summaryItems;
    NSMutableArray *shippingMethods;
}

@end

@implementation ViewController

#pragma mark -  生命周期 Life Circle
- (void)viewDidLoad {
    [super viewDidLoad];
   
}


- (IBAction)btnClick:(UIButton *)sender {

    
    if (@available(iOS 9.2, *)) {
        
        //检查用户是否可进行某种卡的支付，是否支持Amex、MasterCard、Visa与银联四种卡，根据自己项目的需要进行检测
        NSArray *supportedNetworks = @[PKPaymentNetworkAmex, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa, PKPaymentNetworkChinaUnionPay];

        if (![PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:supportedNetworks]) {
            NSLog(@"没有绑定支付卡");
            return;
        }
        NSLog(@"可以支付， 开始创建支付请求");

        //订单请求对象
        PKPaymentRequest *payRequest = [[PKPaymentRequest alloc] init];
        //设置币种， 国家码以及merchant标识符等基本信息 国家代码
        payRequest.countryCode = @"CN";
        //币种
        payRequest.currencyCode = @"CNY";
        //申请的ID
        payRequest.merchantIdentifier = @"merchant.com.mob.AppPayTest";
        //用户可进行支付的银行卡
        payRequest.supportedNetworks = supportedNetworks;

        //设置支付的交易处理协议，3DS必须支持，EMV为可选
        payRequest.merchantCapabilities = PKMerchantCapability3DS|PKMerchantCapabilityEMV;
        //送货地址信息，这里设置需要地址和联系方式和姓名，如果需要进行设置，默认PKAddressFieldNone(没有送货地址)
        payRequest.requiredShippingAddressFields = PKAddressFieldPostalAddress|PKAddressFieldPhone|PKAddressFieldName;

        //设置两种配送方式
        PKShippingMethod *freeShipping = [PKShippingMethod summaryItemWithLabel:@"包邮" amount:[NSDecimalNumber zero]];
        freeShipping.identifier = @"freeshipping";
        freeShipping.detail = @"6-8 天送达";

        PKShippingMethod *expressShipping = [PKShippingMethod summaryItemWithLabel:@"包邮" amount:[NSDecimalNumber decimalNumberWithString:@"10.00"]];
        expressShipping.identifier = @"freeshipping";
        expressShipping.detail = @"6-8 天送达";
        shippingMethods = [NSMutableArray arrayWithArray:@[freeShipping, expressShipping]];

        //shippingMethods为配送方式列表，类型是 NSMutableArray，这里设置成成员变量，在后续的代理回调中可以进行配送方式的调整。
        payRequest.shippingMethods = shippingMethods;

        NSDecimalNumber *subtotalAmount = [NSDecimalNumber decimalNumberWithMantissa:1275 exponent:-2 isNegative:NO];   //12.75
        PKPaymentSummaryItem *subtotal = [PKPaymentSummaryItem summaryItemWithLabel:@"商品价格" amount:subtotalAmount];

        NSDecimalNumber *discountAmount = [NSDecimalNumber decimalNumberWithString:@"-12.74"];      //-12.74
        PKPaymentSummaryItem *discount = [PKPaymentSummaryItem summaryItemWithLabel:@"优惠折扣" amount:discountAmount];

        NSDecimalNumber *methodsAmount = [NSDecimalNumber zero];
        PKPaymentSummaryItem *methods = [PKPaymentSummaryItem summaryItemWithLabel:@"包邮" amount:methodsAmount];

        NSDecimalNumber *totalAmount = [NSDecimalNumber zero];
        totalAmount = [totalAmount decimalNumberByAdding:subtotalAmount];
        totalAmount = [totalAmount decimalNumberByAdding:discountAmount];
        totalAmount = [totalAmount decimalNumberByAdding:methodsAmount];
        PKPaymentSummaryItem *total = [PKPaymentSummaryItem summaryItemWithLabel:@"天下林子" amount:totalAmount];

        summaryItems = [NSMutableArray arrayWithArray:@[subtotal, discount, methods, total]];
        //summaryItems为账单列表，类型是 NSMutableArray，这里设置成成员变量，在后续的代理回调中可以进行支付金额的调整。
        payRequest.paymentSummaryItems = summaryItems;
        
        
        

        // 苹果支付请求控制器
        PKPaymentAuthorizationViewController *view = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:payRequest];
        view.delegate = self;

        [self presentViewController:view animated:YES completion:nil];

    }
    
}

#pragma mark - PKPaymentAuthorizationViewControllerDelegate
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                  didSelectShippingContact:(PKContact *)contact
                                completion:(void (^)(PKPaymentAuthorizationStatus status, NSArray<PKShippingMethod *> *shippingMethods,
                                                     NSArray<PKPaymentSummaryItem *> *summaryItems))completion
{
    //contact送货地址信息，PKContact类型
    //联系人姓名
    //NSPersonNameComponents *name = contact.name;
    //联系人地址
    //CNPostalAddress *postalAddress = contact.postalAddress;
    //联系人邮箱
    //NSString *emailAddress = contact.emailAddress;
    //联系人手机
    //CNPhoneNumber *phoneNumber = contact.phoneNumber;
    //补充信息,iOS9.2及以上才有
    //NSString *supplementarySubLocality = contact.supplementarySubLocality;
    
    //送货信息选择回调，如果需要根据送货地址调整送货方式，比如普通地区包邮+极速配送，偏远地区只有付费普通配送，进行支付金额重新计算，可以实现该代理，返回给系统：shippingMethods配送方式，summaryItems账单列表，如果不支持该送货信息返回想要的PKPaymentAuthorizationStatus
    completion(PKPaymentAuthorizationStatusSuccess, shippingMethods, summaryItems);
    
}


- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                   didSelectShippingMethod:(PKShippingMethod *)shippingMethod
                                completion:(void (^)(PKPaymentAuthorizationStatus status, NSArray<PKPaymentSummaryItem *> *summaryItems))completion
{
    //配送方式回调，如果需要根据不同的送货方式进行支付金额的调整，比如包邮和付费加速配送，可以实现该代理
    PKShippingMethod *oldShippingMethod = [summaryItems objectAtIndex:2];
    PKPaymentSummaryItem *total = [summaryItems lastObject];
    total.amount = [total.amount decimalNumberBySubtracting:oldShippingMethod.amount];
    total.amount = [total.amount decimalNumberByAdding:shippingMethod.amount];
    
    [summaryItems replaceObjectAtIndex:2 withObject:shippingMethod];
    [summaryItems replaceObjectAtIndex:3 withObject:total];
    
    completion(PKPaymentAuthorizationStatusSuccess, summaryItems);
}


- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectPaymentMethod:(PKPaymentMethod *)paymentMethod completion:(void (^)(NSArray<PKPaymentSummaryItem *> * _Nonnull))completion{
    //支付银行卡回调，如果需要根据不同的银行调整付费金额，可以实现该代理
    completion(summaryItems);
}


- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus status))completion {
    
    //PKPaymentToken *payToken = payment.token;
    //支付凭据，发给服务端进行验证支付是否真实有效
    //PKContact *billingContact = payment.billingContact;     //账单信息
    //PKContact *shippingContact = payment.shippingContact;   //送货信息
    //PKContact *shippingMethod = payment.shippingMethod;     //送货方式
    //等待服务器返回结果后再进行系统block调用
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //模拟服务器通信
        completion(PKPaymentAuthorizationStatusSuccess);
    });
}


- (void) paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
