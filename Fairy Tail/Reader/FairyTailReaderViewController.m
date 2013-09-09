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
#import "UIView+UserInfo.h"
#import "Constants.h"

@interface FairyTailReaderViewController ()
{
    NSInteger currentPageNumber;
    NSInteger totalPageNumber;
    
    NSInteger stageNumber;
    NSInteger rotationalNumber;
    
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

@end

@implementation FairyTailReaderViewController

@synthesize bookView = bookView;
@synthesize titleView = titleView;
@synthesize readerView = readerView;
@synthesize upperSettingsView = upperSettingsView;
@synthesize innerSettingsView = innerSettingsView;
@synthesize volumeSlider = volumeSlider;

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
        
        
//        motionTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0/60.0)
//                                                          target:self
//                                                        selector:@selector(getDeviceGLRotationMatrix)
//                                                        userInfo:nil
//                                                         repeats:YES];
        
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
        titleView = [[UIView alloc] initWithFrame:[[self view] frame]];
        [titleView setAlpha:0.0f];
        
        UIImageView *titleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 1025, 748)];
        [titleImageView setImage:[UIImage imageNamed:@"0.jpg"]];
        [titleImageView setContentMode:UIViewContentModeScaleAspectFit];
        [titleImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(beginReading:)]];
        [titleImageView setUserInteractionEnabled:YES];
        [titleView addSubview:titleImageView];
        
        UIScrollView *titleScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 548, 1024, 200)];
        [titleScrollView setBackgroundColor:[UIColor colorWithRed:0.5
                                                          green:0.1
                                                          blue:0.4
                                                          alpha:0.7]];
        [titleView addSubview:titleScrollView];
        
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
    UISwipeGestureRecognizer *leftGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(pageScrolledLeft:)];
    [leftGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
    
    bookView = [[UIView alloc] initWithFrame:CGRectMake(95, 93, 832, 562)];
    [bookView setUserInteractionEnabled:YES];
    [bookView setClipsToBounds:YES];
    [bookView setGestureRecognizers:[[NSArray alloc] initWithObjects:leftGestureRecognizer, rightGestureRecognizer, nil]];
    
    bookDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Book" ofType:@"plist"]];
    
    totalPageNumber = [bookDictionary count];

    //Construct first page
    [self constructBookPageWithNumber:0];
    
    [readerView addSubview:bookView];
}

- (void)constructBookPageWithNumber:(NSInteger)pageNumber
{
    NSMutableDictionary *pageDictionary = [bookDictionary objectForKey:[NSString stringWithFormat:@"Page-%d", pageNumber]];
    
    //Add stages
    NSInteger stageCount = [pageDictionary count] - 1;
    
    rotationalNumber = 0;

    for (NSDictionary *stageDictionary in [pageDictionary allValues])
    {
        NSLog(@"%@", [stageDictionary debugDescription]);
        
        UIView *stageView = [[UIView alloc] initWithFrame:stageFrame];
        [stageView setUserInfo:[NSDictionary dictionaryWithObject:[stageDictionary valueForKey:parallaxCoefficient] forKey:parallaxCoefficient]];
        [stageView setTag:stageCount + parallaxStageTag];
        [bookView addSubview:stageView];
        
        UIImageView *stageImageView = [[UIImageView alloc] initWithFrame:stageFrame];
        [stageImageView setImage:[UIImage imageNamed:[stageDictionary valueForKey:stageImage]]];
        [stageView addSubview:stageImageView];
        
        //Add rotatables to stafe
        NSMutableDictionary *rotationalsDictionary = [stageDictionary objectForKey:rotationals];
        
        NSInteger rotationalCount = [rotationalsDictionary count] - 1;
        
        for (NSDictionary *rotationalDictionary in [rotationalsDictionary allValues])
        {
            NSLog(@"%@", [rotationalDictionary debugDescription]);
            
            FairyTailInteractiveMovableImageView *rotationalView = [[FairyTailInteractiveMovableImageView alloc] initWithImage:[UIImage imageNamed:[rotationalDictionary valueForKey:rotationalImage]]];
            
            //Pass rotation coefficient via userInfo
            [rotationalView setUserInteractionEnabled:YES];
            [rotationalView setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:640],rotationCoefficient,
                                                                                    [NSNumber numberWithInteger:0],seilKey,
                                         [NSNumber numberWithInteger:300],floorKey,
                                                                                    nil]];
            
            //[rotationalView setFrame:CGRectOffset([rotationalView frame], [[rotationalDictionary valueForKey:rotationalXCoordinate] floatValue], [[rotationalDictionary valueForKey:rotationalYCoordinate] floatValue])];
            [rotationalView setTag:rotationalCount + rotationalTag];
            [stageView addSubview:rotationalView];
            
            rotationalCount--;
        }
        
        rotationalNumber = rotationalNumber + [rotationalsDictionary count];
        
        stageCount--;
    }
    
    stageNumber = [pageDictionary count];
}

- (void)pageScrolledRight:(UISwipeGestureRecognizer *)swipeGesture
{
    if (currentPageNumber == 0)
    {
        return;
    }

    currentPageNumber--;
    
    [self bookPageChanged];
}

- (void)pageScrolledLeft:(UISwipeGestureRecognizer *)swipeGesture
{
    if (currentPageNumber == totalPageNumber)
    {
        return;
    }

    currentPageNumber++;
    
    [self bookPageChanged];
}

- (void)bookPageChanged
{
    //Nothing here yet
    CATransition *transitionAnimation = [CATransition animation];
    [transitionAnimation setDuration:1.0f];
    [transitionAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [transitionAnimation setType:kCATransitionFade];
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

- (UIAccelerationValue)tendToZero:(UIAccelerationValue)value {
    if (value < 0) {
        return ceil(value);
    } else {
        return floor(value);
    }
}

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
        
        for (int j = 0 ; j < rotationalNumber ; j++)
        {
            //Perform rotations
            UIImageView *rotational = (UIImageView *)[stage viewWithTag:rotationalTag + j];
            [rotational setTransform:CGAffineTransformMakeRotation([attitude pitch] * [attitude roll])];
        }
    }
    
    accellX = deviceAcceleration.x;
    accellZ = deviceAcceleration.z;
}

@end
