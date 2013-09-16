//
//  FairyTailInteractiveLeaveImageView.m
//  Fairy Tail
//
//  Created by Nick Sargsyan on 9/12/13.
//  Copyright (c) 2013 Simply Technologies. All rights reserved.
//

#import "FairyTailInteractiveLeafImageView.h"
#import "UIView+UserInfo.h"
#import "Constants.h"

@interface FairyTailInteractiveLeafImageView ()
{    
    CGFloat floor;

    NSTimer *timer;
}

@end

@implementation FairyTailInteractiveLeafImageView

@synthesize velocityX = velocityX;
@synthesize velocityY = velocityY;
@synthesize touchSum = touchSum;
@synthesize isAnimationAllowed = isAnimationAllowed;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        isAnimationAllowed = NO;
    }
    return self;
}

- (id)initWithImage:(UIImage *)image
{
    self = [super initWithImage:image];
    if (self) {
        // Initialization code
        
        isAnimationAllowed = NO;
    }
    return self;
}

- (void)didMoveToSuperview
{
    floor = [[[self userInfo] valueForKey:floorKey] floatValue];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0f/30.0f target:self selector:@selector(performDropdownAnimation) userInfo:nil repeats:YES];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)performDropdownAnimation
{
    if (isAnimationAllowed)
    {
        if (velocityX < 0)
        {
            velocityX = velocityX + 0.5f;
            
            if (velocityX > 0)
            {
                velocityX = 0;
            }
        }
        
        if (velocityX > 0)
        {
            velocityX = velocityX - 0.5f;
            
            if (velocityX < 0)
            {
                velocityX = 0;
            }
        }
        
        if (self.frame.origin.y >= (floor - 3) && velocityY > 0)
        {
            velocityY = 0;
            
            if (velocityX < 0)
            {
                velocityX = velocityX + 3;
                
                if (velocityX > 0)
                {
                    velocityX = 0;
                }
            }
            
            if (velocityX > 0)
            {
                velocityX = velocityX - 3;
                
                if (velocityX < 0)
                {
                    velocityX = 0;
                }
            }
            
            if (velocityX == 0 && velocityY == 0)
            {
                isAnimationAllowed = NO;
                touchSum = 0;
            }
            
            [self setFrame:CGRectMake(self.frame.origin.x + velocityX, floor, self.frame.size.width, self.frame.size.height)];
        }
        else
        {
            if (velocityY < 0)
            {
                velocityY = velocityY + 2;
            }
            else
            {
                velocityY = velocityY + 0.5;
            }
            
            [self setFrame:CGRectOffset(self.frame, velocityX, velocityY)];
        }
        
        NSLog(@"Velocity Change %f %f" , velocityX , velocityY);
    }
}

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
//{
//    touchSum = 0;
//    
//    point = [[touches anyObject] locationInView:self];
//}
//
//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
//{
//    UITouch * touch = [touches anyObject];
//    
//    if(touchSum < 1)
//    {
//        velocityX = ([touch locationInView:self].x-point.x) * 5;
//        velocityY = ([touch locationInView:self].y-point.y) * 5;
//        
//        [self setFrame:CGRectOffset(self.frame, velocityX, velocityY)];
//        
//        touchSum++;
//    }
//}
//
//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
//{
//    isAnimationAllowed = YES;
//}
//
//- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
//{
//    isAnimationAllowed = YES;
//}

@end
