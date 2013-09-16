//
//  FairyTailReaderViewController.m
//  Fairy Tail
//
//  Created by Nick Sargsyan on 8/26/13.
//  Copyright (c) 2013 Simply Technologies. All rights reserved.
//

#import "FairyTailReaderViewController.h"
#import "FairyTailInteractiveMovableImageView.h"
#import "FairyTailInteractiveRotatableImageView.h"
#import "FairyTailInteractiveLeafImageView.h"
#import "FairyTailAboutViewController.h"
#import "UIView+UserInfo.h"
#import "Constants.h"
#import "JSON.h"
#import "NSString+SBJSON.h"
#import "AFHTTPClient.h"
#import "UIImageView+AFNetworking.h"

@interface FairyTailReaderViewController ()
{
    NSInteger currentPageNumber;
    NSInteger totalPageNumber;
    
    NSInteger stageNumber;
    
    NSString *languageCode;
    
    BOOL settingsEnabled;
    BOOL languageSettinhsEnabled;
    BOOL volumeSettingsEnabled;
    
    CAKeyframeAnimation *buttonSlideInAnimation;
    
    NSMutableDictionary *languageDictionary;
    NSMutableDictionary *bookDictionary;
    
    CGFloat accellX;
    CGFloat accellZ;
    
    CMMotionManager *motionManager;
    CMAttitude *motionAttitude;
    
    NSTimer *motionTimer;
    
    UIAccelerationValue gravX;
    UIAccelerationValue gravY;
    UIAccelerationValue gravZ;
    UIAccelerationValue prevVelocity;
    UIAccelerationValue prevAcce;
}

@property UIView *bookView;
@property UIView *titleView;
@property UIView *readerView;
@property UIView *upperSettingsView;
@property UIView *innerSettingsView;

@property UISlider *volumeSlider;

@property UIScrollView *titleScrollView;

@end

@implementation FairyTailReaderViewController

@synthesize bookView = bookView;
@synthesize titleView = titleView;
@synthesize readerView = readerView;
@synthesize upperSettingsView = upperSettingsView;
@synthesize innerSettingsView = innerSettingsView;
@synthesize volumeSlider = volumeSlider;
@synthesize titleScrollView = titleScrollView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        languageDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Language" ofType:@"plist"]];
        
        //Inititialize device motion manager to track device rotations and accelerations
        motionManager = [[CMMotionManager alloc] init];
        motionAttitude = nil;
        
        CMDeviceMotion *deviceMotion = motionManager.deviceMotion;
        motionAttitude = [deviceMotion attitude];
        
        motionManager = [[CMMotionManager alloc] init];
        [motionManager setDeviceMotionUpdateInterval:1.0/60.0];
        [motionManager setAccelerometerUpdateInterval:1.0/60.0];
        [motionManager startDeviceMotionUpdates];
        [motionManager startAccelerometerUpdates];
        
        accellX = motionManager.accelerometerData.acceleration.x;
        accellZ = motionManager.accelerometerData.acceleration.y;
        
        gravX = gravY = gravZ = prevVelocity = prevAcce = 0.f;
        
        [motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue]
                                   withHandler:^(CMGyroData *gyroData, NSError *error) {
                                       [self getDeviceGLRotationMatrixWithAcceleration:gyroData.rotationRate];
                                   }
         ];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    if (![[NSUserDefaults standardUserDefaults] boolForKey:isLaunchedBefore])
    {
        //Show Language Choose Dialog if launched first time
        
        [self viewLanguageChooseDialog];
    }
    else
    {
        [self showTitle];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[self navigationController] setNavigationBarHidden:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark - Language Support Methods

- (void)viewLanguageChooseDialog
{
    [[self view] setBackgroundColor:[UIColor colorWithRed:0.5
                                                    green:0.1
                                                    blue:0.4
                                                    alpha:1.0]];
    
    int buttonSize = 1024 / [languageDictionary count] > 128 ? 128 : 1024 / [languageDictionary count];
    int offsetFactor = (1024 - [languageDictionary count] * buttonSize) / 2;
    int id = 0;
    
    for (NSString *code in [languageDictionary allValues])
    {        
        UIButton *languageButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [languageButton setBackgroundColor:[UIColor clearColor]];
        [languageButton setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"icon-%@", code]] forState:UIControlStateNormal];
        [languageButton setFrame:CGRectMake(offsetFactor + id * buttonSize, (id % 2) * (748 + buttonSize) - buttonSize, buttonSize, buttonSize)];
        [languageButton setTag:id + firstLaunchLanguageButtonTag];
        [languageButton addTarget:self action:@selector(languageChoosen:) forControlEvents:UIControlEventTouchUpInside];
        [[self view] addSubview:languageButton];
        
        NSNumber *newOrigin = [NSNumber numberWithInt:374];
        NSNumber *middleOrigin = [NSNumber numberWithInt:newOrigin.intValue + ((id + 1) % 2) * buttonSize * 2 - buttonSize];
        NSNumber *oldOrigin = [NSNumber numberWithInt:(id % 2) * (748 + 2 * buttonSize) - buttonSize];
        
        //Perform button animations
        buttonSlideInAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position.y"];
        [buttonSlideInAnimation setValues:[NSArray arrayWithObjects:oldOrigin,
                                      middleOrigin,
                                      newOrigin,
                                      nil]];
        [buttonSlideInAnimation setKeyTimes:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0f],
                                        [NSNumber numberWithFloat:0.6f],
                                        [NSNumber numberWithFloat:1.0f],
                                        nil]];
        [buttonSlideInAnimation setRemovedOnCompletion:NO];
        [buttonSlideInAnimation setFillMode:kCAFillModeBackwards];
        [buttonSlideInAnimation setDuration:0.4f];
        [buttonSlideInAnimation setDelegate:self];
        [buttonSlideInAnimation setValue:@"buttonSlideInAnimation" forKey:animationType];
        [languageButton.layer addAnimation:buttonSlideInAnimation forKey:nil];
        
        id++;
    }
}

