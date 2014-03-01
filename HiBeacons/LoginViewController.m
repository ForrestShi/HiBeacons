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

union Transfer {
    uint32_t whole;
    struct Parts {
        uint16_t part1;
        uint16_t part2;
    } parts;
};


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

- (void)polishFaceImage:(UIImageView*)imgView{
    imgView.layer.masksToBounds = YES;
    imgView.layer.cornerRadius = 40.;
    imgView.layer.borderColor = [UIColor redColor].CGColor;
    imgView.layer.borderWidth = 2.;

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(afterLogin:) name:@"AfterLogin" object:nil];

    [self polishFaceImage:self.faceImgView];
    [self polishFaceImage:self.faceImgView1];
        [self polishFaceImage:self.faceImgView2];
        [self polishFaceImage:self.faceImgView3];
        [self polishFaceImage:self.faceImgView4];
    
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
            
            [weakSelf startRangingForBeacons];
            [weakSelf startAdvertisingBeacon];
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
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:currentString parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSLog(@"JSON: %@", responseObject);
            NSString* remoteUrl = [responseObject objectForKey:@"avatar_hd"];
            self.faceImgView.hidden = NO;
            
            [self.faceImgView setImageWithURL:[NSURL URLWithString:remoteUrl] placeholderImage:[UIImage imageNamed:@"me2013_s.png"]];
            [UIView animateWithDuration:.5 animations:^{
                self.faceImgView.alpha = 1.;
            }];
        });
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        [self.faceImgView setImage:[UIImage imageNamed:@"me2013_s.png"]];
    }];
    
}


- (void) getUserInfo:(NSString*)userId andToken:(NSString*)token forImageView:(UIImageView*)imgView{
    NSString * userid = userId;
    NSString* wbtoken = token;
    
    NSString * oathString = [NSString stringWithFormat:@"https://api.weibo.com/2/users/show.json?uid=%@&access_token=%@",userid,wbtoken];//
    
    NSString * currentString = (WeiboSDK.isWeiboAppInstalled?oathString:oathString) ;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:currentString parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{

            NSLog(@"JSON: %@", responseObject);
            NSString* remoteUrl = [responseObject objectForKey:@"avatar_hd"];
            imgView.hidden = NO;
            
            [imgView setImageWithURL:[NSURL URLWithString:remoteUrl] placeholderImage:[UIImage imageNamed:@"me2013_s.png"]];
            [UIView animateWithDuration:.5 animations:^{
                imgView.alpha = 1.;
            }];
        });

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        [imgView setImage:[UIImage imageNamed:@"me2013_s.png"]];
    }];
    
}

//- (void) showUserInfo:(NSString *) message
//{
//    NSString *title = @"User Info";
//    
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
//                                                    message:message
//                                                   delegate:nil
//                                          cancelButtonTitle:@"确定"
//                                          otherButtonTitles:nil];
//    
//    [alert show];
//    
//}

//
////接收到服务器回应的时候调用此方法
//- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
//{
//    NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
//    NSLog(@"%@",[res allHeaderFields]);
//    self.receiveData = [NSMutableData data];
//    
//}
////接收到服务器传输数据的时候调用，此方法根据数据大小执行若干次
//-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
//{
//    [self.receiveData appendData:data];
//}
////数据传完之后调用此方法
//-(void)connectionDidFinishLoading:(NSURLConnection *)connection
//{
//    NSString *receiveStr = [[NSString alloc]initWithData:self.receiveData encoding:NSUTF8StringEncoding];
//    //NSLog(@"%@",receiveStr);
//    
//    id json = [NSJSONSerialization JSONObjectWithData:self.receiveData options:NSJSONReadingMutableContainers error:nil];
//    //NSLog(@"json %@", [json);
//    if ([json isKindOfClass:[NSDictionary class]]) {
//        NSString *remoteProfileUrl = [json objectForKey:@"profile_image_url"];
//        self.faceImgView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:remoteProfileUrl]]];
//        self.faceImgView.hidden = NO;
//        self.faceImgView.alpha = 0;
//        
//        [UIView animateWithDuration:.5 animations:^{
//            self.faceImgView.alpha = 1.;
//        }];
//    }
//    
//    
//}
////网络请求过程中，出现任何错误（断网，连接超时等）会进入此方法
//-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
//{
//    NSLog(@"%@",[error localizedDescription]);
//}
//

