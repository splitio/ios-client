//
//  ViewController.m
//  ExampleObjc
//
//  Created by Javier L. Avrudsky on 27/11/2018.
//  Copyright © 2018 Split Software. All rights reserved.
//

#import "ViewController.h"
@import Split;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSString *apiKey = @"4eri39qiou5ene271kpk1tnlfnfvid89dgab";
    NSString *matchingKey = @"fake_id_1";
    
    SplitClientConfig *config = [[SplitClientConfig alloc] init];
    //Key *key = [[Key alloc] initWithMatchingKey:@"CUSTOMER_ID"];
    Key *key = [[Key alloc] initWithMatchingKey:matchingKey bucketingKey:nil];
    SplitFactory *factory = [[SplitFactory alloc] initWithApiKey: apiKey key: key config: config];
    id<SplitClientProtocol> client = [factory client];
    NSString * treatment = [client getTreatment:@"SPLIT_NAME"];
    config.targetSdkEndPoint = @"https://sdk.split-stage.io/api";
    config.targetEventsEndPoint = @"https://events.split-stage.io/api";

    
    if ([treatment  isEqual: @"on"]) {
        // insert code here to show on treatment
    } else if([treatment  isEqual: @"off"]) {
        // insert code here to show off treatment
    } else {
        // insert your control treatment code here
    }
}


@end
