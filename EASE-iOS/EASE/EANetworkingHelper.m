//
//  EANetworkingHelper.m
//  EASE
//
//  Created by Aladin TALEB on 12/02/2015.
//  Copyright (c) 2015 Aladin TALEB. All rights reserved.
//

#import "NSDate+Complements.h"

#import "EANetworkingHelper.h"
#import "EAWorkflow.h"
#import "EADateInterval.h"
#import "EATask.h"

#import "EASearchResults.h"
#import "EAMetaworkflow.h"

#import "EALoginViewController.h"



@interface EANetworkingHelper ()


@property (nonatomic, strong) AFHTTPSessionManager *easeServerManager;

@property (nonatomic, strong) AFHTTPSessionManager *witServerManager;

@property (nonatomic, strong) SocketIOClient *easeSocketManager;


@end

@implementation EANetworkingHelper

NSString *const witServerAddress = @"https://api.wit.ai/";
NSString *const witHeader        = @"Authorization";

NSString *const witToken      = @"Bearer Z6RAMHMFQLP6FG2KSPTT4F23XH5GK5L4";
NSString *const witAPIVersion = @"20150212";




NSString *const EATaskUpdate = @"EATaskUpdate";


#pragma mark - Init

+ (EANetworkingHelper *)sharedHelper {
    static EANetworkingHelper *_sharedHelper = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedHelper = [[self alloc] init];
    });

    return _sharedHelper;
}

- (id)init {
    if (self = [super init]) {

        _colors = @[[UIColor colorWithRed:44/255.0 green:218/255.0 blue:252/255.0 alpha:1.0], [UIColor colorWithRed:28/255.0 green:253/255.0 blue:171/255.0 alpha:1.0], [UIColor colorWithRed:252/255.0 green:200/255.0 blue:53/255.0 alpha:1.0], [UIColor colorWithRed:253/255.0 green:101/255.0 blue:107/255.0 alpha:1.0], [UIColor colorWithRed:254/255.0 green:100/255.0 blue:192/255.0 alpha:1.0]];


        self.easeServerAdress = @"localhost:1337";

        [Wit sharedInstance].accessToken = @"Z6RAMHMFQLP6FG2KSPTT4F23XH5GK5L4";
        [Wit sharedInstance].delegate    = self;


        self.witServerManager                   = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:witServerAddress]];
        self.witServerManager.requestSerializer = [AFJSONRequestSerializer serializer];
        [self.witServerManager.requestSerializer setValue:witToken forHTTPHeaderField:witHeader];
        self.witServerManager.responseSerializer = [AFJSONResponseSerializer serializer];

        _currentUser = nil;


    }

    return self;
}

- (void)setEaseServerAdress:(NSString *)easeServerAdress {
    _easeServerAdress      = easeServerAdress;
    self.easeServerManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/", easeServerAdress]]];


}

//Set cookie for the Socket Connection
- (void)setCookie:(NSHTTPCookie *)cookie {



    self.easeSocketManager = [[SocketIOClient alloc] initWithSocketURL:_easeServerAdress options:nil];

    if (cookie)
        self.easeSocketManager.cookies = @[cookie];

    [self.easeSocketManager connect];

    //SOCKET CALLBACKS
    [self.easeSocketManager on:@"connect" callback:^(NSArray *data, void (^ack)(NSArray *)) {
         NSLog(@"connected \n %@", data);


         [self.easeSocketManager emitWithAck:@"get" withItems:@[@{@"url" : @"/user/subscribe/", @"data" : @{}}]](0, ^(NSArray *data) {
            NSLog(@"%@", data);
        });
        
        


     }];



    [self.easeSocketManager on:@"reconnect" callback:^(NSArray *data, void (^ack)(NSArray *)) {
         NSLog(@"reconnect \n %@", data);
         [[NSNotificationCenter defaultCenter] postNotificationName:@"Disconnect" object:nil];

         self.easeSocketManager = nil;


     }];

    [self.easeSocketManager on:@"error" callback:^(NSArray *data, void (^ack)(NSArray *))  {
         NSLog(@"error \n %@", data);

     }];

    [self.easeSocketManager on:@"subtask" callback:^(NSArray *data, void (^ack)(NSArray *)){
         NSDictionary *infos = data[0];
         NSLog(@"subtasks \n %@", data);

         [[NSNotificationCenter defaultCenter] postNotificationName:EATaskUpdate object:nil userInfo:infos];

     }];

    [self.easeSocketManager on:@"currentStatus" callback:^(NSArray *data, void (^ack)(NSArray *)){
         NSLog(@"currentStatus \n %@", data);
     }];
}