#pragma mark - Beacon ranging
- (void)createBeaconRegion
{
    if (self.beaconRegion)
        return;
    
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:kUUID];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:[NSString stringWithFormat:@"%@",kIdentifier]];
}

- (void)turnOnRanging
{
    NSLog(@"Turning on ranging...");
    
    if (![CLLocationManager isRangingAvailable]) {
        NSLog(@"Couldn't turn on ranging: Ranging is not available.");
        return;
    }
    
    if (self.locationManager.rangedRegions.count > 0) {
        NSLog(@"Didn't turn on ranging: Ranging already on.");
        return;
    }
    
    [self createBeaconRegion];
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
    
    NSLog(@"Ranging turned on for region: %@.", self.beaconRegion);
}

- (void)startRangingForBeacons
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    self.detectedBeacons = [NSArray array];
    
    [self turnOnRanging];
}

#pragma mark - Beacon advertising
- (void)turnOnAdvertising
{
    if (self.peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"Peripheral manager is off.");
  //      self.advertisingSwitch.on = YES;
        return;
    }
    
    time_t t;
    srand((unsigned) time(&t));
    //1827594675
    //1904178197
    NSUInteger userid = (NSUInteger)[[[NSUserDefaults standardUserDefaults] objectForKey:@"userid"] integerValue];
    union Transfer convert;
    convert.whole = userid;;
    
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:self.beaconRegion.proximityUUID
                                                                     major:convert.parts.part1
                                                                     minor:convert.parts.part2
                                                                identifier:self.beaconRegion.identifier];
    NSDictionary *beaconPeripheralData = [region peripheralDataWithMeasuredPower:nil];
    [self.peripheralManager startAdvertising:beaconPeripheralData];
    
    NSLog(@"Turning on advertising for region: %@.", region);
}


- (void)startAdvertisingBeacon
{
    NSLog(@"Turning on advertising...");
    
    [self createBeaconRegion];
    
    if (!self.peripheralManager)
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
    
    [self turnOnAdvertising];
}


