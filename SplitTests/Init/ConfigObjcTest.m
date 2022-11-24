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

- (void)testInvalid {
    SplitClientConfig* config = [[SplitClientConfig alloc] init];
    config.userConsent = @"pepe";

    XCTAssertEqualObjects(@"GRANTED", config.userConsent);
}

- (void)testGranted {
    SplitClientConfig* config = [[SplitClientConfig alloc] init];
    config.userConsent = @"granteD";

    XCTAssertEqualObjects(@"GRANTED", config.userConsent);
}

- (void)testDeclined {
    SplitClientConfig* config = [[SplitClientConfig alloc] init];
    config.userConsent = @"decLined";

    XCTAssertEqualObjects(@"DECLINED", config.userConsent);
}

- (void)testUnknown {
    SplitClientConfig* config = [[SplitClientConfig alloc] init];
    config.userConsent = @"unknOWn";

    XCTAssertEqualObjects(@"UNKNOWN", config.userConsent);
}

@end
