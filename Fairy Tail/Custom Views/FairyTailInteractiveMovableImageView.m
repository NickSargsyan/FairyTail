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
    NSInteger count;
    CGSize way;
    NSInteger touchSum;
    BOOL allowed,goBack;
    
}

@end

@implementation FairyTailInteractiveMovableImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        speed = arc4random() % 17 + 3;
        count = 0;
        allowed = YES;
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
        allowed = YES;
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
            count = arc4random() % 150;
            speed = arc4random() % 2 + 1;
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
                    allowed = NO;
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
        [UIView setAnimationDuration:sqrt((point.x - x)*(point.x - x)+(point.y - y)*(point.y - y)) / 1000];
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
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    
    if(allowed)
    {
        if (self.frame.origin.y > floor)
        {
            allowed = NO;
            [self setUserInteractionEnabled:NO];
            isAnimationAllowed = NO;
            [super touchesCancelled:touches withEvent:event];
            [self performNormalisingAnimation];
            return;
        }
        
        //point1 = point;
        way.width = [touch locationInView:self].x - point.x;
        way.height = [touch locationInView:self].y - point.y;
        NSLog(@"Touch x = %f" , [touch locationInView:self].x);
        NSLog(@"Touch y = %f" , [touch locationInView:self].y);
        NSLog(@"Point x = %f" , point.x);
        NSLog(@"Point y = %f" , point.y);
        [self setFrame:CGRectOffset(self.frame, [touch locationInView:self].x-point.x, [touch locationInView:self].y-point.y)];
        point = [touch locationInView:self];
        touchSum++;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    moveEnded = YES;
    if (!allowed)
    {
        velocityX = way.width;
        velocityY = way.height;
        [self setUserInteractionEnabled:YES];
        allowed = YES;
        moveEnded = NO;
    }
    isAnimationAllowed = YES;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    moveEnded = YES;
    if (!allowed)
    {
        velocityX = way.width;
        velocityY = way.height;
        [self setUserInteractionEnabled:YES];
        allowed = YES;
        moveEnded = NO;
    }
    isAnimationAllowed = YES;
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