- (void)languageChoosenAs:(NSInteger)code
{
    languageCode = [languageDictionary objectForKey:[NSString stringWithFormat:@"Language-%d", code]];
    
    [[NSUserDefaults standardUserDefaults] setInteger:code forKey:@"language"];
}

- (IBAction)languageChoosen:(id)sender
{
    [self languageChoosenAs:[((UIButton *) sender) tag] - 100];
    
    int buttonSize = 1024 / [languageDictionary count] > 128 ? 128 : 1024 / [languageDictionary count];

    for (int i = 0; i < [languageDictionary count]; i++)
    {
        UIButton *languageButton = (UIButton *)[[self view] viewWithTag:i + firstLaunchLanguageButtonTag];
        
        NSNumber *oldOrigin = [NSNumber numberWithInt:374 - buttonSize / 2];
        NSNumber *middleOrigin = [NSNumber numberWithInt:oldOrigin.intValue + (i % 2) * buttonSize * 2 - buttonSize];
        NSNumber *newOrigin = [NSNumber numberWithInt:((i + 1) % 2) * (748 + 2 * buttonSize) - buttonSize];
        
        //Perform button animations
        CAKeyframeAnimation *keyframeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position.y"];
        [keyframeAnimation setValues:[NSArray arrayWithObjects:oldOrigin,
                                                               middleOrigin,
                                                               newOrigin,
                                                               nil]];
        [keyframeAnimation setKeyTimes:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0f],
                                                                 [NSNumber numberWithFloat:0.6f],
                                                                 [NSNumber numberWithFloat:1.0f],
                                                                 nil]];
        [keyframeAnimation setRemovedOnCompletion:NO];
        [keyframeAnimation setFillMode:kCAFillModeForwards];
        [keyframeAnimation setDuration:0.4f];
        [languageButton.layer addAnimation:keyframeAnimation forKey:nil];
        [languageButton setUserInteractionEnabled:NO];
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:isLaunchedBefore];
    
    [self showTitle];
}

#pragma mark -
#pragma mark - Title Methods

