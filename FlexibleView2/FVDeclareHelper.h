//
// Created by Li Shuo on 13-7-20.
// Copyright (c) 2013 ___FULLUSERNAME___. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "FVDeclaration.h"

/**
 * Helper class which provide some short hand or helper
 */

__attribute__((overloadable)) FVDeclaration *dec(NSString *name, CGRect frame, UIView *view);
__attribute__((overloadable)) FVDeclaration *dec(NSString *name, CGRect frame);
__attribute__((overloadable)) FVDeclaration *dec(NSString *name);

@interface FVDeclaration(Helper)

-(FVDeclaration *)$:(NSArray*)subDeclarations;
-(FVDeclaration *)$$:(FVDeclaration *)declaration, ... NS_REQUIRES_NIL_TERMINATION;
-(FVDeclaration *)f:(CGRect)frame;
-(FVDeclaration *)o:(UIView *)view;
@end

