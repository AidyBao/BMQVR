//
//  ViewController.m
//  BMQVR
//
//  Created by bao_aidy on 16/9/22.
//  Copyright © 2016年 bao_aidy. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

//View大小-不包括状态栏
#define APP_FRAME_WIDTH [[UIScreen mainScreen] applicationFrame].size.width
#define APP_FRAME_HEIGHT [[UIScreen mainScreen] applicationFrame].size.height

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,CLLocationManagerDelegate>

@property (nonatomic,strong)AVCaptureDevice *device;

@property (nonatomic,strong)AVCaptureSession *session;

@property (nonatomic ,strong)CLLocationManager *locationManager;

@property (nonatomic,strong)CMMotionManager *motionManager;

@property (nonatomic,assign)CGFloat centerY;

@property (nonatomic,assign)CGFloat angle;

@property (nonatomic,strong)CALayer *myLayer;

@property (nonatomic,strong)UIImageView *imagev;

@property (strong,nonatomic)AVCaptureVideoPreviewLayer * preview;
@property (nonatomic,strong)AVCaptureDeviceInput *input;

@property (nonatomic,strong)AVCaptureMetadataOutput *output;

@end

@implementation ViewController

- (UIImageView *)imagev {
    if (_imagev == nil) {
        _imagev = [[UIImageView alloc]init];
        _imagev.image = [UIImage imageNamed:@"qu300"];
        //        _imagev.layer.contents = (id ) [UIImage imageNamed:@"qu300"].CGImage;
    }
    return _imagev;
}

static CGFloat centerx ;
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //定义随机数[90 - 270]
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    //监听磁场
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = self;
    [self.locationManager requestWhenInUseAuthorization];
    //开始更新经纬度
    //    [self.locationManager startUpdatingLocation];
    //开始更新陀螺仪 磁场方向
    [self.locationManager startUpdatingHeading];
    
    [self deviceMotion];
    
    [self setupCarma];
}


- (void)setupCarma{
    // Device
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Input
    _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    
    // Output
    _output = [[AVCaptureMetadataOutput alloc]init];
    
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // Session
    _session = [[AVCaptureSession alloc]init];
    
    [_session setSessionPreset:AVCaptureSessionPresetMedium];
    
    if ([_session canAddInput:self.input])
    {
        [_session addInput:self.input];
    }
    
    if ([_session canAddOutput:self.output])
    {
        [_session addOutput:self.output];
    }
    // 条码类型 AVMetadataObjectTypeQRCode
    _output.metadataObjectTypes =@[AVMetadataObjectTypeQRCode];
    
    // Preview
    _preview =[AVCaptureVideoPreviewLayer layerWithSession:_session];
    _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _preview.frame =CGRectMake(0,0,APP_FRAME_WIDTH,APP_FRAME_HEIGHT);
    
    //    CATransform3D transform = CATransform3DIdentity;
    //    //
    //    transform.m34 = 0;
    //
    //    _preview.transform = transform;
    
    //    [self.view.layer insertSublayer:self.preview below:self.imagev.layer];
    // Start
    [_session startRunning];
    
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(100, 100, 120, 120)];
    view.backgroundColor = [UIColor clearColor];
    
    
    
    self.imagev.frame = CGRectMake(0, 0, 120, 120);
    //
    //    self.imagev.hidden = YES;
    
    self.myLayer = self.imagev.layer;
    
    //    [_preview addSublayer:self.myLayer];
    //    self.imagev.layer.transform = transform;
    
    self.imagev.userInteractionEnabled = YES;
    
    //    self.imagev.layer.transform = transform;
    
    centerx = self.imagev.center.x;
    
    [view addSubview:self.imagev];
    
    //    [self.view.layer insertSublayer:self.imagev.layer above:_preview];
    //    [self.preview insertSublayer:self.imagev.layer atIndex:0];
    
    [self.view.layer insertSublayer:self.preview atIndex:0];
    //    [self.preview insertSublayer:self.imagev.layer atIndex:1];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(changeViewControl:)];
    
    [view addGestureRecognizer:tap];
    
    [self.view addSubview:view];
    
    
    [self startAnimation];
    
    
}

-(void)addImageView{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(100, 100, 120, 120)];
    view.backgroundColor = [UIColor clearColor];
    
    
    
    self.imagev.frame = CGRectMake(0, 0, 120, 120);
    //
    //    self.imagev.hidden = YES;
    
    self.myLayer = self.imagev.layer;
    
    //    [_preview addSublayer:self.myLayer];
    //    self.imagev.layer.transform = transform;
    
    self.imagev.userInteractionEnabled = YES;
    
    //    self.imagev.layer.transform = transform;
    
    centerx = self.imagev.center.x;
    
    [view addSubview:self.imagev];
    
    [self.view.layer insertSublayer:self.preview atIndex:0];
    
    [self.view addSubview:view];


}

