//
//  EAPendingTaskInfoViewController.h
//  EASE
//
//  Created by Aladin TALEB on 03/03/2015.
//  Copyright (c) 2015 Aladin TALEB. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <YLProgressBar.h>
#import <MZFormSheetController.h>
#import "EANetworkingHelper.h"
#import "EAPendingTask.h"
#import "EAWorkingTask.h"
#import <SCLAlertView.h>
#import <Masonry.h>

@interface EATaskInfoViewController : UIViewController
{
    NSMutableArray *buttons;
}
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *agentNameBackgroundView;
@property (weak, nonatomic) IBOutlet UILabel *agentNameLabel;
@property (weak, nonatomic) IBOutlet UIView *taskNameBackgroundView;
@property (weak, nonatomic) IBOutlet UILabel *taskNameLabel;
@property (weak, nonatomic) IBOutlet UIView *dateBackgroundView;
@property (weak, nonatomic) IBOutlet UILabel *beginLabel;
@property (weak, nonatomic) IBOutlet UILabel *endLabel;

@property (weak, nonatomic) IBOutlet UIView *buttonsBackgroundView;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeStatusLabel;

@property (weak, nonatomic) IBOutlet YLProgressBar *progressBar;

@property(weak, nonatomic) EANotification *taskNotification;

@end