#pragma mark - WIT



- (void)witProcessed:(NSString *)string completionBlock:(void (^)(NSDictionary *, NSError *))completionBlock {

    if (!string || string.length < 4)
        return;

    //[[Wit sharedInstance] interpretString:string customData:nil];
    NSDictionary *parameters = @{ @"v": witAPIVersion, @"q": string};

    [self.witServerManager GET:@"message" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {

         NSLog(@"Success : %@", responseObject);
         NSDictionary *constraints = [self parseWitDictionary:responseObject];

         completionBlock(constraints, nil);

     } failure:^(NSURLSessionDataTask *task, NSError *error) {
         NSLog(@"Fail : %@", error);

         completionBlock(nil, error);

     }];

}

- (NSDictionary *)parseWitDictionary:(NSDictionary *)witDictionary {
    NSMutableDictionary *dictionary        = [NSMutableDictionary dictionary];
    NSDictionary        *outcomeDictionary = [((NSArray *)witDictionary[@"outcomes"]) firstObject];

    NSString *intent = outcomeDictionary[@"intent"];


    dictionary[@"intent"] = intent;

    NSDictionary *entities = outcomeDictionary[@"entities"];

    if (!entities)
        return nil;


    NSDictionary *dates = ((NSDictionary *)((NSArray *)entities[@"datetime"]).firstObject);

    if (dates) {
        if ([dates[@"type"] isEqualToString:@"value"]) {
            NSString *fromDateString = dates[@"value"];

            NSDate *fromDate = [self witStringToDate:fromDateString];

            NSLog(@"From %@ : %@", fromDateString, fromDate);

            if (fromDate)
                dictionary[@"fromDate"] = fromDate;

        } else {
            NSString *fromDateString = dates[@"from"][@"value"];
            NSString *toDateString   = dates[@"to"][@"value"];

            NSDate *fromDate = [self witStringToDate:fromDateString];
            NSDate *toDate   = [self witStringToDate:toDateString];
            if (fromDate)
                dictionary[@"fromDate"] = fromDate;

            if (toDate)
                dictionary[@"toDate"] = toDate;


            NSLog(@"From %@ : %@\nTo %@ : %@", fromDateString, fromDate, toDateString, toDate);
        }


    }

    NSDictionary *searchQuery = ((NSDictionary *)((NSArray *)entities[@"search_query"]).firstObject);


    if (searchQuery) {

        NSString *search = searchQuery[@"value"];

        dictionary[@"title"] = search;

    }





    return dictionary;

}

- (NSDate *)witStringToDate:(NSString *)dateString {

    return [NSDate dateByParsingJSString:dateString];
}

- (void)witDidGraspIntent:(NSArray *)outcomes messageId:(NSString *)messageId customData:(id)customData error:(NSError *)e {
    NSLog(@"\n%@ \n%@ \n%@ \n%@", outcomes, messageId, customData, e);

}

#pragma mark - Workflow Login


