//
//  TrackViewController.m
//  ExampleObjc
//
//  Created by Javier L. Avrudsky on 03/12/2018.
//  Copyright © 2018 Split Software. All rights reserved.
//

#import "TrackViewController.h"
@import Split;

@interface TrackViewController ()

@property (weak, nonatomic) IBOutlet UITextField *trafficTypeField;
@property (weak, nonatomic) IBOutlet UITextField *eventTypeField;
@property (weak, nonatomic) IBOutlet UITextField *valueField;

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (weak, nonatomic) IBOutlet UIButton *trackButton;

@property (strong, nonatomic) id<SplitClient> client;

@end

@implementation TrackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)trackDidTouch:(UIButton *)sender {
    if(self.client == nil) {
        [self initClient];
    }
    [self sendEvent];
}

- (void) initClient {
    
    NSString *apiKey = @"YOUR_API_KEY";
    NSString *matchingKey = @"SAMPLE_ID_1";
    
    // Split Config
    SplitClientConfig *config = [[SplitClientConfig alloc] init];
    config.featuresRefreshRate = 30;
    config.segmentsRefreshRate = 30;
    config.impressionRefreshRate = 30;
    config.sdkReadyTimeOut = 15000;
    config.connectionTimeout = 50;
    
    // Track config
    config.eventsPushRate = 10;
    config.eventsPerPush = 2000;
    config.eventsQueueSize = 10000;
    config.eventsFirstPushWindow = 10;
    config.trafficType = @"custom";
    
    //User Key
    Key *key = [[Key alloc] initWithMatchingKey:matchingKey bucketingKey:nil];
    
    //Split Factory
    id<SplitFactoryBuilder> builder = [[DefaultSplitFactoryBuilder alloc] init];
    [builder setApiKey: apiKey];
    [builder setKey: key];
    [builder setConfig: config];
    
    id<SplitFactory> factory = [builder build];
    
    //Showing sdk version in UI
    self.versionLabel.text = factory.version;
    
    //Split Client
    id<SplitClient> client = factory.client;
}

- (void) sendEvent {
    
    if (self.client == nil) {
        return;
    }
    
    if ([self isEmpty: self.eventTypeField]) {
        self.resultLabel.text = @"Event Type should not be empty";
    } else if( ![self isEmpty: self.valueField] && [self stringToNumber: self.valueField.text] == nil) {
        self.resultLabel.text = @"Value field is not valid";
    } else if( [self isEmpty: self.trafficTypeField] && [self isEmpty: self.valueField]) {
        [self showResult: [self.client trackWithEventType: self.trafficTypeField.text]];
    } else if( [self isEmpty:self.trafficTypeField]) {
        double value = [[self stringToNumber: self.valueField.text] doubleValue];
        [self showResult:[self.client trackWithEventType:self.eventTypeField.text value: value]];
    } else if([self isEmpty:self.valueField]) {
        [self showResult:[self.client trackWithTrafficType: self.trafficTypeField.text eventType: self.eventTypeField.text]];
    } else {
        double value = [[self stringToNumber: self.valueField.text] doubleValue];
        [self showResult:[self.client trackWithTrafficType: self.trafficTypeField.text eventType: self.eventTypeField.text value: value]];
    }
}

- (bool) isEmpty: (UITextField*) textField {
    return textField.text == nil || [[textField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] isEqualToString:@""];
}

- (void) showResult:(bool) result {
    self.resultLabel.text = (result ? @"Success" : @"Failure");
}

- (NSNumber* _Nullable) stringToNumber:(NSString*)stringNumber {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    return [formatter numberFromString:stringNumber];
}

@end
