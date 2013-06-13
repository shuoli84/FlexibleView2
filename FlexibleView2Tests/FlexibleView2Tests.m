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
                    [root calculateLayout];
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
                    NSError* error;
                    [root calculateLayout];
                    [error shouldBeNil];
                    [[theValue(root.frame.origin.x) should] equal:theValue(0)];
                    [[theValue(root.frame.size.width) should] equal:theValue(1000)];

                    FVDeclaration *navigation = [root declarationByName:@"NavigationBar"];
                    [navigation shouldNotBeNil];
                    [[theValue(navigation.frame.size.width) should] equal:theValue(1000)];
                });

                it(@"fill should auto calculate", ^{
                    FVDeclaration *fill = [root declarationByName:@"fill"];
                    [[theValue(fill.frame.size.width) should] equal:theValue(1000 - 44 * 2)];
                });

                it(@"should be able to handle FVFoFVAfter", ^{
                    FVDeclaration *follow1 = [root declarationByName:@"follow1"];
                    FVDeclaration *follow2 = [root declarationByName:@"follow2"];
                    [[theValue(follow1.frame.origin.x) should] equal:theValue(44)];
                    [[theValue(follow2.frame.origin.x) should] equal:theValue(88)];
                });

                it(@"Percent supported", ^{
                    FVDeclaration *yp1 = [root declarationByName:@"yp1"];
                    [[theValue(roundf(yp1.frame.size.height)) should] equal:theValue(100)];
                });

                it(@"should be able to handle FVAuto", ^{
                    FVDeclaration *autoDeclare = [root declarationByName:@"auto"];
                    [[theValue(autoDeclare.frame.size.width) should] equal:
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
                    [root assignFrame:CGRectMake(0, 0, 100, 100)];
                    UIView *v = [root loadView];
                });

                it(@"should support post process", ^{
                    int __block flag = 0;
                    FVDeclaration *declare = [[FVDeclaration declaration:@"test" frame:CGRectMake(0,0,0,0)] postProcess:^(FVDeclaration *declaration) {
                        flag = 1;
                    }];

                    [[theValue(flag) should] equal:theValue(0)];

                    [declare loadView];

                    [[theValue(flag) should] equal:theValue(1)];

                });

                it(@"should support calculate width and height based on Tail value", ^{
                    FVDeclaration *declaration = [FVDeclaration declaration:@"parent" frame:CGRectMake(0, 0, 1000, 1000)];
                    [[declaration withDeclarations:@[
                        [FVDeclaration declaration:@"width" frame:CGRectMake(0, 0, FVT(100), FVP(1))],
                        [FVDeclaration declaration:@"height" frame:CGRectMake(0, 0, FVP(1), FVT(200))],
                    ]] loadView];

                    FVDeclaration *width = [declaration declarationByName:@"width"];
                    FVDeclaration *height = [declaration declarationByName:@"height"];

                    [[theValue(width.frame.size.width) should] equal:theValue(900)];
                    [[theValue(height.frame.size.height) should] equal:theValue(800)];
                });
            });
        });
SPEC_END