- (void)showTitle
{
    if (!titleView)
    {
        bookDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Book" ofType:@"plist"]];
        
        titleView = [[UIView alloc] initWithFrame:[[self view] frame]];
        [titleView setAlpha:0.0f];
        [titleView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(beginReading:)]];
        
        [self constructBookPageWithNumber:0];
        
        titleScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 548, 1024, 200)];
        [titleScrollView setBackgroundColor:[UIColor colorWithRed:0.5
                                                          green:0.1
                                                          blue:0.4
                                                          alpha:0.7]];
        [titleView addSubview:titleScrollView];
        
        [self loadTitleScrollViewItems];
        
        [[self view] addSubview:titleView];
    }
    
    //Perform titleView/readerView appear/disappear animations
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.4];
        [UIView setAnimationDelay:0.4];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        [titleView setAlpha:1.0f];
        
        if (readerView)
        {
            [readerView setAlpha:0.0f];
        }
        
        [UIView commitAnimations];
    });
}

- (void)loadTitleScrollViewItems
{    
    dispatch_async(dispatch_get_current_queue(), ^{
        
        AFHTTPClient *httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:serverBaseUrl]];
        NSDictionary *params = @{};
        NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:serverStoryDataAddress parameters:params];
        
        AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
                NSDictionary *responseDictionary = nil;
            
                @try {
                    responseDictionary = [NSJSONSerialization JSONObjectWithData:(NSData *)responseObject options:NSJSONReadingAllowFragments error:nil];
                }
                @catch (NSException *exception) {
                    
                }
            
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            }
        ];
        [requestOperation start];
        
    });
}

#pragma mark -
#pragma mark - Reader Methods

- (void)beginReading:(UITapGestureRecognizer *)tapGesture
{
    if (!readerView)
    {
        readerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1024, 748)];
        [readerView setAlpha:0.0f];
        [readerView setUserInteractionEnabled:YES];
        
        UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 1025, 748)];
        [backgroundImageView setImage:[UIImage imageNamed:@"wood.png"]];
        [backgroundImageView setContentMode:UIViewContentModeScaleAspectFill];
        [readerView addSubview:backgroundImageView];
        
        settingsEnabled = NO;
        
        //Construct Settings Menu
        
        [self constructSettings];
        
        //Construct Book
        
        [self constructBook];
        
        [[self view] addSubview:readerView];
    }
    
    //Perform titleView/readerView appear/disappear animations
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.4];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        [titleView setAlpha:0.0f];
        [readerView setAlpha:1.0f];
        [UIView commitAnimations];
    });
    
    [[UIScreen mainScreen] bounds];
}

#pragma mark -
#pragma mark - Book Methods

- (void)constructBook
{
    //Initialize swipe gestures to navigate between pages
    UISwipeGestureRecognizer *rightGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(pageScrolledRight:)];
    [rightGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    [rightGestureRecognizer setNumberOfTouchesRequired:2];
    UISwipeGestureRecognizer *leftGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(pageScrolledLeft:)];
    [leftGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
    [leftGestureRecognizer setNumberOfTouchesRequired:2];
    
    bookView = [[UIView alloc] initWithFrame:CGRectMake(95, 93, 832, 562)];
    [bookView setUserInteractionEnabled:YES];
    [bookView setClipsToBounds:YES];
    [bookView setGestureRecognizers:[[NSArray alloc] initWithObjects:leftGestureRecognizer, rightGestureRecognizer, nil]];
    
    currentPageNumber = 1;
    totalPageNumber = [bookDictionary count];

    //Construct first page
    [self constructBookPageWithNumber:currentPageNumber];
    
    [readerView addSubview:bookView];
}

