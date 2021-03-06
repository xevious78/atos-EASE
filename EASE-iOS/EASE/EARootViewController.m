//
//  EARootViewController.m
//  EASE
//
//  Created by Aladin TALEB on 02/03/2015.
//  Copyright (c) 2015 Aladin TALEB. All rights reserved.
//

#import "EARootViewController.h"
#import "UIImage+ImageEffects.h"

@interface EARootViewController ()

@end

@implementation EARootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)awakeFromNib {

    self.menuPreferredStatusBarStyle = UIStatusBarStyleLightContent;
    self.contentViewShadowColor      = [UIColor blackColor];
    self.contentViewShadowOffset     = CGSizeMake(0, 2);
    self.contentViewShadowOpacity    = 0.6;
    self.contentViewShadowRadius     = 3;
    self.contentViewShadowEnabled    = YES;

    self.fadeMenuView             = true;
    self.scaleContentView         = true;
    self.scaleBackgroundImageView = true;
    self.scaleMenuView            = false;

    self.backgroundImage = [[UIImage imageNamed:@"MenuBG"] applyBlurWithRadius:20 tintColor:nil saturationDeltaFactor:1 maskImage:nil];

    self.contentViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"calendarViewController"];
    self.leftMenuViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"leftMenuController"];


}

@end
