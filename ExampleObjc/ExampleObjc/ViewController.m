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
    NSString *apiKey = @"YOUR_API_KEY";
    SplitClientConfig *config = [[SplitClientConfig alloc] init];
    //Key *key = [[Key alloc] initWithMatchingKey:@"CUSTOMER_ID"];
    Key *key = [[Key alloc] initMatchingKey:<#(NSString * _Nonnull)#> bucketingKey:<#(NSString * _Nullable)#>
    [key pepe];
                SplitFactory *factory = [[SplitFactory alloc] initWithApiKey: apiKey key: key config: config];
                SplitClientProtocol *client = [factory getClient];
                NSString * treatment = [client getTreatment:@"SPLIT_NAME"];
                
                if treatment == "on" {
                    // insert code here to show on treatment
                } else if treatment == "off" {
                    // insert code here to show off treatment
                } else {
                    // insert your control treatment code here
                }
}


@end
