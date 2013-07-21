//
//  AppDelegate.m
//  FlexibleView2
//
//  Created by lishuo on 05/28/13.
//  Copyright (c) 2013 lishuo. All rights reserved.
//

#import "AppDelegate.h"
#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "FVDeclaration.h"
#import "FVDeclareHelper.h"
#import <BlocksKit.h>
@interface AppDelegate()
@property (nonatomic, strong) FVDeclaration *root;
@end
@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    self.root = [[FVDeclaration declaration:@"root" frame:CGRectMake(0, 0, self.window.screen.bounds.size.width, self.window.screen.bounds.size.height - 30)] withDeclarations:@[
        [[FVDeclaration declaration:@"ContentView" frame:CGRectMake(0, 44, FVP(1), FVFill)] withDeclarations:@[
            [FVDeclaration declaration:@"percent50" frame:CGRectMake(0, 0, FVP(0.5), 44)],
            [FVDeclaration declaration:@"percentOther50" frame:CGRectMake(0, 0, FVP(0.5), FVSameAsPrev)],

            [FVDeclaration declaration:@"fillLeft" frame:CGRectMake(0, 44, 44, FVSameAsPrev)],
            [FVDeclaration declaration:@"fill" frame:CGRectMake(FVAfter, 44, FVFill, FVSameAsPrev)], //the fill's width should be 1000-44*2
            [FVDeclaration declaration:@"fillRight" frame:CGRectMake(FVT(44), 44, 44, FVSameAsPrev)],

            [FVDeclaration declaration:@"followLeft" frame:CGRectMake(0, 44 * 2, 44, FVSameAsPrev)],
            [FVDeclaration declaration:@"follow1" frame:CGRectMake(FVAfter, 44 * 2, 44, FVSameAsPrev)],
            [FVDeclaration declaration:@"follow2" frame:CGRectMake(FVAfter, 44 * 2, 44, 44)],

            [[FVDeclaration declaration:@"auto" frame:CGRectMake(0, FVAfter, FVAuto, FVAuto)] withDeclarations:@[
                [FVDeclaration declaration:@"auto1" frame:CGRectMake(10, 0, 44, 44)],
                [FVDeclaration declaration:@"auto2" frame:CGRectMake(FVAfter, FVAfter, 44, 44)],
                [FVDeclaration declaration:@"auto3" frame:CGRectMake(FVAfter, FVAfter, 44, 44)],
                [FVDeclaration declaration:@"auto4" frame:CGRectMake(FVR(0), FVA(10), 44, 44)],]],]],
        [[FVDeclaration declaration:@"increaseme" frame:CGRectMake(0, FVT(350), FVP(1), 50)] assignObject:^{
            UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [button setTitle:@"click to increase" forState:UIControlStateNormal];
            [button addEventHandler:^(id sender) {

                CGFloat v = button.frame.size.height;

                [[self.root declarationByName:@"increaseme"] assignUnExpandedFrame:CGRectMake(0, FVT(350), FVP(1), v + 200)];
                [[self.root declarationByName:@"increaseme"] updateViewFrame];

                [UIView beginAnimations:nil context:nil];
                [[self.root declarationByName:@"increaseme"] assignUnExpandedFrame:CGRectMake(0, FVT(350), FVP(1), v + 30)];
                [self.root updateViewFrame];
                [UIView commitAnimations];
            } forControlEvents:UIControlEventTouchUpInside];

            return button;
        }()],
        [[FVDeclaration declaration:@"addsomecontainer" frame:CGRectMake(0, FVT(550), FVP(1), 100)] withDeclarations:@[
            [[FVDeclaration declaration:@"addsome" frame:CGRectMake(0, 0, FVP(1), 50)] assignObject:^{
                UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                [button setTitle:@"click add element" forState:UIControlStateNormal];
                [button addEventHandler:^(id sender) {
                    FVDeclaration *d = [self.root declarationByName:@"addsomecontainer"];
                    [d resetLayout];
                    FVDeclaration *newdec = dec(@"newview", CGRectMake(FVT(0), FVAfter, FVP(1), 50), ^{
                        UIView *view = [[UIView alloc]init];
                        view.backgroundColor = [UIColor blackColor];
                        return view;
                    }());
                    FVDeclaration *olddec = [d declarationByName:@"newview"];

                    [d appendDeclaration:newdec];
                    [d updateViewFrame];

                    [UIView beginAnimations:nil context:nil];

                    [UIView setAnimationDuration:.5];
                    [olddec removeFromParentDeclaration];
                    [newdec assignUnExpandedFrame:CGRectMake(0, FVAfter, FVP(1), 50)];
                    [newdec updateViewFrame];
                    [UIView commitAnimations];
                } forControlEvents:UIControlEventTouchUpInside];

                return button;
        }()]
        ]],
        [[FVDeclaration declaration:@"gauge" frame:CGRectMake(0, FVT(88), FVP(1), 44)] withDeclarations:^{
            NSMutableArray *array = [NSMutableArray array];
            for (int i = 0; i < 20; ++i) {
                FVDeclaration *d = [FVDeclaration declaration:[NSString stringWithFormat:@"%d", i] frame:CGRectMake(FVP(0.05 * i), 0, FVP(0.05), FVP(1))];
                [array addObject:d];
            }
            return array;
        }()],
        ]];

    FVDeclaration *autoD = [self.root declarationByName:@"auto"];
    [autoD assignObject:^{
        UIView *v = [[UIView alloc] init];
        v.backgroundColor = [UIColor yellowColor];
        return v;
    }()];

    UIViewController *controller = [[UIViewController alloc] init];
    [self.root assignObject:controller.view];
    [self.root setupViewTree];
    [self.root updateViewFrame];
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