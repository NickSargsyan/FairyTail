//
//  FairyTailInteractiveLeaveImageView.h
//  Fairy Tail
//
//  Created by Nick Sargsyan on 9/12/13.
//  Copyright (c) 2013 Simply Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FairyTailInteractiveLeafImageView : UIImageView

@property (nonatomic, readwrite) CGFloat velocityX;
@property (nonatomic, readwrite) CGFloat velocityY;

@property (nonatomic, readwrite) NSInteger touchSum;
    
@property (nonatomic, readwrite) BOOL isAnimationAllowed;

@property (nonatomic, readwrite) CGPoint point;

@end