- (void)constructBookPageWithNumber:(NSInteger)pageNumber
{
    NSMutableDictionary *pageDictionary = [bookDictionary objectForKey:[NSString stringWithFormat:@"Page-%d", pageNumber]];
    
    //Add stages
    NSInteger stageCount = [pageDictionary count] - 1;
    
    for (NSDictionary *stageDictionary in [pageDictionary allValues])
    {
        NSLog(@"%@", [stageDictionary debugDescription]);
        
        UIView *stageView;
        
        if (pageNumber == 0)
        {
            stageView = [[UIView alloc] initWithFrame:titleFrame];
        }
        else
        {
            stageView  = [[UIView alloc] initWithFrame:stageFrame];
        }
        
        [stageView setUserInfo:[NSDictionary dictionaryWithObject:[stageDictionary valueForKey:parallaxCoefficient] forKey:parallaxCoefficient]];
        [stageView setTag:stageCount + parallaxStageTag];
        
        if (pageNumber == 0)
        {
            [titleView addSubview:stageView];
        }
        else
        {
            [bookView addSubview:stageView];
        }
        
        UIImageView *stageImageView = [[UIImageView alloc] initWithFrame:stageView.frame];
        [stageImageView setImage:[UIImage imageNamed:[stageDictionary valueForKey:stageImage]]];
        [stageView addSubview:stageImageView];
        
        //Add rotatationals to stage
        NSMutableDictionary *rotationalsDictionary = [stageDictionary objectForKey:rotationals];
        
        NSInteger rotationalCount = [rotationalsDictionary count] - 1;
        
        [stageView setUserInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:(rotationalCount + 1) ]
                                                           forKey:rotationalNumberInStage]];
        
        for (NSDictionary *rotationalDictionary in [rotationalsDictionary allValues])
        {
            NSLog(@"%@", [rotationalDictionary debugDescription]);
            
            UIImageView *rotationalView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[rotationalDictionary valueForKey:rotationalImage]]];
            
            CGFloat XCoordinate = [[rotationalDictionary valueForKey:rotationalXCoordinate] floatValue];
            CGFloat YCoordinate = [[rotationalDictionary valueForKey:rotationalYCoordinate] floatValue];
            
            [rotationalView setFrame:CGRectOffset(rotationalView.frame, XCoordinate, YCoordinate)];
            
            [rotationalView setTag:rotationalCount + rotationalTag];
            [stageView addSubview:rotationalView];
            
            rotationalCount--;
        }
        
        //Add rotatables to stage
        NSMutableDictionary *rotatablesDictionary = [stageDictionary objectForKey:rotatables];
        
        for (NSDictionary *rotatableDictionary in [rotatablesDictionary allValues])
        {
            NSLog(@"%@", [rotatableDictionary debugDescription]);
            
            FairyTailInteractiveRotatableImageView *rotatableView = [[FairyTailInteractiveRotatableImageView alloc] initWithImage:[UIImage imageNamed:[rotatableDictionary valueForKey:rotatableImage]]];
            
            CGFloat XCoordinate = [[rotatableDictionary valueForKey:rotatableXCoordinate] floatValue];
            CGFloat YCoordinate = [[rotatableDictionary valueForKey:rotatableYCoordinate] floatValue];
            
            [rotatableView setFrame:CGRectOffset(rotatableView.frame, XCoordinate, YCoordinate)];

            [rotatableView setUserInteractionEnabled:YES];
            [bookView addSubview:rotatableView];
        }
        
        //Add clouds to stage
        NSMutableDictionary *cloudsDictionary = [stageDictionary objectForKey:clouds];
        
        for (NSDictionary *cloudDictionary in [cloudsDictionary allValues])
        {
            NSLog(@"%@", [cloudDictionary debugDescription]);
            
            FairyTailInteractiveMovableImageView *cloudView = [[FairyTailInteractiveMovableImageView alloc] initWithImage:[UIImage imageNamed:[cloudDictionary valueForKey:cloudImage]]];
            
            NSNumber *ceilCoordinate = [cloudDictionary valueForKey:cloudCeilCoordinate];
            NSNumber *floorCoordinate = [cloudDictionary valueForKey:cloudFloorCoordinate];
            
            [cloudView setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:ceilCoordinate,
                                                                                seilKey,
                                                                                floorCoordinate,
                                                                                floorKey,
                                                                                nil]];
            
            [cloudView setUserInteractionEnabled:YES];
            [stageView addSubview:cloudView];
        }
        
        //Add leafs to stage
        NSMutableDictionary *leafsDictionary = [stageDictionary objectForKey:leafs];
        
        for (NSDictionary *leafDictionary in [leafsDictionary allValues])
        {
            NSLog(@"%@", [leafDictionary debugDescription]);
            
            FairyTailInteractiveLeafImageView *leafView = [[FairyTailInteractiveLeafImageView alloc] initWithImage:[UIImage imageNamed:[leafDictionary valueForKey:leafImage]]];
            
            NSNumber *XCoordinate = [leafDictionary valueForKey:leafXCoordinate];
            NSNumber *floorCoordinate = [leafDictionary valueForKey:leafFloorCoordinate];
            
            [leafView setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:floorCoordinate,
                                                                                floorKey,
                                                                                nil]];
            NSLog(@"%d %d" , [XCoordinate integerValue] , [floorCoordinate integerValue]);
            
            [leafView setFrame:CGRectOffset(leafView.frame, [XCoordinate integerValue], [floorCoordinate integerValue])];
            
            NSLog(@"%f %f" , leafView.frame.origin.x , leafView.frame.origin.y);
            
            [leafView setUserInteractionEnabled:YES];
            [bookView addSubview:leafView];
        }
        
        stageCount--;
    }
    
    stageNumber = [pageDictionary count];
}