- (void)deviceMotion{
    
    __block  double rollchangeIndex = 0.0;
    
    __weak typeof(self) weakself = self;
    
    self.motionManager = [[CMMotionManager alloc]init];
    
    __block  CGFloat centerY = self.imagev.center.y;
    
    // 是否可用
    if ([self.motionManager isDeviceMotionAvailable]) {
        //开始更新
        [self.motionManager setDeviceMotionUpdateInterval:1.0/30.0];
        
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
            
            //            //获得重力值在各个方向上的分量
            double gravityX = motion.gravity.x;
            double gravityY = motion.gravity.y;
            double gravityZ = motion.gravity.z;
            
            //            //与水平面的夹角
            double zTheta = -atan2(gravityZ, sqrtf(gravityX *gravityX + gravityY *gravityY))/M_PI *180;
            
            //            double xyTheta = atan2(gravityX, gravityY)/M_PI *180.0;
            
            if (zTheta > -30.0 && zTheta <= 60.0) {
                
                self.centerY = zTheta;
            }
            
            // 如何算每次角度的增量
            //获得空间位置的欧拉角
            double roll = motion.attitude.roll;//Y轴方向 增加设备往右滚动 减少则往左。
            double pitch = motion.attitude.pitch; // X轴，增加则正面倾斜抬起，减少则后仰
            double yaw = motion.attitude.yaw; // Z轴，逆时针增加
            
            //            if (centerY> 350) {
            //                centerY = MIN(centerY, 350);
            //            }
            //            if (centerY<-100) {
            //                centerY = MAX(centerY, -100);
            //            }
            
            //四元素
            double w = motion.attitude.quaternion.w;
            double wx = motion.attitude.quaternion.x;
            double wy = motion.attitude .quaternion.y;
            double wz = motion.attitude.quaternion.z;
            
            // 矩阵
            CMRotationMatrix rotationMartrix =  motion.attitude.rotationMatrix;
            
            CGFloat h = atan2(rotationMartrix.m13, rotationMartrix.m33); //相当于roll
            CGFloat b = atan2(rotationMartrix.m21, rotationMartrix.m22);//相当于yaw
            CGFloat sp = -rotationMartrix.m23;
            if (sp<=-1.0f) {
                
                //旋转-90度。后仰
            }
            else if(sp >= 1.0f)
            {
                //上仰90度
            }
            else{
                CGFloat p = asin(sp);
            }
            //检查万向锁情况，并计算 heading bank；
            if (sp> 0.9999f) {
                b = 0.0f;
                h = atan2f(-rotationMartrix.m31, rotationMartrix.m11);
            }else{
                h = atan2(rotationMartrix.m13, rotationMartrix.m33);
                b = atan2(rotationMartrix.m21, rotationMartrix.m22);
                
            }
            
            
            //            [motion.attitude multiplyByInverseOfAttitude: self.manager.deviceMotion.attitude];
            //            NSLog(@"%f %f %f %f",w,wx,wy,wz);
            //            NSLog(@"围绕Z轴%f  Y轴的旋转%f ,X轴的旋转 %f",yaw/M_PI *180,roll/M_PI *180,pitch/M_PI *180);
            
            //            weakself.imagev.center = CGPointMake(95- ceil(roll*200), 160 -ceil(pitch*100)/2 );
            
            //            weakself.imagev.transform = CGAffineTransformMakeTranslation(ceil(roll*100), -ceil(pitch*100)/2);
            
            //            NSLog(@"%f  %f", ceil(roll*100)/100  ,ceil(pitch*100)/2);
            
            //磁力感应
            double fiex  = motion.magneticField.field.x;
            double fiey = motion.magneticField.field.y;
            double fiez =motion.magneticField.field.z;
            
            //角速度
            CGFloat rotation = motion.rotationRate.y;
            CGFloat rotatiox = motion.rotationRate.x;
            
            if (fabs(rotation) >= 0.1f) {
                
                CGFloat centerX = weakself.imagev.center.x + rotation *35;
                CGFloat centerY = weakself.imagev.center.y - rotatiox*30;
                //
                //            [UIView animateWithDuration:0.3f
                //                                  delay:0.0f
                //                                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut
                //                             animations:^{
                //                                 weakself.imagev.center = CGPointMake(centerX, centerY);
                //                             }
                //                             completion:nil];
            }
            
        }];
        
    }
}

#pragma mark AVCaptureMetadataOutputObjectsDelegate 使用协议
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    NSString *stringValue;
    
    if ([metadataObjects count] >0)
    {
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex:0];
        stringValue = metadataObject.stringValue;
        
        NSLog(@"metadataObjects = %@",metadataObjects);
    }
    //停止扫描
    [_session stopRunning];
    // 跳转回去！ 并停止timer
    //    [self dismissViewControllerAnimated:YES completion:^
    //     {
    //         [timer invalidate];
    //         //打印的扫描的信息
    //         NSLog(@"stringValue= %@",stringValue);
    //         [[UIApplication sharedApplication]openURL:[NSURL URLWithString:stringValue]];
    //     }];
}


#pragma mark -

- (void)locationManager:(CLLocationManager *)manager
       didUpdateHeading:(CLHeading *)newHeading{
    
    double X = newHeading.x;
    double Y = newHeading.y;
    
    CGFloat engle = (APP_FRAME_WIDTH - self.imagev.frame.size.width)/100 ;
    CGFloat engleH =  (APP_FRAME_HEIGHT - self.imagev.frame.size.height)/60;
    
    if (newHeading.magneticHeading < 359.0 && newHeading.magneticHeading > 180.0) {
        
        self.imagev.hidden = NO;
        
        [UIView animateWithDuration:0.3f
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.imagev.center = CGPointMake(centerx - (newHeading.magneticHeading - 270.0)*engle,180 - self.centerY * engleH);
                         }
                         completion:nil];
        
    }else {
        self.imagev.hidden = YES;
    }
}

//绕Y轴旋转方法2
- (void)startAnimation{
    
    //       self.angle = 10;
    
    CATransform3D rotation = CATransform3DMakeRotation(self.angle *(M_PI/180.0), 0, 1.0, 0);
    
    //    rotation.m34 = -1.0/500;
    
    [UIView animateWithDuration:0.03 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        
        self.imagev.layer.transform = rotation;
        
        //        self.preview.sublayerTransform = rotation;
        
    } completion:^(BOOL finished) {
        
        self.angle+= 10;
        
        [self startAnimation];
    }];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)dealloc {
    NSLog(@"dealloc");
    [self.session stopRunning];
}


@end
