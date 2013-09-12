//
//  FairyTailInteractiveLeaveImageView.m
//  Fairy Tail
//
//  Created by Nick Sargsyan on 9/12/13.
//  Copyright (c) 2013 Simply Technologies. All rights reserved.
//

#import "FairyTailInteractiveLeaveImageView.h"

@interface FairyTailInteractiveLeaveImageView ()
{
    CGPoint point;
}

@end

@implementation FairyTailInteractiveLeaveImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
//    touchSum = 0;
//    way.width = 0;
//    way.height = 0;
//    isAnimationAllowed = NO;
    point = [[touches anyObject] locationInView:self];
//    //point1 = [[touches anyObject] locationInView:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    
//    if(allowed)
//    {
//        if (self.frame.origin.y > floor)
//        {
//            allowed = NO;
//            [self setUserInteractionEnabled:NO];
//            isAnimationAllowed = NO;
//            [super touchesCancelled:touches withEvent:event];
//            [self performNormalisingAnimation];
//            return;
//        }
//        
//        //point1 = point;
//        way.width+=[touch locationInView:self].x-point.x;
//        way.height+=[touch locationInView:self].y-point.y;
//        NSLog(@"Touch x = %f" , [touch locationInView:self].x);
//        NSLog(@"Touch y = %f" , [touch locationInView:self].y);
//        NSLog(@"Point x = %f" , point.x);
//        NSLog(@"Point y = %f" , point.y);
//        [self setFrame:CGRectOffset(self.frame, [touch locationInView:self].x-point.x, [touch locationInView:self].y-point.y)];
//        point = [touch locationInView:self];
//        touchSum++;
//    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //velocityX = (point.x-point1.x)/2;
    //velocityY = (point.y-point1.y)/2;
//    moveEnded = YES;
//    if (!allowed)
//    {
//        velocityX = way.width/touchSum * 2;
//        velocityY = way.height/touchSum * 2;
//        [self setUserInteractionEnabled:YES];
//        allowed = YES;
//        moveEnded = NO;
//    }
//    isAnimationAllowed = YES;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    //velocityX = (point.x-point1.x)/2;
    //velocityY = (point.y-point1.y)/2;
//    moveEnded = YES;
//    if (!allowed)
//    {
//        velocityX = way.width/touchSum * 2;
//        velocityY = way.height/touchSum * 2;
//        [self setUserInteractionEnabled:YES];
//        allowed = YES;
//        moveEnded = NO;
//    }
//    isAnimationAllowed = YES;
}

@end