- (void)pageScrolledRight:(UISwipeGestureRecognizer *)swipeGesture
{
    if (currentPageNumber == 1)
    {
        return;
    }

    currentPageNumber--;
    
    [self bookPageChanged];
}

- (void)pageScrolledLeft:(UISwipeGestureRecognizer *)swipeGesture
{
    if (currentPageNumber == totalPageNumber - 1)
    {
        return;
    }

    currentPageNumber++;
    
    [self bookPageChanged];
}

- (void)bookPageChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.4];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        [bookView setAlpha:0.0];
        [UIView commitAnimations];
    });
    
    [[bookView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [self constructBookPageWithNumber:currentPageNumber];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.4];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        [bookView setAlpha:1.0];
        [UIView commitAnimations];
    });
}

#pragma mark -
#pragma mark - Setting Menu Methods

- (void)constructSettings
{
    UITapGestureRecognizer *settingTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showHideSettingsMenu:)];
    [settingTapGesture setNumberOfTapsRequired:2];
    
    [readerView addGestureRecognizer:settingTapGesture];
    
    innerSettingsView = [[UIView alloc] initWithFrame:CGRectMake(0, 700, 1024, 48)];
    [innerSettingsView setAlpha:0.0];
    [innerSettingsView setBackgroundColor:[UIColor colorWithRed:0.7f
                                                          green:0.7f
                                                           blue:1.0f
                                                          alpha:0.7]];
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, 28, 28)];
    [backButton setBackgroundColor:[UIColor clearColor]];
    [backButton setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [innerSettingsView addSubview:backButton];
    
    UIButton *simplyButton = [[UIButton alloc] initWithFrame:CGRectMake(920, 17, 92, 14)];
    [simplyButton setBackgroundColor:[UIColor clearColor]];
    [simplyButton setImage:[UIImage imageNamed:@"simply-small.png"] forState:UIControlStateNormal];
    [simplyButton addTarget:self action:@selector(aboutButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [innerSettingsView addSubview:simplyButton];
    
    upperSettingsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1024, 48)];
    [upperSettingsView setAlpha:0.0];
    [upperSettingsView setBackgroundColor:[UIColor colorWithRed:0.7f
                                                          green:0.7f
                                                           blue:1.0f
                                                          alpha:0.7]];
    
    UIButton *volumeButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, 28, 28)];
    [volumeButton setBackgroundColor:[UIColor clearColor]];
    [volumeButton setImage:[UIImage imageNamed:@"volume.png"] forState:UIControlStateNormal];
    [volumeButton addTarget:self action:@selector(volumeSettings:) forControlEvents:UIControlEventTouchUpInside];
    [upperSettingsView addSubview:volumeButton];
    
    volumeSettingsEnabled = NO;
    
    UIButton *languageButton = [[UIButton alloc] initWithFrame:CGRectMake(986, 10, 28, 28)];
    [languageButton setBackgroundColor:[UIColor clearColor]];
    [languageButton setImage:[UIImage imageNamed:@"language.png"] forState:UIControlStateNormal];
    [languageButton addTarget:self action:@selector(languageSettings:) forControlEvents:UIControlEventTouchUpInside];
    [upperSettingsView addSubview:languageButton];
    
    languageSettinhsEnabled = NO;
    
    [readerView addSubview:innerSettingsView];
    [readerView addSubview:upperSettingsView];
}

