//
//  FairyTailInteractiveRotatableImageView.h
//  Fairy Tail
//
//  Created by Nick Sargsyan on 9/4/13.
//  Copyright (c) 2013 Simply Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface FairyTailInteractiveRotatableImageView : UIImageView

@property (nonatomic, readwrite) BOOL isAnimationAllowed;

@property (nonatomic, readwrite) CGPoint point;
@property (nonatomic, readwrite) CGPoint centerPoint;

@property (nonatomic, readwrite) NSInteger sign;

@property (nonatomic, readwrite) CGFloat velocity;

@property (nonatomic, readwrite) CGAffineTransform rotateTransformation;

@end
