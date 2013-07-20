//
// Created by Li Shuo on 13-7-20.
// Copyright (c) 2013 ___FULLUSERNAME___. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "FVDeclareHelper.h"
#import "FVDeclaration.h"
#import "NSArray+BlocksKit.h"

__attribute__((overloadable)) FVDeclaration *dec(NSString* name, CGRect frame, UIView *view){
    FVDeclaration *declaration = [[FVDeclaration declaration:name frame:frame] assignObject:view];
    return declaration;
}

__attribute__((overloadable)) FVDeclaration *dec(NSString *name, CGRect frame){
    FVDeclaration *declaration = [FVDeclaration declaration:name frame:frame];
    return declaration;
}

__attribute__((overloadable)) FVDeclaration *dec(NSString *name){
    FVDeclaration *declaration = [FVDeclaration declaration:name frame:CGRectZero];
    return declaration;
}

@implementation FVDeclaration(Helper)
-(FVDeclaration *)$:(NSArray*)subDeclarations{
    return [self withDeclarations:subDeclarations];
}

-(FVDeclaration *)$$:(FVDeclaration *)declaration, ...{
    [self appendDeclaration:declaration];
    va_list args;
    va_start(args, declaration);
    id arg = nil;
    while((arg = va_arg(args,id))){
        [self appendDeclaration:arg];
    }
    va_end(args);

    return self;
}

-(FVDeclaration *)f:(CGRect)frame{
    return [self assignFrame:frame];
}

-(FVDeclaration *)o:(UIView *)view{
    return [self assignObject:view];
}
@end