- (void)showHideSettingsMenu:(UITapGestureRecognizer *)tapGesture
{
    if (settingsEnabled)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.4];
            [UIView setAnimationCurve:UIViewAnimationCurveLinear];
            [innerSettingsView setAlpha:0.0];
            [upperSettingsView setAlpha:0.0];
            [UIView commitAnimations];
        });
        
        settingsEnabled = NO;
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.4];
            [UIView setAnimationCurve:UIViewAnimationCurveLinear];
            [innerSettingsView setAlpha:1.0];
            [upperSettingsView setAlpha:1.0];
            [UIView commitAnimations];
        });
        
        settingsEnabled = YES;
    }
}

- (IBAction)volumeSettings:(id)sender
{
    if (volumeSettingsEnabled)
    {
        //Perform conceal animations
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.1];
            [UIView setAnimationCurve:UIViewAnimationCurveLinear];
            [volumeSlider setFrame:CGRectMake(414, -28, 200, 28)];
            [UIView commitAnimations];
        });
        
        volumeSettingsEnabled = NO;
    }
    else
    {
        if (!volumeSlider)
        {
            volumeSlider = [[UISlider alloc] initWithFrame:CGRectMake(414, -28, 200, 28)];
            [volumeSlider setMinimumValue:0.0f];
            [volumeSlider setMaximumValue:1.0f];
            [volumeSlider setThumbImage:[UIImage imageNamed:@"slider-pin.png"] forState:UIControlStateNormal];
            [volumeSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
            [upperSettingsView addSubview:volumeSlider];
        }
        
        //Perform apperence animations
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.1];
            [UIView setAnimationCurve:UIViewAnimationCurveLinear];
            [volumeSlider setFrame:CGRectMake(414, 10, 200, 28)];
            [UIView commitAnimations];
        });
        
        volumeSettingsEnabled = YES;
    }
}

- (IBAction)backButtonClicked:(id)sender
{
    [self showTitle];
}

- (IBAction)aboutButtonClicked:(id)sender
{
    FairyTailAboutViewController *aboutViewController = [[FairyTailAboutViewController alloc] init];
    
    [[self navigationController] presentViewController:aboutViewController animated:YES completion:nil];
}

- (IBAction)languageSettings:(id)sender
{
    int buttonSize = 1024 / [languageDictionary count] > 28 ? 28 : 1024 / [languageDictionary count];
    int offsetFactor = (1024 - [languageDictionary count] * buttonSize) / 2;
    
    if (languageSettinhsEnabled)
    {
        int id = [languageDictionary count] - 1;
        
        for (NSString *code in [languageDictionary allValues])
        {
            UIButton *languageButton = (UIButton *)[upperSettingsView viewWithTag:(id + languageButtonTag)];
            
            //Perform coceal animations
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.1];
                [UIView setAnimationDelay:0.05 * id];
                [UIView setAnimationCurve:UIViewAnimationCurveLinear];
                [languageButton setFrame:CGRectMake(offsetFactor + id * buttonSize, -buttonSize, buttonSize, buttonSize)];
                [UIView commitAnimations];
            });
            
            id--;
        }
        
        languageSettinhsEnabled = NO;
    }
    else
    {
        int id = 0;
        
        for (NSString *code in [languageDictionary allValues])
        {
            UIButton *languageButton = (UIButton *)[upperSettingsView viewWithTag:(id + languageButtonTag)];
            
            if (!languageButton)
            {
                languageButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            }
            
            [languageButton setBackgroundColor:[UIColor clearColor]];
            [languageButton setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"icon-%@", code]] forState:UIControlStateNormal];
            [languageButton setFrame:CGRectMake(offsetFactor + id * buttonSize, -buttonSize, buttonSize, buttonSize)];
            [languageButton setTag:id + 200];
            [languageButton addTarget:self action:@selector(languageSettingsChoosen:) forControlEvents:UIControlEventTouchUpInside];
            [upperSettingsView addSubview:languageButton];
            
            //Perform apperence animations
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.1];
                [UIView setAnimationDelay:0.05 * id];
                [UIView setAnimationCurve:UIViewAnimationCurveLinear];
                [languageButton setFrame:CGRectMake(offsetFactor + id * buttonSize, 24 - buttonSize / 2, buttonSize, buttonSize)];
                [UIView commitAnimations];
            });
            
            id++;
        }
        
        languageSettinhsEnabled = YES;
    }
}

