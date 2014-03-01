//
//  LoginViewController.h
//  HiBeacons
//
//  Created by Shi Lin on 14-3-1.
//  Copyright (c) 2014年 Nick Toumpelis. All rights reserved.
//

#import <UIKit/UIKit.h>
@import CoreLocation;
@import CoreBluetooth;

@interface LoginViewController : UIViewController<WBHttpRequestDelegate,CLLocationManagerDelegate, CBPeripheralManagerDelegate>

@property (nonatomic) IBOutlet UIButton *loginBtn;
@property (nonatomic) IBOutlet UIButton *logoutBtn;

@property (nonatomic) IBOutlet UIImageView *faceImgView;
@property (nonatomic) IBOutlet UIImageView *faceImgView1;
@property (nonatomic) IBOutlet UIImageView *faceImgView2;
@property (nonatomic) IBOutlet UIImageView *faceImgView3;
@property (nonatomic) IBOutlet UIImageView *faceImgView4;

@property (strong, nonatomic) NSMutableData *receiveData;

-(IBAction)onLogin:(id)sender;
-(IBAction)onLogout:(id)sender;
-(IBAction)onHideMe:(id)sender;

@end
