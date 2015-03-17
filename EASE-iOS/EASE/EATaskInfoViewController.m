//
//  EAPendingTaskInfoViewController.m
//  EASE
//
//  Created by Aladin TALEB on 03/03/2015.
//  Copyright (c) 2015 Aladin TALEB. All rights reserved.
//

#import "EATaskInfoViewController.h"

@interface EATaskInfoViewController ()

@end

@implementation EATaskInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.imageView.clipsToBounds = true;
    buttons = [NSMutableArray array];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setTaskNotification:(EANotification *)taskNotification
{
    
    _taskNotification = taskNotification;
    
    if (self.isViewLoaded) {
        
        
        NSArray *colors = @[[UIColor colorWithRed:44/255.0 green:218/255.0 blue:252/255.0 alpha:1.0], [UIColor colorWithRed:28/255.0 green:253/255.0 blue:171/255.0 alpha:1.0], [UIColor colorWithRed:252/255.0 green:200/255.0 blue:53/255.0 alpha:1.0], [UIColor colorWithRed:253/255.0 green:101/255.0 blue:107/255.0 alpha:1.0], [UIColor colorWithRed:254/255.0 green:100/255.0 blue:192/255.0 alpha:1.0]];
        
        
        UIColor *color = colors[arc4random()%5];
        
        
        
        self.agentNameBackgroundView.backgroundColor = color;
        
        self.agentNameLabel.textColor = [UIColor whiteColor];
        self.taskNameLabel.textColor = [UIColor colorWithWhite:180/255. alpha:1.0];
        
        self.agentNameBackgroundView.layer.masksToBounds = false;
        self.agentNameBackgroundView.layer.shadowOffset = CGSizeMake(0, -2);
        self.agentNameBackgroundView.layer.shadowOpacity = 0.2;
        self.agentNameBackgroundView.layer.shadowRadius = 2;
        self.agentNameBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
        
        self.taskNameBackgroundView.layer.masksToBounds = false;
        self.taskNameBackgroundView.layer.shadowOffset = CGSizeMake(0, 0);
        self.taskNameBackgroundView.layer.shadowOpacity = 0.1;
        self.taskNameBackgroundView.layer.shadowRadius = 1;
        self.taskNameBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
        
        self.dateBackgroundView.layer.masksToBounds = false;
        self.dateBackgroundView.layer.shadowOffset = CGSizeMake(0, 0);
        self.dateBackgroundView.layer.shadowOpacity = 0.1;
        self.dateBackgroundView.layer.shadowRadius = 3;
        self.dateBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
        
        self.buttonsBackgroundView.backgroundColor = color;
        self.buttonsBackgroundView.layer.masksToBounds = false;
        self.buttonsBackgroundView.layer.shadowOffset = CGSizeMake(0, -2);
        self.buttonsBackgroundView.layer.shadowOpacity = 0.2;
        self.buttonsBackgroundView.layer.shadowRadius = 3;
        self.buttonsBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
        
        self.beginLabel.textColor = color;
        self.endLabel.textColor = color;
        
        for (UIButton *button in buttons)
            [button removeFromSuperview];
        [buttons removeAllObjects];
        
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 3, self.view.frame.size.width, self.buttonsBackgroundView.frame.size.height-3)];
        [button addTarget:self action:@selector(didTapCenterButton:) forControlEvents:UIControlEventTouchUpInside];
        
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18];
        
        
        if (_taskNotification.class == EAPendingTask.class)
            [button setTitle:@"Start" forState:UIControlStateNormal];
        
        else if (_taskNotification.class == EAWorkingTask.class)
            [button setTitle:@"Done" forState:UIControlStateNormal];
        
        
        [self.buttonsBackgroundView addSubview:button];
        [buttons addObject:button];
        

        
        
        if (_taskNotification.class == EAWorkingTask.class)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(workingTaskUpdated:) name:EAWorkingTaskUpdate object:nil];
        }
        [self update];
        
    }
    
    
}

-(void)update
{
    
    
    
    if (self.taskNotification.class == EAPendingTask.class)
    {
        self.statusLabel.text = @"Pending";
        //self.beginLabel.textColor = color;
        
        
    }
    else if (self.taskNotification.class == EAWorkingTask.class)
    {
        self.statusLabel.text = [NSString stringWithFormat:@"%@ (%d%%)", self.taskNotification.status, (int)(100*self.taskNotification.completionPercentage)];
        //self.endLabel.textColor = color;
        
    }

}

-(void)didTapCenterButton:(UIButton*)sender
{
    
    if (_taskNotification.class == EAPendingTask.class)
    {
        EAPendingTask *pendingTask = _taskNotification;
        
        if (!pendingTask.alertMessage) {
            [[EANetworkingHelper sharedHelper] startPendingTask:pendingTask completionBlock:^(BOOL ok, EAWorkingTask *workingTask) {
                if (ok) {
                    self.taskNotification = workingTask;
                }
            }];
        }
        else {
            SCLAlertView *alert = [[SCLAlertView alloc] init];
            alert.showAnimationType = SlideInFromCenter;
            alert.backgroundType = Blur;
            alert.customViewColor = [UIColor colorWithWhite:200/255. alpha:1.0];
            alert.iconTintColor = [UIColor whiteColor];
            
            [alert addButton:@"Everything's ok ! Let's do it !" actionBlock:^{
                [[EANetworkingHelper sharedHelper] startPendingTask:pendingTask completionBlock:^(BOOL ok, EAWorkingTask *workingTask) {
                    if (ok) {
                        self.taskNotification = workingTask;
                    }
                }];
            }];
            
            [alert showWarning:self title:@"Warning" subTitle:pendingTask.alertMessage closeButtonTitle:@"Let me check ..." duration:0];
            
            
        }
    }
    
   
}

-(void)workingTaskUpdated:(NSNotification*)notification
{
    EAWorkingTask *task = notification.userInfo[@"workingTask"];
    
    int index = [[EANetworkingHelper sharedHelper].workingTasks indexOfObject:task];
    
    if (index != -1)
        [self update];
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end