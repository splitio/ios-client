//
//  ConfigObjcTest.m
//  SplitTests
//
//  Created by Javier Avrudsky on 24-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

#import <XCTest/XCTest.h>
@import Split;
@interface ConfigObjcTest : XCTestCase

@end

@implementation ConfigObjcTest


// MARK: User Consent
- (void)testUserConsentInvalid {
    SplitClientConfig* config = [[SplitClientConfig alloc] init];
    config.userConsent = @"pepe";

    XCTAssertEqualObjects(@"GRANTED", config.userConsent);
}

- (void)testUserConsentGranted {
    SplitClientConfig* config = [[SplitClientConfig alloc] init];
    config.userConsent = @"granteD";

    XCTAssertEqualObjects(@"GRANTED", config.userConsent);
}

- (void)testUserConsentDeclined {
    SplitClientConfig* config = [[SplitClientConfig alloc] init];
    config.userConsent = @"decLined";

    XCTAssertEqualObjects(@"DECLINED", config.userConsent);
}

- (void)testUserConsentUnknown {
    SplitClientConfig* config = [[SplitClientConfig alloc] init];
    config.userConsent = @"unknOWn";

    XCTAssertEqualObjects(@"UNKNOWN", config.userConsent);
}


// MARK: Impressions mode
- (void)testImpressionsModeInvalid {
    SplitClientConfig* config = [[SplitClientConfig alloc] init];
    config.impressionsMode = @"pepe";

    XCTAssertEqualObjects(@"OPTIMIZED", config.impressionsMode);
}

- (void)testImpressionsModeOptimized {
    SplitClientConfig* config = [[SplitClientConfig alloc] init];
    config.impressionsMode = @"optimized";

    XCTAssertEqualObjects(@"OPTIMIZED", config.impressionsMode);
}

- (void)testImpressionsModedebug {
    SplitClientConfig* config = [[SplitClientConfig alloc] init];
    config.impressionsMode = @"debug";

    XCTAssertEqualObjects(@"DEBUG", config.impressionsMode);
}

- (void)testImpressionsModenone {
    SplitClientConfig* config = [[SplitClientConfig alloc] init];
    config.impressionsMode = @"none";

    XCTAssertEqualObjects(@"NONE", config.impressionsMode);
}
@end