- (void)loginWithUsername:(NSString *)username andPassword:(NSString *)password completionBlock:(void (^) (NSError *error) )completionBlock {



    NSDictionary *parameters = @{@"username": username, @"password" : password};


    self.easeServerManager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];




    [self.easeServerManager POST:@"User/signin" parameters:parameters success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {

         if (responseObject[@"error"]) {
             completionBlock([NSError errorWithDomain:responseObject[@"error"] code:0 userInfo:nil]);
         } else {

             NSHTTPCookie *cookie = [[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/", self.easeServerAdress]]] firstObject];
             NSLog(@"%@", cookie.properties);

             [self setCookie:cookie];
             _currentUser = [[EAUser alloc] init];
             _currentUser.username = responseObject[@"user"][@"username"];
             _currentUser.userID = ((NSNumber *)responseObject[@"user"][@"id"]).intValue;


             [self retrieveUserIngredients:^{
                  completionBlock(nil);

              }];


         }








     } failure:^(NSURLSessionDataTask *task, NSError *error) {

         completionBlock(error);

     }];




}

- (void)logout {
    _currentUser = nil;
    [self.loginViewController logout];
}

- (void)retrieveUserIngredients:(void (^) () )completionBlock {


    [self.easeServerManager GET:@"user/getIngredient" parameters:nil success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {

         if (responseObject[@"error"]) {
             completionBlock([NSError errorWithDomain:responseObject[@"error"] code:0 userInfo:nil]);
         } else {


             for (NSDictionary *ing in responseObject[@"ingredients"]) {

                 EAIngredient *ingredient = [EAIngredient ingredientWithDictionary:ing];
                 [_currentUser.ingredients addObject:ingredient];
             }

             completionBlock(nil);

         }








     } failure:^(NSURLSessionDataTask *task, NSError *error) {

         completionBlock(error);

     }];

}

#pragma mark - Generate Workflows

- (void)searchWorkflowsWithConstraints:(NSDictionary *)constraints completionBlock:(void (^) (int totalNumberOfWorkflows, EASearchResults *searchResults, NSError *error))completionBlock;
{


    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters addEntriesFromDictionary:@{@"intent": constraints[@"intent"]}];

    if (constraints[@"title"])
        [parameters addEntriesFromDictionary:@{@"title": constraints[@"title"]}];

    if (constraints[@"sortBy"])
        [parameters addEntriesFromDictionary:@{@"sortBy": constraints[@"sortBy"]}];


    if (constraints[@"endDate"]) {
        [parameters addEntriesFromDictionary:@{@"time": constraints[@"endDate"]}];
        [parameters addEntriesFromDictionary:@{@"type": @1}];
        [parameters addEntriesFromDictionary:@{@"option": @0}];

    } else if (constraints[@"startDate"]) {
        [parameters addEntriesFromDictionary:@{@"time": constraints[@"startDate"]}];
        [parameters addEntriesFromDictionary:@{@"type": @0}];
        [parameters addEntriesFromDictionary:@{@"option": @1}];
    } else {
        [parameters addEntriesFromDictionary:@{@"time": [NSDate date].description}];
        [parameters addEntriesFromDictionary:@{@"type": @0}];
        [parameters addEntriesFromDictionary:@{@"option": @1}];
    }

    [self.easeServerManager POST:@"workflow/createwf" parameters:parameters success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {

         [EASearchResults searchResultsByParsingGeneratorDictionary:responseObject completion:^(EASearchResults *searchResult) {

              searchResult.constraints = constraints;

              completionBlock(searchResult.workflows.count, searchResult, nil);

          }];



     } failure:^(NSURLSessionDataTask *task, NSError *error) {

         completionBlock(0, nil, error);

     }];




}

- (void)sortWorkflowBy:(NSString *)sortBy completionBlock:(void (^) (EASearchResults *searchResults, NSError *error))completionBlock {
    NSDictionary *parameters = @{@"sortBy": sortBy};

    [self.easeServerManager POST:@"workflow/sortwf" parameters:parameters success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {

         [EASearchResults searchResultsByParsingGeneratorDictionary:responseObject completion:^(EASearchResults *searchResult) {


              completionBlock(searchResult, nil);

          }];



     } failure:^(NSURLSessionDataTask *task, NSError *error) {

         completionBlock(nil, error);

     }];

}

