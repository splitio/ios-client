//
//  GetTreatmentsViewController.m
//  ExampleObjc
//
//  Created by Javier L. Avrudsky on 27/11/2018.
//  Copyright © 2018 Split Software. All rights reserved.
//

#import "GetTreatmentsViewController.h"
@import Split;

@interface GetTreatmentsViewController ()

@property (weak, nonatomic) IBOutlet UITextField *splitsField;
@property (weak, nonatomic) IBOutlet UITextField *matchingKeyField;
@property (weak, nonatomic) IBOutlet UITextField *bucketingKeyField;
@property (weak, nonatomic) IBOutlet UITextField *attributesField;

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (weak, nonatomic) IBOutlet UIButton *evaluateButton;

@end

@implementation GetTreatmentsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)evaluateDidTouch:(UIButton *)sender {
    
    NSString *apiKey = @"YOUR_API_KEY";
    NSString *splitName = self.splitsField.text;
    NSString *matchingKey = self.matchingKeyField.text;
    
    // Split Config
    SplitClientConfig *config = [[SplitClientConfig alloc] init];
    config.featuresRefreshRate = 30;
    config.segmentsRefreshRate = 30;
    config.impressionRefreshRate = 30;
    config.sdkReadyTimeOut = 15000;
    config.connectionTimeout = 50;
    
    //User Key
    Key *key = [[Key alloc] initWithMatchingKey:matchingKey bucketingKey:nil];
    
    //Split Factory
    SplitFactory *factory = [[SplitFactory alloc] initWithApiKey: apiKey key: key config: config];
    
    //Showing sdk version in UI
    self.versionLabel.text = [factory version];
    
    //Split Client
    id<SplitClientProtocol> client = [factory client];
    
    [client onEvent: SplitEventSdkReady execute: ^(){
        NSDictionary *attributes = [self convertToDictionary:self.attributesField.text];
        self.resultLabel.text = [client getTreatment:splitName attributes: attributes];
        
        if(![[self.splitsField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] isEqualToString:@""]){
            NSArray *splits = [self.splitsField.text componentsSeparatedByString:@","];
            NSDictionary *result = [client getTreatmentsForSplits:splits attributes:attributes];
            self.resultLabel.text = [self convertToJsonString:result];
        }
    }];
    
    [client onEvent: SplitEventSdkReadyTimedOut execute: ^(){
        self.resultLabel.text = @"SDK Time Out";
    }];
}

- ( NSDictionary* _Nullable ) convertToDictionary:(NSString*) text {
    NSData *data = [text dataUsingEncoding: kCFStringEncodingUTF8];
    if( data == nil) return nil;
    NSError *error = nil;
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if(error != nil) {
        NSLog(@"Error parsing attributes: %@", error.localizedDescription);
        return nil;
    }
    return jsonObject;
}

- (NSString*) convertToJsonString:(NSDictionary*) jsonObject {
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options: NSJSONWritingSortedKeys error:&error];
    
    if(error != nil){
        return error.localizedDescription;
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
