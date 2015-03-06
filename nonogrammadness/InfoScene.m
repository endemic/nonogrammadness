//
//  InfoScene.m
//  nonogrammadness
//
//  Created by Nathan Demick on 8/31/11.
//  Copyright 2011 Ganbaru Games. All rights reserved.
//

#import "InfoScene.h"
#import "TitleScene.h"

#import "GameSingleton.h"
#import "SimpleAudioEngine.h"

@implementation InfoScene

+ (CCScene *)scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	InfoScene *layer = [InfoScene node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
- (id)init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if ((self = [super init]))
	{
		// ask director the the window size
		CGSize windowSize = [CCDirector sharedDirector].winSize;
		
		// This string gets appended onto all image filenames based on whether the game is on iPad or not
		if ([GameSingleton sharedGameSingleton].isPad)
		{
			hdSuffix = @"-hd";
			fontMultiplier = 2;
		}
		else
		{
			hdSuffix = @"";
			fontMultiplier = 1;
		}
		
		// Create/add background
		CCSprite *bg = [CCSprite spriteWithFile:[NSString stringWithFormat:@"background%@.png", hdSuffix]];
		bg.position = ccp(windowSize.width / 2, windowSize.height / 2);
		[self addChild:bg z:0];
		
		// Create/add title
		CCSprite *title = [CCSprite spriteWithFile:[NSString stringWithFormat:@"info-title%@.png", hdSuffix]];
		title.position = ccp(windowSize.width / 2, windowSize.height - title.contentSize.height * 2);
		[self addChild:title z:1];
		
		// create and initialize a Label
		CCLabelTTF *label = [CCLabelTTF labelWithString:@"Designed and programmed\nby Nathan Demick" dimensions:CGSizeMake(windowSize.width, 100 * fontMultiplier) alignment:CCTextAlignmentCenter fontName:@"pf_westa_seven.ttf" fontSize:14 * fontMultiplier];
		label.color = ccc3(255, 255, 255);
		label.position = ccp(windowSize.width / 2, title.position.y - label.contentSize.height);
		[self addChild:label z:1];
		
		// Create "rate on App Store" button
		CCMenuItemImage *rateButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"rate-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"rate-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
			
			// Create "go to App Store?" alert
			UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Rate on App Store?"
																 message:@"I appreciate your feedback. Thanks for playing my game!"
																delegate:self
													   cancelButtonTitle:@"Cancel"
													   otherButtonTitles:@"Rate", nil] autorelease];
			[alertView setTag:1];
			[alertView show];
		}];
		
		// Create "more games" button
		CCMenuItemImage *moreGamesButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"more-games-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"more-games-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
			
			// Create "go to App Store?" alert
			UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Go to App Store?"
																 message:@"Check my other games!"
																delegate:self
													   cancelButtonTitle:@"Cancel"
													   otherButtonTitles:@"Go", nil] autorelease];
			[alertView setTag:2];
			[alertView show];
		}];
		
		CCMenu *iTunesMenu = [CCMenu menuWithItems:rateButton, moreGamesButton, nil];
		[iTunesMenu alignItemsVerticallyWithPadding:11];
		iTunesMenu.position = ccp(windowSize.width / 2, rateButton.contentSize.height * 2);
		[self addChild:iTunesMenu z:1];
		
		// Create back button/menu
		CCMenuItemImage *backButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"back-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"back-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play sound effect
			[[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
			
			// Transition to title screen
			CCTransitionTurnOffTiles *transition = [CCTransitionTurnOffTiles transitionWithDuration:0.5 scene:[TitleScene node]];
			[[CCDirector sharedDirector] replaceScene:transition];
		}];
		
		CCMenu *topMenu = [CCMenu menuWithItems:backButton, nil];
		topMenu.position = ccp(backButton.contentSize.width / 1.5, windowSize.height - backButton.contentSize.height);
		[self addChild:topMenu z:1];
	}
	return self;
}

/**
 * Handle clicking of the alert view
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// "Rate" alert
	if (alertView.tag == 1)
	{
		switch (buttonIndex) 
		{
			case 0:
				// Do nothing - dismiss
				break;
			case 1:
#if TARGET_IPHONE_SIMULATOR
				CCLOG(@"App Store is not supported on the iOS simulator. Unable to open App Store page.");
#else
				// they want to rate it
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=467395560"]];
#endif
				break;
			default:
				break;
		}
	}
	// "More games" alert
	else if (alertView.tag == 2)
	{
		switch (buttonIndex) 
		{
			case 0:
				// Do nothing - dismiss
				break;
			case 1:
#if TARGET_IPHONE_SIMULATOR
				CCLOG(@"App Store is not supported on the iOS simulator. Unable to open App Store page.");
#else
				// they want to see more games
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.com/apps/ganbarugames"]];
#endif
				break;
			default:
				break;
		}
	}
}

// on "dealloc" you need to release all your retained objects
- (void)dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
