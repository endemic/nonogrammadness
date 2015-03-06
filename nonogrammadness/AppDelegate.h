//
//  AppDelegate.h
//  nonogrammadness
//
//  Created by Nathan Demick on 8/31/11.
//  Copyright Ganbaru Games 2011. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow			*window;
	RootViewController	*viewController;
}

@property (nonatomic, retain) UIWindow *window;

@end
