//
//  GameSingleton.m
//
//  Created by Nathan Demick on 6/11/11.
//  Copyright 2011 Ganbaru Games. All rights reserved.
//

#import "SynthesizeSingleton.h"
#import "GameSingleton.h"

@implementation GameSingleton

@synthesize level, isPad, isRetina, hasGameCenter, unsentScores, unsentAchievements, achievementsDictionary;

SYNTHESIZE_SINGLETON_FOR_CLASS(GameSingleton);

- (id)init 
{
	if ((self = [super init]))
	{
		// Check if running on iPad
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		{
			isPad = YES;
		}
		else
		{
			isPad = NO;
		}
		
		// Check if Game Center exists
		if ([self isGameCenterAPIAvailable])
		{
			hasGameCenter = YES;
		}
		else
		{
			hasGameCenter = NO;
		}
		
		// Create the "unsentScores" array if it doesn't exist (e.g. first run)
		if (unsentScores == nil)
		{
			unsentScores = [[NSMutableArray alloc] init];
		}
		
		// Create the "unsentAchievements" array if it doesn't exist (e.g. first run)
		if (unsentAchievements == nil)
		{
			unsentAchievements = [[NSMutableArray alloc] init];
		}
		
		// Create the "achievementsDictionary" array if it doesn't exist (e.g. first run)
		if (achievementsDictionary == nil)
		{
			achievementsDictionary = [[NSMutableDictionary alloc] init];
		}
		
		// Set the "isRetina" flag to "no" by default
		isRetina = NO;
	}
	return self;
}

#pragma mark -
#pragma mark Game Center methods

- (BOOL)isGameCenterAPIAvailable
{
	// Check for presence of GKLocalPlayer class
	BOOL localPlayerClassAvailable = (NSClassFromString(@"GKLocalPlayer")) != nil;
	
	// Device must be running 4.1 or later
	NSString *reqSysVer = @"4.1";
	NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
	BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
	
	return (localPlayerClassAvailable && osVersionSupported);
}

- (void)authenticateLocalPlayer
{
	if ([self isGameCenterAPIAvailable])
	{
		GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
		[localPlayer authenticateWithCompletionHandler:^(NSError *error) {
			if (localPlayer.isAuthenticated)
			{
				// Perform additional tasks for the authenticated player
				hasGameCenter = YES;
				
				// Load player achievements
				[GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error) {
					if (error != nil)
					{
						// handle errors
					}
					if (achievements != nil)
					{
						// process array of achievements
						for (GKAchievement* achievement in achievements)
							[achievementsDictionary setObject:achievement forKey:achievement.identifier];
					}
				}];
				
				// If unsent scores array has length > 0, try to send saved scores here
				if ([unsentScores count] > 0)
				{
					// Create new array to help remove successfully sent scores
					NSMutableArray *removedScores = [NSMutableArray array];
					
					for (GKScore *score in unsentScores)
					{
						[score reportScoreWithCompletionHandler:^(NSError *error) {
							if (error != nil)
							{
								// If there's an error reporting the score (again!), leave the score in the array
							}
							else
							{
								// If success, remove that obj
								[removedScores addObject:score];
							}
						}];
					}
					
					// Remove successfully sent scores from stored array
					[unsentScores removeObjectsInArray:removedScores];
				}
				
				// If unsent achievements array has length > 0, try to send saved achievement progress here
				if ([unsentAchievements count] > 0)
				{
					// Create new array to help remove successfully sent achievements
					NSMutableArray *removedAchievements = [NSMutableArray array];
					
					for (GKAchievement *achievement in unsentAchievements)
					{
						[achievement reportAchievementWithCompletionHandler:^(NSError *error)
						 {
							 if (error != nil)
							 {
								 // If there's an error reporting the achievement (again!), leave the achievement in the array
							 }
							 else
							 {
								 // Otherwise, add the achievement object into the array of achievements to remove
								 [removedAchievements addObject:achievement];
							 }
						 }];
					}
					
					// Remove successfully sent achievements from stored array
					[unsentAchievements removeObjectsInArray:removedAchievements];
				}
			}
			else
			{
				// Disable Game Center
				hasGameCenter = NO;
			}
		}];
	}
}

#pragma mark -
#pragma mark Leaderboards

- (void)reportScore:(int64_t)score forCategory:(NSString *)category
{
	if (hasGameCenter)
	{
		GKScore *scoreReporter = [[[GKScore alloc] initWithCategory:category] autorelease];
		scoreReporter.value = score;
		
		//NSLog(@"Trying to send score %lld for category %@", score, category);
		
		[scoreReporter reportScoreWithCompletionHandler:^(NSError *error) {
			if (error != nil)
			{
				// Handle reporting error here by adding object to a serializable array, to be sent again later
				[unsentScores addObject:scoreReporter];
				
				NSLog(@"Error sending score!");
			}
		}];
	}
}

- (void)showLeaderboardForCategory:(NSString *)category
{
	if (hasGameCenter)
	{
		GKLeaderboardViewController *leaderboardController = [[GKLeaderboardViewController alloc] init];
		if (leaderboardController != nil)
		{
			// Leaderboard config
			leaderboardController.leaderboardDelegate = self;	// The leaderboard view controller will send messages to this object
			leaderboardController.category = category;	// Set category here
			leaderboardController.timeScope = GKLeaderboardTimeScopeToday;	// GKLeaderboardTimeScopeToday, GKLeaderboardTimeScopeWeek, GKLeaderboardTimeScopeAllTime
			
			// Create an additional UIViewController to attach the GKLeaderboardViewController to
			myViewController = [[UIViewController alloc] init];
			
			// Add the temporary UIViewController to the main OpenGL view
			[[[CCDirector sharedDirector] openGLView] addSubview:myViewController.view];
			
			// Tell UIViewController to present the leaderboard
			[myViewController presentModalViewController:leaderboardController animated:YES];
		}
	}
}

