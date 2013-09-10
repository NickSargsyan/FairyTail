//
//  FairyTailInteractiveMovableImageView.m
//  Fairy Tail
//
//  Created by Nick Sargsyan on 9/4/13.
//  Copyright (c) 2013 Simply Technologies. All rights reserved.
//

#import "FairyTailInteractiveMovableImageView.h"
#import "UIView+UserInfo.h"
#import "Constants.h"

@interface FairyTailInteractiveMovableImageView()
{
    NSTimer *timer;
    
    BOOL isAnimationAllowed,moveEnded;
    CGFloat velocityX,velocityY;
    CGFloat speed;
    CGFloat seil;
    CGFloat floor;
    CGPoint point;
    //CGPoint point1;
    NSInteger count;
    CGSize way;
    NSInteger touchSum;
    
}

@end

@implementation FairyTailInteractiveMovableImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        speed = arc4random() % 17 + 3;
    }
    return self;
}

- (id)initWithImage:(UIImage *)image
{
    self = [super initWithImage:image];
    if (self) {
        // Initialization code
        speed = arc4random() % 17 + 3;
        count = 0;
    }
    return self;
}

- (void)didMoveToSuperview
{
    isAnimationAllowed = YES;
    seil = [[[self userInfo] valueForKey:seilKey] floatValue];
    floor = [[[self userInfo] valueForKey:floorKey] floatValue];
    
    CGFloat x = -(self.frame.size.width);
    CGFloat y = arc4random() % (int)(floor - seil) + seil;
    [self setFrame:CGRectMake(x, y, self.frame.size.width, self.frame.size.height)];
    
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

- (void)performCustomAnimation
{
    if(isAnimationAllowed && count<=0)
    {
        CGFloat x = self.frame.origin.x;
        CGFloat y = self.frame.origin.y;
        
        if(x >= self.superview.frame.size.width)
        {
            count = arc4random() % 60;
            speed = arc4random() % 17 + 3;
            x = -(self.frame.size.width);
            y = arc4random() % (int)(floor - seil) + seil;
            [self setFrame:CGRectMake(x, y, self.frame.size.width, self.frame.size.height)];
        }
        else
        {
            if(moveEnded)
            {
                [self setFrame:CGRectOffset(self.frame, speed+velocityX, velocityY)];
                
                if(velocityX>0)
                {
                    velocityX--;
                    if(velocityX<0)
                        velocityX=0;
                }
                else if (velocityX<0)
                {
                    velocityX++;
                    if(velocityX>0)
                        velocityX=0;
                }
                if(velocityY>0)
                {
                    velocityY--;
                    if(velocityY<0)
                        velocityY=0;
                }
                else if (velocityY<0)
                {
                    velocityY++;
                    if(velocityY>0)
                        velocityY=0;
                }
                if(velocityY==0 && velocityX==0)
                    moveEnded=NO;
                
                if (self.frame.origin.y > floor)
                {
                    isAnimationAllowed = NO;
                    [self setUserInteractionEnabled:NO];
                    [self performNormalisingAnimation];
                }
            }
            else
            {
                [self setFrame:CGRectOffset(self.frame, speed, 0)];
            }
        }
    }
    count--;
}

- (void)performNormalisingAnimation
{
    CGFloat x = arc4random() % (int)self.superview.frame.size.width;
    CGFloat y = arc4random() % (int)(floor - seil) + seil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.4];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        [UIView setAnimationDelegate:self];
        [self setFrame:CGRectMake(x, y, self.frame.size.width, self.frame.size.height)];
        [UIView commitAnimations];
    });
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    touchSum = 0;
    way.width = 0;
    way.height = 0;
    isAnimationAllowed = NO;
    point = [[touches anyObject] locationInView:self];
    //point1 = [[touches anyObject] locationInView:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    //point1 = point;
    UITouch * touch = [touches anyObject];
    way.width+=[touch locationInView:self].x-point.x;
    way.height+=[touch locationInView:self].y-point.y;
    
    [self setFrame:CGRectOffset(self.frame, [touch locationInView:self].x-point.x, [touch locationInView:self].y-point.y)];
    point = [touch locationInView:self];
    touchSum++;
    
    if (self.frame.origin.y > floor)
    {
        [self setUserInteractionEnabled:NO];
        [self performNormalisingAnimation];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //velocityX = (point.x-point1.x)/2;
    //velocityY = (point.y-point1.y)/2;
    velocityX = way.width/touchSum * 2;
    velocityY = way.height/touchSum * 2;
    NSLog(@"%f %f" , velocityX , velocityY);
    isAnimationAllowed = YES;
    moveEnded = YES;
    
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    //velocityX = (point.x-point1.x)/2;
    //velocityY = (point.y-point1.y)/2;
    velocityX = way.width/touchSum * 2;
    velocityY = way.height/touchSum * 2;
    isAnimationAllowed = YES;
    moveEnded = YES;
}

#pragma mark -
#pragma mark - CAAction Methods

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag
{
    velocityX = 0;
    velocityY = 0;
    moveEnded = NO;
    isAnimationAllowed = YES;
    [self setUserInteractionEnabled:YES];
}

- (void)runActionForKey:(NSString *)event object:(id)anObject arguments:(NSDictionary *)dict
{
    
}

@end
