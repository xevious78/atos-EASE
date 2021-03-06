//
//  EAWorkflowListCollectionViewController.m
//  EASE
//
//  Created by Aladin TALEB on 08/02/2015.
//  Copyright (c) 2015 Aladin TALEB. All rights reserved.
//

#import "EAWorkflowListCollectionViewController.h"

#import "MZFormSheetController.h"
#import "MZFormSheetSegue.h"


@interface EAWorkflowListCollectionViewController ()

@end

@implementation EAWorkflowListCollectionViewController

static NSString *const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;

    // Register cell classes

    colors = @[[UIColor colorWithRed:44/255.0 green:218/255.0 blue:252/255.0 alpha:1.0], [UIColor colorWithRed:28/255.0 green:253/255.0 blue:171/255.0 alpha:1.0], [UIColor colorWithRed:252/255.0 green:200/255.0 blue:53/255.0 alpha:1.0], [UIColor colorWithRed:253/255.0 green:101/255.0 blue:107/255.0 alpha:1.0], [UIColor colorWithRed:254/255.0 green:100/255.0 blue:192/255.0 alpha:1.0]];




    self.collectionView.backgroundColor = [UIColor colorWithWhite:245/255. alpha:1.0];
    FRGWaterfallCollectionViewLayout *layout = self.collectionViewLayout;
    layout.delegate = self;



    layout.itemWidth = (self.view.frame.size.width-30)/2;

    layout.topInset     = -10.0f;
    layout.bottomInset  = 0.0f;
    layout.stickyHeader = YES;



    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {


}

- (void)viewDidAppear:(BOOL)animated {

    [UIView animateWithDuration:0.5 animations:^{
         self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:44/255.0 green:218/255.0 blue:252/255.0 alpha:1.0];

     }];

}

- (void)setSearchResults:(EASearchResults *)searchResults {
    _searchResults = searchResults;
    if (self.isViewLoaded) {
        [self.collectionView reloadData];

    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.


    if ([segue.identifier isEqualToString:@"SortFilter"]) {

        EASearchSortTableViewController *vc = segue.destinationViewController;

        vc.sortBy = self.searchResults.constraints[@"sortBy"];


        MZFormSheetSegue *formSheetSegue = (MZFormSheetSegue *)segue;

        MZFormSheetController *formSheet = formSheetSegue.formSheetController;
        formSheet.transitionStyle        = MZFormSheetTransitionStyleDropDown;
        formSheet.cornerRadius           = 8.0;
        formSheet.shouldCenterVertically = true;
        formSheet.presentedFormSheetSize = CGSizeMake(300, 300);



        formSheet.shouldDismissOnBackgroundViewTap = YES;

        formSheet.willDismissCompletionHandler = ^(UIViewController *presentedFSViewController) {


            if (![vc.sortBy isEqualToString:self.searchResults.constraints[@"sortBy"]]) {
                NSMutableDictionary *constraints = [NSMutableDictionary dictionaryWithDictionary:self.searchResults.constraints];

                constraints[@"sortBy"] = vc.sortBy;

                [[EANetworkingHelper sharedHelper] sortWorkflowBy:vc.sortBy completionBlock:^(EASearchResults *searchResults, NSError *error) {
                     searchResults.constraints = constraints;
                     self.searchResults = searchResults;
                 }];
            }

        };

    }

}

- (void)pushWorkflow:(EAWorkflow *)workflow {

    EAWorkflowMasterViewController *workflowViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MasterInfo"];
    workflowViewController.workflow = workflow;
    workflowViewController.delegate = self;
    [self.navigationController pushViewController:workflowViewController animated:true];


}

- (void)workflowViewValidatedWorkflow {
    [self.delegate workflowListAskToDismiss];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == self.collectionView)
        return self.searchResults.workflows.count;

    return ((EAWorkflow *)self.searchResults.workflows[collectionView.tag]).consumption.allKeys.count;


}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    if (collectionView == self.collectionView) {
        EAWorkflowListCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];

        // Configure the cell

        EAWorkflow *workflow = self.searchResults.workflows[indexPath.row];

        cell.infosCollectionView.tag = indexPath.row;
        cell.workflow                = workflow;


        cell.imageView.progressIndicatorView.strokeProgressColor  = workflow.color;
        cell.imageView.progressIndicatorView.strokeRemainingColor = [UIColor colorWithWhite:230/255.0 alpha:1.0];
        cell.imageView.progressIndicatorView.strokeWidth          = 2;

        [cell.imageView setImageWithProgressIndicatorAndURL:workflow.metaworkflow.imageURL];




        return cell;
    }

    NSDictionary *dic = ((EAWorkflow *)self.searchResults.workflows[collectionView.tag]).consumption;


    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"InfoCell" forIndexPath:indexPath];

    NSString *key = dic.allKeys[indexPath.row];

    UIImageView *imageView = [cell viewWithTag:2];
    imageView.image = [UIImage imageNamed:key];

    UILabel *label = [cell viewWithTag:1];


    if ([key isEqualToString:@"time"]) {

        int TI = ceil(((NSNumber *)dic.allValues[indexPath.row]).floatValue)/60;

        int minutes = TI%60;
        int hours   = TI/60;

        label.text = [NSString stringWithFormat:@"%dh%dm", hours, minutes];


    } else if ([key isEqualToString:@"WATER"])
        label.text = [NSString stringWithFormat:@"%0.1fL", ((NSNumber *)dic.allValues[indexPath.row]).floatValue];

    else if ([key isEqualToString:@"CO2"])
        label.text = [NSString stringWithFormat:@"%0.2fg/CO2", ((NSNumber *)dic.allValues[indexPath.row]).floatValue];



    label.textColor = [UIColor whiteColor];


    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    EAWorkflow *workflow = self.searchResults.workflows[indexPath.row];



    if (workflow.tasks.count) {
        [self pushWorkflow:workflow];

    }


}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    int nbItems   = [self collectionView:collectionView numberOfItemsInSection:0];
    int itemWidth = collectionViewLayout.itemSize.width;
    int space     = collectionViewLayout.minimumInteritemSpacing;

    int w = nbItems*(itemWidth+space);

    int delta = (collectionView.frame.size.width-w)/2;
    return UIEdgeInsetsMake(0, MAX(delta, 0), 0, 0);


}

#pragma mark - FRGWaterfallCollectionViewDelegate

- (CGFloat)     collectionView:(UICollectionView *)collectionView
                        layout:(FRGWaterfallCollectionViewLayout *)collectionViewLayout
    heightForHeaderAtIndexPath:(NSIndexPath *)indexPath {
    return 20;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(FRGWaterfallCollectionViewLayout *)collectionViewLayout heightForItemAtIndexPath:(NSIndexPath *)indexPath {
    return 250 + indexPath.row%3*40;

}

- (IBAction)cancel:(id)sender {
    [self.delegate workflowListAskToDismiss];
}

@end
