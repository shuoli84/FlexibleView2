//
//  FlexibleView2Tests.m
//  FlexibleView2Tests
//
//  Created by lishuo on 05/28/13.
//  Copyright (c) 2013 lishuo. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import "FVDeclaration.h"
#import "Kiwi.h"
#import "NSObject+BlockObservation.h"
#import "FVDeclareHelper.h"

@interface DebugView : UIView
@property (nonatomic, copy) void (^didAddSubviewBlock)(UIView* view, UIView* subview);
@end

@implementation DebugView
-(void)didAddSubview:(UIView *)subview {
    self.didAddSubviewBlock(self, subview);
}
@end

SPEC_BEGIN(DeclarationSpec)
        describe(@"Declaration", ^{
            context(@"Position calculation", ^{

                __block FVDeclaration *root;

                beforeEach(^{
                    root = [[FVDeclaration declaration:@"root" frame:CGRectMake(0, 0, 1000, 1000)] withDeclarations:@[
                        [[FVDeclaration declaration:@"NavigationBar" frame:CGRectMake(0, 0, FVP(1), 44)] withDeclarations:@[
                            [[FVDeclaration declaration:@"MenuButton" frame:CGRectMake(0, 0, 44, FVP(1))] process:^(FVDeclaration *declaration) {
                                declaration.object = [[UIView alloc] init];
                                declaration.object.tag = 3;
                            }],
                            [FVDeclaration declaration:@"ComposeButton" frame:CGRectMake(FVT(44), 0, 44, FVP(1))],]],
                        [[FVDeclaration declaration:@"ContentView" frame:CGRectMake(0, 44, FVP(1), FVFill)] withDeclarations:@[
                            [FVDeclaration declaration:@"percent50" frame:CGRectMake(0, 0, FVP(0.5), 44)],
                            [FVDeclaration declaration:@"percentOther50" frame:CGRectMake(0, 0, FVP(0.5), FVSameAsPrev)],

                            [FVDeclaration declaration:@"fillLeft" frame:CGRectMake(0, 44, 44, FVSameAsPrev)],
                            [FVDeclaration declaration:@"fill" frame:CGRectMake(FVAfter, 44, FVFill, FVSameAsPrev)], //the fill's width should be 1000-44*2
                            [FVDeclaration declaration:@"fillRight" frame:CGRectMake(FVT(44), 44, 44, FVSameAsPrev)],

                            [FVDeclaration declaration:@"followLeft" frame:CGRectMake(0, 44 * 2, 44, FVSameAsPrev)],
                            [FVDeclaration declaration:@"follow1" frame:CGRectMake(FVAfter, 44 * 2, 44, FVSameAsPrev)],
                            [FVDeclaration declaration:@"follow2" frame:CGRectMake(FVAfter, 44 * 2, 44, 44)],

                            [[FVDeclaration declaration:@"auto" frame:CGRectMake(0, FVAfter, FVAuto, 44)] withDeclarations:@[
                                [FVDeclaration declaration:@"auto1" frame:CGRectMake(0, 44 * 3, 44, 44)],
                                [FVDeclaration declaration:@"auto2" frame:CGRectMake(FVAfter, FVAfter, 44, 44)],
                                [FVDeclaration declaration:@"auto3" frame:CGRectMake(FVAfter, FVAfter, 44, 44)],
                                [FVDeclaration declaration:@"auto4" frame:CGRectMake(FVR(0), FVAfter, 44, 44)],
                            ]],
                            [[FVDeclaration declaration:@"ypercent" frame:CGRectMake(0, FVAfter, FVP(1), 300)] withDeclarations:@[
                                [FVDeclaration declaration:@"yp1" frame:CGRectMake(0, 0, FVP(0.5), FVP(1.0 / 3))],
                                [FVDeclaration declaration:@"yp2" frame:CGRectMake(0, FVAfter, FVP(0.5), FVP(1.0 / 3))],
                                [FVDeclaration declaration:@"yfill" frame:CGRectMake(0, FVAfter, FVFill, FVFill)],
                            ]],
                        ]],
                    ]];
                    [root setupViewTree];
                    [root updateViewFrame];
                });

                it(@"should able to fetch by name", ^{
                    FVDeclaration *composeButton = [root declarationByName:@"ComposeButton"];
                    [[composeButton.name should] equal:@"ComposeButton"];
                });

                it(@"should able to convert between float and relative and special values", ^{
                    [[theValue(FVIsPercent(FVP(1))) should] beTrue];
                    [[theValue(FVF2P(FVP(1))) should] equal:theValue(1)];
                    // 0.05 is a float, comparation will fail, need to take almost equal instead of equal
                    [[theValue(FVF2P(FVP(0.05))) should] equal:theValue(0.05)];
                    [[theValue(FVIsTail(FVT(44))) should] beTrue];
                    [[theValue(FVF2T(FVT(44))) should] equal: theValue(44)];

                    [[theValue(FVIsFill(FVFill)) should] beTrue];
                    [[theValue(FVIsAfter(FVAfter)) should] beTrue];
                    [[theValue(FVIsAuto(FVAuto)) should] beTrue];
                    [[theValue(FVIsNormal(44)) should] beTrue];
                });

                it(@"should able to accept absolute values", ^{
                    [[theValue(root.expandedFrame.origin.x) should] equal:theValue(0)];
                    [[theValue(root.expandedFrame.size.width) should] equal:theValue(1000)];

                    FVDeclaration *navigation = [root declarationByName:@"NavigationBar"];
                    [navigation shouldNotBeNil];
                    [[theValue(navigation.expandedFrame.size.width) should] equal:theValue(1000)];
                });

                it(@"fill should auto calculate", ^{
                    FVDeclaration *fill = [root declarationByName:@"fill"];
                    [[theValue(fill.expandedFrame.size.width) should] equal:theValue(1000 - 44 * 2)];
                });

                it(@"should be able to handle FVFoFVAfter", ^{
                    FVDeclaration *follow1 = [root declarationByName:@"follow1"];
                    FVDeclaration *follow2 = [root declarationByName:@"follow2"];
                    [[theValue(follow1.expandedFrame.origin.x) should] equal:theValue(44)];
                    [[theValue(follow2.expandedFrame.origin.x) should] equal:theValue(88)];
                });

                it(@"Percent supported", ^{
                    FVDeclaration *yp1 = [root declarationByName:@"yp1"];
                    [[theValue(roundf(yp1.expandedFrame.size.height)) should] equal:theValue(100)];
                });

                it(@"should be able to handle FVAuto", ^{
                    FVDeclaration *autoDeclare = [root declarationByName:@"auto"];
                    [[theValue(autoDeclare.expandedFrame.size.width) should] equal:
                    theValue(44*3)];
                });

                it( @"should be calculated", ^{
                    [[theValue([root calculated:YES]) should] beTrue];
                });

                it( @"should support process", ^{
                    [[theValue([root declarationByName:@"MenuButton"].object.tag) should] equal:
                    theValue(3)];
                });

                it(@"should support recalculate on newer setted frame", ^{
                    [root resetLayout];
                    [root assignUnExpandedFrame:CGRectMake(0, 0, 100, 100)];
                    [root updateViewFrame];
                });

                it(@"should support post process", ^{
                    int __block flag = 0;
                    FVDeclaration *declare = [[FVDeclaration declaration:@"test" frame:CGRectMake(0,0,0,0)] postProcess:^(FVDeclaration *declaration) {
                        flag = 1;
                    }];

                    [[theValue(flag) should] equal:theValue(0)];
                    [declare updateViewFrame];
                    [[theValue(flag) should] equal:theValue(1)];

                });

                it(@"should support calculate width and height based on Tail value", ^{
                    FVDeclaration *declaration = [FVDeclaration declaration:@"parent" frame:CGRectMake(0, 0, 1000, 1000)];
                    [[declaration withDeclarations:@[
                        [FVDeclaration declaration:@"width" frame:CGRectMake(0, 0, FVT(100), FVP(1))],
                        [FVDeclaration declaration:@"height" frame:CGRectMake(0, 0, FVP(1), FVT(200))],
                    ]] updateViewFrame];

                    FVDeclaration *width = [declaration declarationByName:@"width"];
                    FVDeclaration *height = [declaration declarationByName:@"height"];

                    [[theValue(width.expandedFrame.size.width) should] equal:theValue(900)];
                    [[theValue(height.expandedFrame.size.height) should] equal:theValue(800)];
                });

                #define F CGRectMake
                #define declare FVDeclaration
                it(@"should support center calculation", ^{
                    FVDeclaration *declaration = [FVDeclaration declaration:@"root" frame:CGRectMake(0, 0, 1000, 1000)];
                    [declaration withDeclarations:@[
                        [FVDeclaration declaration:@"center" frame:F(FVCenter, FVCenter, 40, 40)],
                        [[declare declaration:@"center-autowidth" frame:F(FVCenter, FVCenter, FVAuto, FVAuto)] withDeclarations:@[
                            [declare declaration:@"sub1" frame:F(0, 0, 30, 30)],
                            [declare declaration:@"sub2" frame:F(10, 10, 30, 30)],
                        ]],
                    ]];
                    [declaration updateViewFrame];
                    FVDeclaration *center = [declaration declarationByName:@"center"];
                    [[theValue(center.expandedFrame.origin.x) should] equal:theValue(480)];
                    [[theValue(center.expandedFrame.origin.y) should] equal:theValue(480)];
                    declare* centerAutoWidth = [declaration declarationByName:@"center-autowidth"];
                    [[theValue(centerAutoWidth.expandedFrame.origin.x) should] equal:theValue(480)];
                    [[theValue(centerAutoWidth.expandedFrame.size.width) should] equal:theValue(40)];
                    [[theValue(centerAutoWidth.expandedFrame.origin.y) should] equal:theValue(480)];
                    [[theValue(centerAutoWidth.expandedFrame.size.height) should] equal:theValue(40)];
                });

                it(@"should support autoTail calculation", ^{
                    FVDeclaration *declaration = [[FVDeclaration declaration:@"root" frame:CGRectMake(0, 0, 1000, 1000)] assignObject:[UIView new]];
                    [declaration withDeclarations:@[
                        [FVDeclaration declaration:@"center" frame:F(FVAutoTail, FVAutoTail, 40, 40)],
                        [[declare declaration:@"center-autowidth" frame:F(FVAutoTail, FVAutoTail, FVAuto, FVAuto)] withDeclarations:@[
                            [declare declaration:@"sub1" frame:F(0, 0, 30, 30)],
                            [[declare declaration:@"sub2" frame:F(10, 10, 30, 30)] assignObject:[UIView new]],
                        ]],
                    ]];
                    [declaration updateViewFrame];
                    FVDeclaration *center = [declaration declarationByName:@"center"];
                    [[theValue(center.expandedFrame.origin.x) should] equal:theValue(960)];
                    [[theValue(center.expandedFrame.origin.y) should] equal:theValue(960)];
                    declare* centerAutoWidth = [declaration declarationByName:@"center-autowidth"];
                    [[theValue(centerAutoWidth.expandedFrame.origin.x) should] equal:theValue(960)];
                    [[theValue(centerAutoWidth.expandedFrame.size.width) should] equal:theValue(40)];
                    [[theValue(centerAutoWidth.expandedFrame.origin.y) should] equal:theValue(960)];
                    [[theValue(centerAutoWidth.expandedFrame.size.height) should] equal:theValue(40)];

                    declare* sub2 = [declaration declarationByName:@"sub2"];
                    NSLog(@"%@", NSStringFromCGRect(sub2.object.frame));
                });

                it(@"should support till end", ^{
                    FVDeclaration *declaration = [[FVDeclaration declaration:@"root" frame:CGRectMake(0, 0, 1000, 1000)] assignObject:[UIView new]];
                    [declaration withDeclarations:@[
                        [FVDeclaration declaration:@"tillEnd" frame:F(30, 30, FVTillEnd, FVTillEnd)],
                        [[declare declaration:@"center-autowidth" frame:F(FVAutoTail, FVAutoTail, FVAuto, FVAuto)] withDeclarations:@[
                            [[declare declaration:@"sub1" frame:F(0, 0, 30, 30)] assignObject:[UIView new]],
                        ]],
                    ]];
                    [declaration updateViewFrame];

                    CGRect f = [declaration declarationByName:@"tillEnd"].expandedFrame;
                    [[theValue(f.size.width) should] equal:theValue(970)];
                    [[theValue(f.size.height) should] equal:theValue(970)];
                });

                it(@"should support update view frame", ^{
                    FVDeclaration *declaration = [[FVDeclaration declaration:@"root" frame:CGRectMake(0, 0, 1000, 1000)] assignObject:[DebugView new]];
                    [declaration withDeclarations:@[
                        [FVDeclaration declaration:@"tillEnd" frame:F(30, 30, FVTillEnd, FVTillEnd)],
                        [[declare declaration:@"center-autowidth" frame:F(FVAutoTail, FVAutoTail, FVAuto, FVAuto)] withDeclarations:@[
                            [[declare declaration:@"sub1" frame:F(0, 0, 30, 30)] assignObject:[UIView new]],
                        ]],
                    ]];
                    DebugView* dv = (DebugView*)declaration.object;
                    BOOL __block called = NO;
                    dv.didAddSubviewBlock = ^(UIView *view, UIView *subview){
                        called = YES;
                    };

                    [declaration setupViewTree];
                    [declaration updateViewFrame];

                    [[theValue(called) should] beYes];
                    called = NO;

                    [declaration declarationByName:@"sub1"].unExpandedFrame = F(0, 0, 50, 50);
                    [declaration updateViewFrame];

                    NSLog(@"%@", NSStringFromCGRect([declaration declarationByName:@"sub1"].object.frame));
                    [[theValue(called) should] beNo];
                });

                it(@"should support autopilot", ^{
                    FVDeclaration *declaration = [FVDeclaration declaration:@"root" frame:CGRectMake(0, 0, 1000, 1000)];
                    [declaration withDeclarations:@[
                        [FVDeclaration declaration:@"center" frame:F(FVAutoTail, FVAutoTail, 40, 40)],
                        [[declare declaration:@"center-autowidth" frame:F(FVAutoTail, FVAutoTail, FVAuto, FVAuto)] withDeclarations:@[
                            [[declare declaration:@"sub1" frame:F(0, 0, 30, 30)] assignObject:[UIView new]],
                        ]],
                    ]];

                    [declaration updateViewFrame];
                    UIView* sub2 = [declaration declarationByName:@"sub2"].object;

                    UIView *superView = [UIView new];
                    superView.frame = F(0, 0, 1000, 1000);

                    [superView addObserverForKeyPaths:@[@"frame", @"bounds"] task:^(id obj, NSString *keyPath) {
                        declaration.unExpandedFrame = [obj bounds];
                        [declaration updateViewFrame];
                        [obj addSubview:declaration.object];
                    }];

                    superView.frame = F(0, 0, 2000, 2000);
                    superView.bounds = F(0, 0, 2000, 3000);

                    NSLog(@"frame of sub2 change to %@", NSStringFromCGRect(sub2.frame));

                    superView.frame = F(0, 0, 500, 500);
                    NSLog(@"frame of sub2 change to %@", NSStringFromCGRect(sub2.frame));
                });
                it(@"should support deep copy", ^{
                    declare* rootCopy = [root copy];

                    [[root.name should] equal:rootCopy.name];
                    [[theValue(root.subDeclarations.count) should] equal:theValue(rootCopy.subDeclarations.count)];
                });

                it(@"should able to updateviewframe even itself is a virtual node", ^{
                    declare* d = dec(@"root",F(0, 0, 1000, 1000));
                    [d $$:
                        [dec(@"p1", F(FVP(0.5), FVP(0.5), FVP(0.5), FVP(0.5))) $$:
                            [dec(@"p2", F(FVA(10), FVA(10), FVTillEnd, FVTillEnd)) $$:
                                dec(@"v", F(FVA(10), FVA(10), FVTillEnd, FVTillEnd), [UIView new]),
                                nil],
                            nil],
                        nil];

                    UIView *view = [[UIView alloc]init];
                    view.frame = F(0, 0, 1000, 1000);

                    [d updateViewFrame];
                    NSString *str1 = NSStringFromCGRect([[view.subviews lastObject] frame]);

                    declare* d1 = [d declarationByName:@"v"];
                    NSString *str2 = NSStringFromCGRect([[view.subviews lastObject] frame]);

                    [d1 updateViewFrame];
                    NSString *str3 = NSStringFromCGRect([[view.subviews lastObject] frame]);

                    [[str1 should] equal:str2];
                    [[str1 should] equal:str3];
                });

                it(@"should able to use offset in tillend", ^{
                    declare *d = [dec(@"container", CGRectMake(0, 0, 1000, 1000)) $:@[
                        dec(@"left", CGRectMake(100, 0, FVE(-50), FVTillEnd)),
                    ]];
                    [d setupViewTree];
                    [d updateViewFrame];
                    CGFloat w = [d declarationByName:@"left"].expandedFrame.size.width;
                    [[theValue(w) should] equal:theValue(850)];
                    CGFloat h = [d declarationByName:@"left"].expandedFrame.size.height;
                    [[theValue(h) should] equal:theValue(1000)];
                });

                it(@"should able to use origin value for view", ^{
                    UIView *view = [[UIView alloc] initWithFrame:F(1, 2, 1001, 1002)];
                    declare *d = dec(@"root", F(FVKeepOrigin, FVKeepOrigin, FVKeepOrigin, FVKeepOrigin), view);
                    [d updateViewFrame];

                    [[theValue(view.frame.origin.x) should] equal:theValue(1)];
                    [[theValue(view.frame.origin.y) should] equal:theValue(2)];
                    [[theValue(view.frame.size.width) should] equal:theValue(1001)];
                    [[theValue(view.frame.size.height) should] equal:theValue(1002)];

                });
            });
        });
SPEC_END
