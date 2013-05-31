//
//  AppDelegate.m
//  FlexibleView2
//
//  Created by lishuo on 05/28/13.
//  Copyright (c) 2013 lishuo. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import "AppDelegate.h"
#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "FVDeclaration.h"
@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    FVViewCreateBlock space = ^(NSDictionary *context){
        UIView *space = [[UIView alloc] init];
        return space;
    };

    FVDeclareTemplateBlock template = ^{
        return [[FVDeclaration declaration:@"NavigationBar" frame:CGRectMake(0, 0, FVP(1), 44)] withDeclarations:@[
            [FVDeclaration declaration:@"MenuButton" frame:CGRectMake(0, 0, 44, FVP(1))],
            [FVDeclaration declaration:@"ComposeButton" frame:CGRectMake(FVT(44), 0, 44, FVP(1))],]];
    };

    FVDeclaration *root = [[FVDeclaration declaration:@"root" frame:CGRectMake(0, 0, self.window.screen.bounds.size.width, self.window.screen.bounds.size.height - 30)] withDeclarations:@[
        template(),
        [[FVDeclaration declaration:@"ContentView" frame:CGRectMake(0, 44, FVP(1), FVFill)] withDeclarations:@[
            [FVDeclaration declaration:@"percent50" frame:CGRectMake(0, 0, FVP(0.5), 44)],
            [FVDeclaration declaration:@"percentOther50" frame:CGRectMake(0, 0, FVP(0.5), FVSameAsPrev)],

            [FVDeclaration declaration:@"fillLeft" frame:CGRectMake(0, 44, 44, FVSameAsPrev)],
            [FVDeclaration declaration:@"fill" frame:CGRectMake(FVAfter, 44, FVFill, FVSameAsPrev)], //the fill's width should be 1000-44*2
            [FVDeclaration declaration:@"fillRight" frame:CGRectMake(FVT(44), 44, 44, FVSameAsPrev)],

            [FVDeclaration declaration:@"followLeft" frame:CGRectMake(0, 44 * 2, 44, FVSameAsPrev)],
            [FVDeclaration declaration:@"follow1" frame:CGRectMake(FVAfter, 44 * 2, 44, FVSameAsPrev)],
            [FVDeclaration declaration:@"follow2" frame:CGRectMake(FVAfter, 44 * 2, 44, 44)],

            //Add one space here
            [[FVDeclaration declaration:@"space" frame:CGRectMake(0, FVAfter, FVFill, 30)] assignObject:space(nil)],

            [[FVDeclaration declaration:@"auto" frame:CGRectMake(0, FVAfter, FVAuto, FVAuto)] withDeclarations:@[
                [FVDeclaration declaration:@"auto1" frame:CGRectMake(10, 0, 44, 44)],
                [FVDeclaration declaration:@"auto2" frame:CGRectMake(FVAfter, FVAfter, 44, 44)],
                [FVDeclaration declaration:@"auto3" frame:CGRectMake(FVAfter, FVAfter, 44, 44)],
                [FVDeclaration declaration:@"auto4" frame:CGRectMake(FVR(0), FVA(10), 44, 44)],]],]],
        [[FVDeclaration declaration:@"gauge" frame:CGRectMake(0, FVT(88), FVP(1), 44)] withDeclarations:^{
            NSMutableArray *array = [NSMutableArray array];
            for (int i = 0; i < 20; ++i) {
                FVDeclaration *d = [FVDeclaration declaration:[NSString stringWithFormat:@"%d", i] frame:CGRectMake(FVP(0.05 * i), 0, FVP(0.05), FVP(1))];
                d.debug = YES;
                [array addObject:d];
            }
            return array;
        }()],
        [template() assignFrame:CGRectMake(FVP(0.05), FVT(44), FVP(0.9), 44)],]];

    FVDeclaration *autoD = [root declarationByName:@"auto"];
    [autoD assignObject:^{
        UIView *v = [[UIView alloc] init];
        v.backgroundColor = [UIColor yellowColor];
        return v;
    }()];

    UIViewController *controller = [[UIViewController alloc] init];
    [root assignObject:controller.view];
    [root loadView];
    // add the background color for each loadView
    [[controller.view subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIView *v = obj;
        UIColor *color = [UIColor colorWithRed:(arc4random()%255)/255.0f green:(arc4random()%255)/255.0 blue:(arc4random()%255)/255.0 alpha:0.8];
        v.backgroundColor = color;
    }];
    self.window.rootViewController = controller;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

}

@end