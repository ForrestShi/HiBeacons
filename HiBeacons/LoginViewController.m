//
//  LoginViewController.m
//  HiBeacons
//
//  Created by Shi Lin on 14-3-1.
//  Copyright (c) 2014年 Nick Toumpelis. All rights reserved.
//

#import "LoginViewController.h"
#import "NTHiBeaconsDelegate.h"

#import <QuartzCore/QuartzCore.h>

static NSString * const kUUID = @"00000000-0000-0000-0000-000000000000";
static NSString * const kIdentifier = @"OUYU";

static NSString * const kOperationCellIdentifier = @"OperationCell";
static NSString * const kBeaconCellIdentifier = @"BeaconCell";

static NSString * const kAdvertisingOperationTitle = @"隐身";
static NSString * const kRangingOperationTitle = @""; //@"Ranging";
static NSUInteger const kNumberOfSections = 2;
static NSUInteger const kNumberOfAvailableOperations = 2;
static CGFloat const kOperationCellHeight = 44;
static CGFloat const kBeaconCellHeight = 52;
static NSString * const kBeaconSectionTitle = @"看看周围有谁哦 ...";
static CGPoint const kActivityIndicatorPosition = (CGPoint){205, 12};
static NSString * const kBeaconsHeaderViewIdentifier = @"BeaconsHeader";

typedef NS_ENUM(NSUInteger, NTSectionType) {
    NTOperationsSection,
    NTDetectedBeaconsSection
};

typedef NS_ENUM(NSUInteger, NTOperationsRow) {
    NTAdvertisingRow,
    NTRangingRow
};



@interface LoginViewController ()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) NSArray *detectedBeacons;


@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(afterLogin:) name:@"AfterLogin" object:nil];

    self.faceImgView.layer.masksToBounds = YES;
    self.faceImgView.layer.cornerRadius = 40.;
    self.faceImgView.layer.borderColor = [UIColor redColor].CGColor;
    self.faceImgView.layer.borderWidth = 2.;

    
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)afterLogin:(NSNotification*)nft{
    
    NSString *userid = [[nft userInfo] objectForKey:@"userid"];
    NSString *token = [[nft userInfo] objectForKey:@"token"];
    
    NSLog(@"userid %@", userid);
    
    [self getUserInfo:userid andToken:token];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        __weak LoginViewController* weakSelf = self;
//        self.faceImgView.hidden = NO;
//        self.faceImgView.alpha = 0;
        
        [UIView animateWithDuration:.5 animations:^{
            weakSelf.loginBtn.alpha = 0;
           // weakSelf.faceImgView.alpha = 1.;
        } completion:^(BOOL finished) {
            
        }];
    });

    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)onLogin:(id)sender{
    
    WBAuthorizeRequest *request = [WBAuthorizeRequest request];
    request.redirectURI = kRedirectURI;
    request.scope = @"all";
    request.userInfo = @{@"SSO_From": @"LoginViewController",
                         @"Other_Info_1": [NSNumber numberWithInt:123],
                         @"Other_Info_2": @[@"obj1", @"obj2"],
                         @"Other_Info_3": @{@"key1": @"obj1", @"key2": @"obj2"}};
    [WeiboSDK sendRequest:request];

}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UITextField *textField=[alertView textFieldAtIndex:0];
    
    NTHiBeaconsDelegate *myDelegate =(NTHiBeaconsDelegate*)[[UIApplication sharedApplication] delegate];
    NSString *jsonData = @"{\"text\": \"新浪新闻是新浪网官方出品的新闻客户端，用户可以第一时间获取新浪网提供的高品质的全球资讯新闻，随时随地享受专业的资讯服务，加入一起吧\",\"url\": \"http://app.sina.com.cn/appdetail.php?appID=84475\",\"invite_logo\":\"http://sinastorage.com/appimage/iconapk/1b/75/76a9bb371f7848d2a7270b1c6fcf751b.png\"}";
    
    [WeiboSDK inviteFriend:jsonData withUid:[textField text] withToken:myDelegate.wbtoken delegate:self withTag:@"invite1"];
}

- (void)request:(WBHttpRequest *)request didReceiveResponse:(NSURLResponse *)response{
    NSLog(@"%s",__PRETTY_FUNCTION__);
}

- (void)request:(WBHttpRequest *)request didFinishLoadingWithResult:(NSString *)result
{
    NSString *title = nil;
    UIAlertView *alert = nil;
    
    title = @"收到网络回调";
    alert = [[UIAlertView alloc] initWithTitle:title
                                       message:[NSString stringWithFormat:@"%@",result]
                                      delegate:nil
                             cancelButtonTitle:@"确定"
                             otherButtonTitles:nil];
    [alert show];
}

- (void)request:(WBHttpRequest *)request didFailWithError:(NSError *)error;
{
    NSString *title = nil;
    UIAlertView *alert = nil;
    
    title = @"请求异常";
    alert = [[UIAlertView alloc] initWithTitle:title
                                       message:[NSString stringWithFormat:@"%@",error]
                                      delegate:nil
                             cancelButtonTitle:@"确定"
                             otherButtonTitles:nil];
    [alert show];
}


- (void) getUserInfo:(NSString*)userId andToken:(NSString*)token{
    NSString * userid = userId;
    NSString* wbtoken = token;
    
    NSString * oathString = [NSString stringWithFormat:@"https://api.weibo.com/2/users/show.json?uid=%@&access_token=%@",userid,wbtoken];//
    
    NSString * currentString = (WeiboSDK.isWeiboAppInstalled?oathString:oathString) ;
    
    //第一步，创建url
    NSURL *url = [NSURL URLWithString:currentString];
    //第二步，创建请求
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    //第三步，连接服务器
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
}

- (void) showUserInfo:(NSString *) message
{
    NSString *title = @"User Info";
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"确定"
                                          otherButtonTitles:nil];
    
    [alert show];
    
}


//接收到服务器回应的时候调用此方法
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
    NSLog(@"%@",[res allHeaderFields]);
    self.receiveData = [NSMutableData data];
    
}
//接收到服务器传输数据的时候调用，此方法根据数据大小执行若干次
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.receiveData appendData:data];
}
//数据传完之后调用此方法
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *receiveStr = [[NSString alloc]initWithData:self.receiveData encoding:NSUTF8StringEncoding];
    //NSLog(@"%@",receiveStr);
    
    id json = [NSJSONSerialization JSONObjectWithData:self.receiveData options:NSJSONReadingMutableContainers error:nil];
    //NSLog(@"json %@", [json);
    if ([json isKindOfClass:[NSDictionary class]]) {
        NSString *remoteProfileUrl = [json objectForKey:@"profile_image_url"];
        self.faceImgView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:remoteProfileUrl]]];
        self.faceImgView.hidden = NO;
        self.faceImgView.alpha = 0;
        
        [UIView animateWithDuration:.5 animations:^{
            self.faceImgView.alpha = 1.;
        }];
    }
    
    
}
//网络请求过程中，出现任何错误（断网，连接超时等）会进入此方法
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"%@",[error localizedDescription]);
}
@end