- (IBAction)languageSettingsChoosen:(id)sender
{
    int buttonSize = 1024 / [languageDictionary count] > 28 ? 28 : 1024 / [languageDictionary count];
    int offsetFactor = (1024 - [languageDictionary count] * buttonSize) / 2;
    int id = [languageDictionary count] - 1;
    
    for (NSString *code in [languageDictionary allValues])
    {
        UIButton *languageButton = (UIButton *)[upperSettingsView viewWithTag:(id + languageButtonTag)];
        
        //Perform coceal animations
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.1];
            [UIView setAnimationDelay:0.05 * id];
            [UIView setAnimationCurve:UIViewAnimationCurveLinear];
            [languageButton setFrame:CGRectMake(offsetFactor + id * buttonSize, -buttonSize, buttonSize, buttonSize)];
            [UIView commitAnimations];
        });
        
        id--;
    }
}

#pragma mark -
#pragma mark - CAAction Methods

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag
{
    //Handle Language Dialog's animation end in order to make language buttons clickable
    if ([[animation valueForKey:animationType] isEqualToString:@"buttonSlideInAnimation"])
    {
        int buttonSize = 1024 / [languageDictionary count] > 128 ? 128 : 1024 / [languageDictionary count];
        int offsetFactor = (1024 - [languageDictionary count] * buttonSize) / 2;
        int id = 0;
        
        for (NSString *code in [languageDictionary allValues])
        {
            UIButton *languageButton = (UIButton *)[self.view viewWithTag:(100 + id)];
            [languageButton setFrame:CGRectMake(offsetFactor + id * buttonSize, 374 - buttonSize / 2, buttonSize, buttonSize)];
            
            id++;
        }
    }
}

- (void)runActionForKey:(NSString *)event object:(id)anObject arguments:(NSDictionary *)dict
{
    
}

#pragma mark -
#pragma mark - UISlider Methods

- (IBAction)sliderValueChanged:(id)sender
{
    
}

#pragma mark -
#pragma mark - Motion Manager Methods

- (void)getDeviceGLRotationMatrixWithAcceleration:(CMRotationRate)rotationRate
{
    //Kip track on device motion
    
    CMDeviceMotion *deviceMotion = motionManager.deviceMotion;
    CMAcceleration deviceAcceleration = motionManager.accelerometerData.acceleration;
    CMAttitude *attitude = deviceMotion.attitude;
    
    if (motionAttitude != nil) [attitude multiplyByInverseOfAttitude:motionAttitude];
    
    for (int i = 0 ; i < stageNumber ; i++)
    {
        //Perform parallax
        UIView *stage = (UIView *)[bookView viewWithTag:parallaxStageTag + i];

        NSNumber *coefficient = (NSNumber *)[[stage userInfo] valueForKey:parallaxCoefficient];
        CGFloat sign = ((attitude.yaw + attitude.pitch) > 0) ? 1 : -1;
        CGFloat pitch = sin(attitude.pitch) * sin(attitude.pitch);
        CGFloat yaw = sin(attitude.yaw) * sin(attitude.yaw);
        CGFloat root = sqrt(pitch + yaw);
        CGFloat angle = sign * root * [coefficient floatValue];
        [stage setFrame:CGRectOffset(stageFrame, angle, 0)];
        
        NSInteger rotationalNumber = [[[stage userInfo] valueForKey:rotationalNumberInStage] integerValue];
        
        for (int j = 0 ; j < rotationalNumber ; j++)
        {
            //Perform rotations
            UIImageView *rotational = (UIImageView *)[stage viewWithTag:rotationalTag + j];
            [rotational setTransform:CGAffineTransformMakeRotation(-[attitude pitch])];
        }
    }
    
    accellX = deviceAcceleration.x;
    accellZ = deviceAcceleration.z;
}

