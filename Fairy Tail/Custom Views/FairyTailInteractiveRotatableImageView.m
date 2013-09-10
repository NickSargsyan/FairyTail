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
    
    CGPoint point;
    CGPoint centerPoint;
    
    CGFloat velocity;
    
    CGAffineTransform rotateTransformation;
    
    NSInteger angleCoefficient;
    NSInteger sign;
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
        
        rotateTransformation = CGAffineTransformMakeRotation(0);
    }
    return self;
}

- (id)initWithImage:(UIImage *)image
{
    self = [super initWithImage:image];
    if (self) {
        // Initialization code
        
        rotateTransformation = CGAffineTransformMakeRotation(0);
    }
    return self;
}

- (void)didMoveToSuperview
{
    //Retrieve rotation coefficient
    isAnimationAllowed = YES;
    
    centerPoint.x = self.frame.size.width / 2;
    centerPoint.y = self.frame.size.height / 2;
    
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
    angleCoefficient = (angleCoefficient + 1) % 640;
    
    if (isAnimationAllowed)
    {
        CGFloat rotationRate;
        
        if (velocity > 0)
        {
            rotationRate = sign * velocity / centerPoint.x + 2 * M_PI / 640;
            velocity--;
        }
        else
        {
            rotationRate = 2 * M_PI / 640;
        }
        
        rotateTransformation = CGAffineTransformRotate(rotateTransformation, rotationRate);
        [self setTransform:rotateTransformation];
    }
}

#pragma mark -
#pragma mark - Touch Event Handling Methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    isAnimationAllowed = NO;
    
    point = [[touches anyObject] locationInView:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *concreteTouch = [touches anyObject];
    CGPoint touchPoint = [concreteTouch locationInView:self];
    
    CGFloat velocityXVector = point.x - touchPoint.x;
    CGFloat velocityYVector = point.y - touchPoint.y;
    
    //Determine sign of rotation
    sign = 0;
    
    CGFloat a = (point.y - centerPoint.y) / (point.x - centerPoint.x);
    
    if (a * (touchPoint.x - centerPoint.x) - (touchPoint.y - centerPoint.y) > 0)
    {
        if (point.x > centerPoint.x)
        {
            sign = -1;
        }
        else if (point.x < centerPoint.x)
        {
            sign = 1;
        }
    }
    else if (a * touchPoint.x - touchPoint.y < 0)
    {
        if (point.x > centerPoint.x)
        {
            sign = 1;
        }
        else if (point.x < centerPoint.x)
        {
            sign = -1;
        }
    }
    
    //Compute velocity and perform rotation
    velocity = sqrt(velocityXVector * velocityXVector + velocityYVector * velocityYVector);
    
    rotateTransformation = CGAffineTransformRotate(rotateTransformation, sign * velocity / centerPoint.x);
    [self setTransform:rotateTransformation];
    
    point = touchPoint;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    isAnimationAllowed  = YES;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isAnimationAllowed = YES;
}

@end