/**
 * Dismiss an active GKLeaderboardViewController
 */
- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	[myViewController dismissModalViewControllerAnimated:YES];
	[myViewController release];
}

#pragma mark -
#pragma mark Achievements

/**
 * Get an achievement object in the locally stored dictionary
 */
- (GKAchievement *)getAchievementForIdentifier:(NSString *)identifier
{
	if (hasGameCenter)
	{
		GKAchievement *achievement = [achievementsDictionary objectForKey:identifier];
		if (achievement == nil)
		{
			achievement = [[[GKAchievement alloc] initWithIdentifier:identifier] autorelease];
			[achievementsDictionary setObject:achievement forKey:achievement.identifier];
		}
		return [[achievement retain] autorelease];
	}
	return nil;
}

/**
 * Send a completion % for a specific achievement to Game Center
 */
- (void)reportAchievementIdentifier:(NSString *)identifier percentComplete:(float)percent
{
	if (hasGameCenter)
	{
		// Instantiate GKAchievement object for an achievement (set up in iTunes Connect)
		GKAchievement *achievement = [self getAchievementForIdentifier:identifier];
		if (achievement)
		{
			achievement.percentComplete = percent;
			[achievement reportAchievementWithCompletionHandler:^(NSError *error)
			{
				if (error != nil)
				{
					// Retain the achievement object and try again later
					[unsentAchievements addObject:achievement];

					NSLog(@"Error sending achievement!");
				}
			}];
		}
	}
}

/**
 * Send a completion % for a specific achievement to Game Center - increments an existing achievement object
 */
- (void)reportAchievementIdentifier:(NSString *)identifier incrementPercentComplete:(float)percent
{
	if (hasGameCenter)
	{
		// Instantiate GKAchievement object for an achievement (set up in iTunes Connect)
		GKAchievement *achievement = [self getAchievementForIdentifier:identifier];
		if (achievement)
		{
			achievement.percentComplete += percent;
			[achievement reportAchievementWithCompletionHandler:^(NSError *error)
			 {
				 if (error != nil)
				 {
					 // Retain the achievement object and try again later
					 [unsentAchievements addObject:achievement];
					 
					 NSLog(@"Error sending achievement!");
				 }
			 }];
		}
	}
}

/**
 * Create a GKAchievementViewController and display it on top of cocos2d's OpenGL view
 */
- (void)showAchievements
{
	if (hasGameCenter)
	{
		GKAchievementViewController *achievements = [[GKAchievementViewController alloc] init];
		if (achievements != nil)
		{
			achievements.achievementDelegate = self;
			
			// Create an additional UIViewController to attach the GKAchievementViewController to
			myViewController = [[UIViewController alloc] init];
			
			// Add the temporary UIViewController to the main OpenGL view
			[[[CCDirector sharedDirector] openGLView] addSubview:myViewController.view];
			
			[myViewController presentModalViewController:achievements animated:YES];
		}
		[achievements release];
	}
}

/**
 * Dismiss an active GKAchievementViewController
 */
- (void)achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
	[myViewController dismissModalViewControllerAnimated:YES];
	[myViewController release];
}

#pragma mark -
#pragma mark Object Serialization

+ (void)loadState
{
	@synchronized([GameSingleton class]) 
	{
		// just in case loadState is called before GameSingleton inits
		if(!sharedGameSingleton)
			[GameSingleton sharedGameSingleton];

		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		// NSString *file = [documentsDirectory stringByAppendingPathComponent:kSaveFileName];
		NSString *file = [documentsDirectory stringByAppendingPathComponent:@"GameSingleton.bin"];
		Boolean saveFileExists = [[NSFileManager defaultManager] fileExistsAtPath:file];
		
		if(saveFileExists) 
		{
			// don't need to set the result to anything here since we're just getting initwithCoder to be called.
			// if you try to overwrite sharedGameSingleton here, an assert will be thrown.
			[NSKeyedUnarchiver unarchiveObjectWithFile:file];
		}
	}
}

+ (void)saveState
{
	@synchronized([GameSingleton class]) 
	{  
		GameSingleton *state = [GameSingleton sharedGameSingleton];

		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		// NSString *saveFile = [documentsDirectory stringByAppendingPathComponent:kSaveFileName];
		NSString *saveFile = [documentsDirectory stringByAppendingPathComponent:@"GameSingleton.bin"];
		
		[NSKeyedArchiver archiveRootObject:state toFile:saveFile];
	}
}

#pragma mark -
#pragma mark NSCoding Protocol Methods

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.unsentScores forKey:@"unsentScores"];
	[coder encodeObject:self.unsentAchievements forKey:@"unsentAchievements"];
	[coder encodeInt:self.level forKey:@"level"];
}

- (id)initWithCoder:(NSCoder *)coder
{
	if ((self = [super init])) 
	{
		self.unsentScores = [coder decodeObjectForKey:@"unsentScores"];
		self.unsentAchievements = [coder decodeObjectForKey:@"unsentAchievements"];
		self.level = [coder decodeIntForKey:@"level"];
	}
	return self;
}

@end