- (void)validateWorkflow:(EAWorkflow *)workflow completionBlock:(void (^)  (NSError *error))completionBlock {

    [self.easeServerManager POST:@"WorkflowGenerator/validate" parameters:@{@"index" : @(workflow.workflowID), @"color" : @(workflow.colorIndex)} success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {


         completionBlock(nil);


     } failure:^(NSURLSessionDataTask *task, NSError *error) {

         completionBlock(error);

     }];

}

- (void)retrieveWorkflowWithID:(int)workflowID completionBlock:(void (^) (EAWorkflow *, int, NSError *error))completionBlock {

    NSDictionary *parameters = @{@"id" : @(workflowID)};

    [self.easeServerManager GET:@"workflow/" parameters:parameters success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {

         EAWorkflow *workflow = [EAWorkflow workflowByParsingSearchDictionary:responseObject completion:^(EAWorkflow *workflow) {
                                     workflow.metaworkflow.imageURL = [NSURL URLWithString:@"http://www.supermarchesmatch.fr/userfiles/images/Poulet%20au%20curry.jpg"];

                                     int metaworkflowID = ((NSNumber *)responseObject[@"metaworkflow"][@"id"]).intValue;
                                     completionBlock(workflow, metaworkflowID, nil);
                                 }];





     } failure:^(NSURLSessionDataTask *task, NSError *error) {
         completionBlock(nil, -1, error);
     }];



}

- (void)retrieveAgentWithID:(int)agentID completionBlock:(void (^) (EAAgent *agent, NSError *error))completionBlock {

    NSDictionary *parameters = @{@"id" : @(agentID)};

    [self.easeServerManager GET:@"agent/" parameters:parameters success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {

         EAAgent *agent = [EAAgent agentByParsingDictionary:responseObject];
         completionBlock(agent, nil);

     } failure:^(NSURLSessionDataTask *task, NSError *error) {
         completionBlock(nil, error);
     }];
}

- (void)retrieveMetaworkflowWithID:(int)metaworkflowID completionBlock:(void (^)(EAMetaworkflow *, NSError *))completionBlock {

    NSDictionary *parameters = @{@"id" : @(metaworkflowID)};

    [self.easeServerManager GET:@"metaworkflow/" parameters:parameters success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {

         EAMetaworkflow *metaworkflow = [EAMetaworkflow metaworkflowByParsingDictionary:responseObject];
         completionBlock(metaworkflow, nil);

     } failure:^(NSURLSessionDataTask *task, NSError *error) {
         completionBlock(nil, error);
     }];

}

- (void)retrieveStartConditionWithID:(int)startConditionID completionBlock:(void (^) (NSDictionary *, NSError *))completionBlock {

    NSDictionary *parameters = @{@"id" : @(startConditionID)};

    [self.easeServerManager GET:@"startcondition/" parameters:parameters success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {
         completionBlock(responseObject, nil);

     } failure:^(NSURLSessionDataTask *task, NSError *error) {
         completionBlock(nil, error);
     }];

}

- (void)retrieveTaskWithID:(int)taskID completionBlock:(void (^) (EATask *task, NSError *error))completionBlock {

    NSDictionary *parameters = @{@"id" : @(taskID)};

    [self.easeServerManager GET:@"startcondition/" parameters:parameters success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {

         [EATask taskByParsingSearchDictionary:responseObject fromWorkflow:nil completion:^(EATask *task) {
              completionBlock(task, nil);

          }];

     } failure:^(NSURLSessionDataTask *task, NSError *error) {
         completionBlock(nil, error);
     }];

}

- (void)retrieveWorkflowIDWithTaskID:(int)taskID completionBlock:(void (^) (int workflowID, NSError *error))completionBlock {

    NSDictionary *parameters = @{@"id" : @(taskID)};

    [self.easeServerManager GET:@"subtask/" parameters:parameters success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {

         completionBlock( ((NSNumber *)responseObject[@"workflow"][@"id"]).intValue, nil);

     } failure:^(NSURLSessionDataTask *task, NSError *error) {
         completionBlock(0, error);
     }];


}

