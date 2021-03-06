//
//  EASearchPopupViewController.h
//  EASE
//
//  Created by Aladin TALEB on 18/04/2015.
//  Copyright (c) 2015 Aladin TALEB. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EANetworkingHelper.h"

@protocol EASearchPopupDelegate <NSObject>

- (void)popupFoundWorkflows:(EASearchResults *)searchResults;

@end


@interface EASearchPopupViewController : UIViewController  <UITextFieldDelegate>


@property(nonatomic, weak) id <EASearchPopupDelegate> delegate;


@property (weak, nonatomic) IBOutlet UITextField *searchQueryTextField;
@property (weak, nonatomic) IBOutlet UILabel     *examplesLabel;
@property (weak, nonatomic) IBOutlet UIButton    *searchButton;


- (IBAction)search:(id)sender;


@end