#pragma mark - Beacon ranging delegate methods
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (![CLLocationManager locationServicesEnabled]) {
        NSLog(@"Couldn't turn on ranging: Location services are not enabled.");
        return;
    }
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
        NSLog(@"Couldn't turn on ranging: Location services not authorised.");
        return;
    }
    
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region {
    NSArray *filteredBeacons = [self filteredBeacons:beacons];
    
    if (filteredBeacons.count == 0) {
        NSLog(@"No beacons found nearby.");
    } else {
        NSLog(@"Found %lu %@.", (unsigned long)[filteredBeacons count],
              [filteredBeacons count] > 1 ? @"beacons" : @"beacon");
    }
    
    self.detectedBeacons = filteredBeacons;
    
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"token"];
    if (self.detectedBeacons && self.detectedBeacons.count > 0 && self.detectedBeacons.count < 5) {
        switch (self.detectedBeacons.count) {
            case 1:
            {
                [self getUserInfo:[self userIdFromBeacon:[self.detectedBeacons objectAtIndex:0] ] andToken:token forImageView:self.faceImgView1];
                [UIView animateWithDuration:.5 animations:^{
                    self.faceImgView2.alpha = 0;
                    self.faceImgView3.alpha = 0;
                    self.faceImgView4.alpha = 0;

                }];
                break;
            }
            
            case 2:
            {
                [self getUserInfo:[self userIdFromBeacon:[self.detectedBeacons objectAtIndex:0] ] andToken:token forImageView:self.faceImgView1];
                [self getUserInfo:[self userIdFromBeacon:[self.detectedBeacons objectAtIndex:1] ] andToken:token forImageView:self.faceImgView2];
                [UIView animateWithDuration:.5 animations:^{
                    self.faceImgView3.alpha = 0;
                    self.faceImgView4.alpha = 0;
                    
                }];

                break;
            }
            case 3:
            {
                [self getUserInfo:[self userIdFromBeacon:[self.detectedBeacons objectAtIndex:0] ] andToken:token forImageView:self.faceImgView1];
                [self getUserInfo:[self userIdFromBeacon:[self.detectedBeacons objectAtIndex:1] ] andToken:token forImageView:self.faceImgView2];
                 [self getUserInfo:[self userIdFromBeacon:[self.detectedBeacons objectAtIndex:2] ] andToken:token forImageView:self.faceImgView3];
                [UIView animateWithDuration:.5 animations:^{
                    self.faceImgView4.alpha = 0;
                    
                }];

                break;
            }
            case 4:
            {
                [self getUserInfo:[self userIdFromBeacon:[self.detectedBeacons objectAtIndex:0] ] andToken:token forImageView:self.faceImgView1];
                [self getUserInfo:[self userIdFromBeacon:[self.detectedBeacons objectAtIndex:1] ] andToken:token forImageView:self.faceImgView2];
                [self getUserInfo:[self userIdFromBeacon:[self.detectedBeacons objectAtIndex:2] ] andToken:token forImageView:self.faceImgView3];
                
                [self getUserInfo:[self userIdFromBeacon:[self.detectedBeacons objectAtIndex:3] ] andToken:token forImageView:self.faceImgView4];
                break;
            }
            default:{
                [UIView animateWithDuration:.5 animations:^{
                    self.faceImgView1.alpha = 0;
                    self.faceImgView2.alpha = 0;
                    self.faceImgView3.alpha = 0;
                    self.faceImgView4.alpha = 0;
                    
                }];

                break;
            }
        }
    }

}

- (NSString*)userIdFromBeacon:(CLBeacon*)beacon{
    NSString *userId = nil;
    if (beacon) {
        union Transfer gotValue;
        gotValue.parts.part1 = beacon.major.intValue;
        gotValue.parts.part2 = beacon.minor.intValue;
        userId = [NSString stringWithFormat:@"%d",gotValue.whole];
    }

    return userId;
}

- (NSArray *)filteredBeacons:(NSArray *)beacons
{
    // Filters duplicate beacons out; this may happen temporarily if the originating device changes its Bluetooth id
    NSMutableArray *mutableBeacons = [beacons mutableCopy];
    
    NSMutableSet *lookup = [[NSMutableSet alloc] init];
    for (int index = 0; index < [beacons count]; index++) {
        CLBeacon *curr = [beacons objectAtIndex:index];
        NSString *identifier = [NSString stringWithFormat:@"%@/%@", curr.major, curr.minor];
        
        union Transfer gotValue;
        gotValue.parts.part1 = curr.major.intValue;
        gotValue.parts.part2 = curr.minor.intValue;
        
        NSLog(@"got value %d", gotValue.whole);
        
        // this is very fast constant time lookup in a hash table
        if ([lookup containsObject:identifier]) {
            [mutableBeacons removeObjectAtIndex:index];
        } else {
            [lookup addObject:identifier];
        }
    }
    
    return [mutableBeacons copy];
}

#pragma mark - Beacon advertising delegate methods
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheralManager error:(NSError *)error
{
    if (error) {
        NSLog(@"Couldn't turn on advertising: %@", error);
//        self.advertisingSwitch.on = YES;
        return;
    }
    
    if (peripheralManager.isAdvertising) {
        NSLog(@"Turned on advertising.");
//        self.advertisingSwitch.on = NO;
    }
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheralManager
{
    if (peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"Peripheral manager is off.");
//        self.advertisingSwitch.on = YES;
        return;
    }
    
    NSLog(@"Peripheral manager is on.");
    [self turnOnAdvertising];
}


@end