#pragma mark -
#pragma mark - Touch Methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    for(FairyTailInteractiveRotatableImageView *subview in [bookView subviews])
    {
        if([subview isKindOfClass:[FairyTailInteractiveRotatableImageView class]] && CGRectContainsPoint(subview.frame, [touch locationInView:bookView]))
        {
            [subview setIsAnimationAllowed:NO];
            [subview setPoint:[[touches anyObject] locationInView:subview]];
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    
    for (UIView *subview in [bookView subviews])
    {
        if ([subview isKindOfClass:[FairyTailInteractiveLeafImageView class]] && CGRectContainsPoint(subview.frame, [touch locationInView:bookView]))
        {
            FairyTailInteractiveLeafImageView *view = (FairyTailInteractiveLeafImageView *)subview;
            
            if([view touchSum] == 0)
            {
                [view setPoint:[touch locationInView:subview]];
                [view setTouchSum:1];
            }
            else if ([view touchSum] == 1)
            {
                [view setVelocityX:([touch locationInView:subview].x - [view point].x)];
                [view setVelocityY:([touch locationInView:subview].y - [view point].y) * 2];
                
                NSLog(@"Velocity %f %f" , [view velocityX] , [view velocityY]);
                
                [view setTouchSum:20];
                
                [view setIsAnimationAllowed:YES];
            }
        }
        
        
        if([subview isKindOfClass:[FairyTailInteractiveRotatableImageView class]] && CGRectContainsPoint(subview.frame, [touch locationInView:bookView]))
        {
            
            FairyTailInteractiveRotatableImageView *view = (FairyTailInteractiveRotatableImageView *)subview;
            UITouch *concreteTouch = [touches anyObject];
            
            if (CGRectContainsPoint(view.frame, [concreteTouch locationInView:[view superview]]))
            {
                return;
            }
            
            CGPoint touchPoint = [concreteTouch locationInView:view];

            CGFloat velocityXVector = [view point].x - touchPoint.x;
            CGFloat velocityYVector = [view point].y - touchPoint.y;
            
            //Determine sign of rotation
            [view setSign:0];
            
            CGFloat a = ([view point].y - [view centerPoint].y) / ([view point].x - [view centerPoint].x);
            
            if (a * (touchPoint.x - [view centerPoint].x) - (touchPoint.y - [view centerPoint].y) > 0)
            {
                if ([view point].x > [view centerPoint].x)
                {
                    [view setSign:-1];
                }
                else if ([view point].x < [view centerPoint].x)
                {
                    [view setSign:1];
                }
            }
            else if (a * touchPoint.x - touchPoint.y < 0)
            {
                if ([view point].x > [view centerPoint].x)
                {
                    [view setSign:1];
                }
                else if ([view point].x < [view centerPoint].x)
                {
                    [view setSign:-1];
                }
            }
            
            //Compute velocity and perform rotation
            [view setVelocity:sqrt(velocityXVector * velocityXVector + velocityYVector * velocityYVector)];
            
            [view setRotateTransformation:CGAffineTransformRotate([view rotateTransformation], [view sign] * ([view velocity] / [view centerPoint].x > 2 ? 2 : [view velocity] / [view centerPoint].x)) ];
            [view setTransform:[view rotateTransformation]];
            
            [view setPoint:touchPoint];
        }
    }
 
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{

}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{

}

@end
