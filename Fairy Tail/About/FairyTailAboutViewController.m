//
//  FairyTailAboutViewController.m
//  Fairy Tail
//
//  Created by Nick Sargsyan on 9/10/13.
//  Copyright (c) 2013 Simply Technologies. All rights reserved.
//

#import "FairyTailAboutViewController.h"

@interface FairyTailAboutViewController ()

@end

@implementation FairyTailAboutViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIImageView *image1 = [[UIImageView alloc] initWithFrame:CGRectMake(101, 20, 200, 200)];
    [image1 setImage:[UIImage imageNamed:@"0.jpg"]];
    [[self view]  addSubview:image1];
    UITextView *text1 = [[UITextView alloc] initWithFrame:CGRectMake(200, 200, 300, 1000)];
    [text1 setText:@"Hello"];
    [text1 setBackgroundColor:[UIColor clearColor]];
    [text1 setFont:[UIFont systemFontOfSize:20]];
    [text1 setEditable:NO];
    [[self view] addSubview:text1];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
