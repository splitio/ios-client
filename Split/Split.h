//
//  Split.h
//  Split
//
//  Created by Javier L. Avrudsky on 7/2/18.
//  Copyright © 2018 Split. All rights reserved.
//

#include <TargetConditionals.h>

#if TARGET_OS_IPHONE
    @import UIKit;
#else
    @import AppKit;
#endif

//! Project version number for Split.
FOUNDATION_EXPORT double SplitVersionNumber;

//! Project version string for Split.
FOUNDATION_EXPORT const unsigned char SplitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Split/PublicHeader.h>
