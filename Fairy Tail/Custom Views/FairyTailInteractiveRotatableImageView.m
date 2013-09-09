//
//  FairyTailInteractiveRotatableImageView.m
//  Fairy Tail
//
//  Created by Nick Sargsyan on 9/4/13.
//  Copyright (c) 2013 Simply Technologies. All rights reserved.
//

#import "FairyTailInteractiveRotatableImageView.h"
#import "UIView+UserInfo.h"
#import "Constants.h"

@interface FairyTailInteractiveRotatableImageView()
{
    NSTimer *timer;
    
    BOOL isAnimationAllowed;
    
    NSInteger viewRotationCoefficient;
    NSInteger angleCoefficient;
}

@end

@implementation FairyTailInteractiveRotatableImageView

#pragma mark -
#pragma mark - Initialization Methods

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        
    }
    return self;
}

- (void)didMoveToSuperview
{
    //Retrieve rotation coefficient
    viewRotationCoefficient = [[[self userInfo] valueForKey:rotationCoefficient] integerValue];
    
    isAnimationAllowed = YES;
    
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0f/30.0f
                                             target:self
                                           selector:@selector(performCustomAnimation)
                                           userInfo:nil
                                            repeats:YES];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

#pragma mark - 
#pragma mark - Animation Methods

- (void)performCustomAnimation
{
    angleCoefficient = (angleCoefficient + 1) % viewRotationCoefficient;
    
    if (isAnimationAllowed)
    {
        //Perform button animations
        CAKeyframeAnimation *buttonSlideInAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position.y"];
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
    }
}

#pragma mark -
#pragma mark - Touch Event Handling Methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

@end
