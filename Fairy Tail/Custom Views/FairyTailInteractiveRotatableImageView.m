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

    NSInteger angleCoefficient;
}

@end

@implementation FairyTailInteractiveRotatableImageView

@synthesize rotateTransformation = rotateTransformation;
@synthesize isAnimationAllowed = isAnimationAllowed;
@synthesize centerPoint = centerPoint;
@synthesize velocity = velocity;
@synthesize sign = sign;

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
            rotationRate = sign * (velocity / centerPoint.x > 2 ? 2 : velocity / centerPoint.x) + 2 * M_PI / 640;
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

}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{

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
