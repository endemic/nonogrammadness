//
//  UpgradeScene.m
//  nonogrammadness
//
//  Created by Nathan Demick on 9/16/11.
//  Copyright 2011 Ganbaru Games. All rights reserved.
//

#import "UpgradeScene.h"
#import "LevelSelectScene.h"

#import "GameSingleton.h"
#import "SimpleAudioEngine.h"

@implementation UpgradeScene

+ (CCScene *)scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	UpgradeScene *layer = [UpgradeScene node];
	
	// add layer as a child to scene
	[scene addChild:layer];
	
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
		CCSprite *title = [CCSprite spriteWithFile:[NSString stringWithFormat:@"thanks-title%@.png", hdSuffix]];
		title.position = ccp(windowSize.width / 2, windowSize.height - title.contentSize.height * 2);
		[self addChild:title z:1];
		
		// create and initialize a Label
		CCLabelTTF *label = [CCLabelTTF labelWithString:@"I hope you enjoyed this lite version of Nonogram Madness.\n\nGet the full version for:\n\t* 100 more puzzles to solve\n\t* Randomly generated puzzles\n\t* Game Center achievements" dimensions:CGSizeMake(windowSize.width - (20 * fontMultiplier), 175 * fontMultiplier) alignment:CCTextAlignmentLeft fontName:@"pf_westa_seven.ttf" fontSize:14 * fontMultiplier];
		label.color = ccc3(255, 255, 255);
		label.position = ccp(windowSize.width / 2, title.position.y - label.contentSize.height / 1.35);
		[self addChild:label z:1];
		
		// Create "Buy Now" button
		CCMenuItemImage *buyButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"buy-now-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"buy-now-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
			
			// Create "go to App Store?" alert
			UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Go to App Store?"
																 message:@""
																delegate:self
													   cancelButtonTitle:@"Cancel"
													   otherButtonTitles:@"Go", nil] autorelease];
			[alertView show];
		}];
		
		// Create "No thanks" button
		CCMenuItemImage *noThanksButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"no-thanks-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"no-thanks-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
			
			// Go back to level select
			CCTransitionTurnOffTiles *transition = [CCTransitionTurnOffTiles transitionWithDuration:0.5 scene:[LevelSelectScene node]];
			[[CCDirector sharedDirector] replaceScene:transition];
		}];
		
		CCMenu *iTunesMenu = [CCMenu menuWithItems:buyButton, noThanksButton, nil];
		[iTunesMenu alignItemsVerticallyWithPadding:11];
		iTunesMenu.position = ccp(windowSize.width / 2, buyButton.contentSize.height * 2);
		[self addChild:iTunesMenu z:1];
	}
	return self;
}

/**
 * Handle clicking of the alert view
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
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
			// they want to buy it - itms-apps://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftwareUpdate?id=[APPID]&mt=8
			//[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=386461624"]];
			[self openReferralURL:[NSURL URLWithString:@"http://click.linksynergy.com/fs-bin/stat?id=0VdnAOV054A&offerid=146261&type=3&subid=0&tmpid=1826&RD_PARM1=http%253A%252F%252Fitunes.apple.com%252Fus%252Fapp%252Fnonogram-madness%252Fid386461624%253Fmt%253D8%2526uo%253D4%2526partnerId%253D30"]];
#endif
			break;
		default:
			break;
	}
}

// Process a LinkShare/TradeDoubler/DGM URL to something iPhone can handle
- (void)openReferralURL:(NSURL *)referralURL 
{
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:referralURL] delegate:self startImmediately:YES];
    [conn release];
}

// Save the most recent URL in case multiple redirects occur
// "iTunesURL" is an NSURL property in your class declaration
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response 
{
    iTunesURL = [response URL];
    return request;
}

// No more redirects; use the last URL saved
- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
    [[UIApplication sharedApplication] openURL:iTunesURL];
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