- (void)getPendingTasksCompletionBlock:(void (^) (EASearchResults *searchResults, NSError *error))completionBlock {
    [self.easeServerManager GET:@"workflow/getPendingTask" parameters:nil success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {


         [EASearchResults searchResultsByParsingSearchDictionary:responseObject[@"pending"] completion:^(EASearchResults *searchResult) {

              completionBlock(searchResult, nil);
          }];

     } failure:^(NSURLSessionDataTask *task, NSError *error) {
         completionBlock(nil, error);
     }];
}

- (void)getPendingAndWorkingTasksCompletionBlock:(void (^) (EASearchResults *searchResults, NSError *error))completionBlock {

    [self.easeServerManager GET:@"workflow/getPendingAndWorkingTasks" parameters:nil success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {


         [EASearchResults searchResultsByParsingSearchDictionary:responseObject[@"tasks"] completion:^(EASearchResults *searchResult) {

              completionBlock(searchResult, nil);
          }];

     } failure:^(NSURLSessionDataTask *task, NSError *error) {
         completionBlock(nil, error);
     }];

}

- (void)getWorkingTasksCompletionBlock:(void (^) (EASearchResults *searchResults, NSError *error))completionBlock {
    [self.easeServerManager GET:@"workflow/getWorkingTask" parameters:nil success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {


         [EASearchResults searchResultsByParsingSearchDictionary:responseObject[@"working"] completion:^(EASearchResults *searchResult) {

              completionBlock(searchResult, nil);
          }];

     } failure:^(NSURLSessionDataTask *task, NSError *error) {
         completionBlock(nil, error);
     }];
}

- (void)getNumberOfPendingTasks:(void (^) (int nb, NSError *error))completionBlock {
    [self.easeServerManager GET:@"workflow/getPendingTask" parameters:nil success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {

         completionBlock(((NSArray *)responseObject[@"pending"]).count, nil);


     } failure:^(NSURLSessionDataTask *task, NSError *error) {
         completionBlock(0, error);
     }];
}

- (void)getNumberOfWorkingTasks:(void (^) (int nb, NSError *error))completionBlock {
    [self.easeServerManager GET:@"workflow/getWorkingTask" parameters:nil success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {

         completionBlock(((NSArray *)responseObject[@"working"]).count, nil);


     } failure:^(NSURLSessionDataTask *task, NSError *error) {
         completionBlock(0, error);
     }];
}

- (void)tasksAtDay:(NSDate *)date completionBlock:(void (^) (EASearchResults *, NSError *))completionBlock {

    NSDictionary *parameters = @{@"day" : date.description};

    [self.easeServerManager POST:@"subtask/getSubtasksAtDay" parameters:parameters success:^(NSURLSessionDataTask *task, NSArray *responseObject) {

         if (responseObject.count == 0)
             completionBlock(nil, nil);



         [EASearchResults searchResultsByParsingSearchDictionary:responseObject completion:^(EASearchResults *searchResult) {
              completionBlock(searchResult, nil);
          }];


     } failure:^(NSURLSessionDataTask *task, NSError *error) {



     }];
}

- (void)startTask:(EATask *)task completionBlock:(void (^) (NSError *error))completionBlock {

    if (task.status != EATaskStatusPending)
        completionBlock([NSError errorWithDomain:@"Task Pending" code:0 userInfo:nil]);

    [self.easeSocketManager emitWithAck:@"post" withItems:@[@{@"url" : @"/subtask/start", @"data" : @{ @"id" : @(task.taskID) }}]] (0, ^(NSArray *data) {
        NSLog(@"%@", data);

        completionBlock(nil);
    });


}

- (void)finishTask:(EATask *)task completionBlock:(void (^) (NSError *error))completionBlock {

    if (task.status != EATaskStatusWorking)
        completionBlock([NSError errorWithDomain:@"Task Working" code:0 userInfo:nil]);

    [self.easeSocketManager emitWithAck:@"post" withItems:@[@{@"url" : @"/subtask/finish", @"data" : @{ @"subTask" : @(task.taskID) }}]] (0, ^(NSArray *data) {
        NSLog(@"%@", data);

        completionBlock(nil);
    });


}

@end
