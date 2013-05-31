//
// Created by lishuo on 13-5-28.
// Copyright (c) 2013 ___FULLUSERNAME___. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "FVDeclaration.h"

@interface FVDeclaration()
@property (nonatomic, assign) BOOL xCalculated;
@property (nonatomic, assign) BOOL yCalculated;
@property (nonatomic, assign) BOOL widthCalculated;
@property (nonatomic, assign) BOOL heightCalculated;

@property (nonatomic, weak) UIView* weakObject;
@end

@implementation FVDeclaration

-(id)init{
    if(self = [super init]){
    }
    return self;
}

+(FVDeclaration *)declaration:(NSString*)name frame:(CGRect)frame {
    FVDeclaration *declaration = [[FVDeclaration alloc]init];
    declaration.name = name;
    declaration.frame = frame;
    return declaration;
}

-(FVDeclaration *)assignObject:(UIView*)object{
    self.object = object;
    return self;

}

-(FVDeclaration *)withDeclarations:(NSArray *)array{
    self.subDeclarations = [array mutableCopy];
    [self.subDeclarations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [(FVDeclaration *)obj setParent:self];
    }];
    return self;
}

- (FVDeclaration *)Context:(NSDictionary *)context {
    self.context = context;
    return self;
}

-(FVDeclaration *)declarationByName:(NSString *)name {
    if([self.name isEqualToString:name]) {
        return self;
    }
    else{
        for(FVDeclaration *declaration in self.subDeclarations){
            FVDeclaration *dec = [declaration declarationByName:name];
            if(dec != nil){
                return dec;
            }
        }
    }

    return nil;
}

-(void)calculateLayout {
    if(!self.xCalculated){
        CGFloat x = self.frame.origin.x;
        if(FVIsNormal(x)){
            self.xCalculated = YES;
        }
        else if(FVIsPercent(x)){
            NSAssert(self.parent, @"For percent values, the parent must not be nil");
            if(self.parent.widthCalculated){
                [self assignX:self.parent.frame.size.width * FVF2P(x)];
            }
        }
        else if(FVIsFill(x)){
            NSAssert(!FVIsFill(x), @"x not support FVFill");
        }
        else if(FVIsAfter(x)){
            NSAssert(self.parent, @"FVAfter must has a valid parent");
            FVDeclaration *prev = [self.parent prevSiblingOfChild:self];
            if(prev){
                if(prev.xCalculated){
                    [self assignX: prev.frame.origin.x + prev.frame.size.width + FVFloat2After(x)];
                }
            }
            else{
                [self assignX:FVFloat2After(x)];
            }
        }
        else if(FVIsTail(x)){
            NSAssert(self.parent, @"FVTail must has a valid parent, and its width already calcualted");
            if(self.parent.widthCalculated){
                [self assignX: self.parent.frame.size.width - FVF2T(x)];
            }
        }
        else if(FVIsRelated(x)){
            NSAssert(self.parent, @"FVRelated must has a valid parent");
            FVDeclaration *prev = [self.parent prevSiblingOfChild:self];
            if(prev && prev.xCalculated){
                [self assignX: prev.frame.origin.x + FVF2R(x)];
            }
            else{
                [self assignX:FVF2R(x)];
            }
        }
    }

    if(!self.widthCalculated){
        CGFloat w = self.frame.size.width;
        if(FVIsNormal(w)){
            self.widthCalculated = YES;
        }
        else if(FVIsPercent(w)){
            if(self.parent && self.parent.widthCalculated){
                [self assignWidth: self.parent.frame.size.width * FVF2P(w)];
                self.widthCalculated = YES;
            }
        }
        else if (FVIsRelated(w)){
            FVDeclaration *prev = [self prevSibling];
            if(prev && prev.widthCalculated){
                [self assignWidth:prev.frame.size.width + FVF2R(w)];
            }
            else{
                [self assignWidth:FVF2R(w)];
            }
        }
        else if(FVIsFill(w)){
            //Need the next x's x been calculated
            FVDeclaration *next = [self nextSibling];
            if (next) {
                if(!next.xCalculated){
                    [next calculateLayout];
                }

                if(next.xCalculated){
                    [self assignWidth:next.frame.origin.x - self.frame.origin.x];
                }
            }
            else{
                [self assignWidth:self.parent.frame.size.width - self.frame.origin.x];
            }
        }
        else if(FVIsAuto(w)){
            if(self.subDeclarations && self.subDeclarations.count > 0){
                CGFloat width = 0.0f;
                for( FVDeclaration *declaration in self.subDeclarations){
                    if(!declaration.xCalculated && !declaration.widthCalculated){
                        [declaration calculateLayout];
                    }
                    NSAssert(declaration.xCalculated && declaration.widthCalculated, @"Auto for w: sub declaration's x and width must be calculated");
                    CGFloat right = declaration.frame.origin.x + declaration.frame.size.width;
                    width = width > right ? width : right;
                }
                [self assignWidth:width];
            }
            else{
                [self assignWidth:0];
            }
        }
    }

    if(!self.yCalculated){
        CGFloat y = self.frame.origin.y;
        if(FVIsNormal(y)){
            self.yCalculated = YES;
        }
        else if(FVIsPercent(y)){
            NSAssert(self.parent, @"Percent y: must have a parent");
            if(self.parent.heightCalculated){
                [self assignY:self.parent.frame.size.height * FVF2P(y)];
            }
        }
        else if(FVIsAfter(y)){
            if(self.parent){
                FVDeclaration *prev = [self.parent prevSiblingOfChild:self];
                if(prev.yCalculated && prev.heightCalculated){
                    [self assignY: prev.frame.origin.y + prev.frame.size.height + FVFloat2After(y)];
                }
            }
        }
        else if(FVIsTail(y)){
            if(self.parent && self.parent.heightCalculated){
                [self assignY:self.parent.frame.size.height - FVF2T(y)];
            }
        }
        else if(FVIsRelated(y)){
            if(self.parent){
                FVDeclaration *prev = [self.parent prevSiblingOfChild:self];
                if(prev && prev.yCalculated){
                    [self assignY: prev.frame.origin.y + FVF2R(y)];
                }
                else{
                    [self assignY:FVF2R(y)];
                }
            }
        }
    }

    if (!self.heightCalculated){
        CGFloat h = self.frame.size.height;
        if (FVIsNormal(h)){
            self.heightCalculated = YES;
        }
        else if (FVIsPercent(h)){
            if (self.parent && self.parent.heightCalculated){
                [self assignHeight: self.parent.frame.size.height * FVF2P(h)];
            }
        }
        else if(FVIsRelated(h)){
            NSAssert(self.parent, @"FVRelated: self.parent is nil");
            FVDeclaration *prev = [self.parent prevSiblingOfChild:self];
            if(prev){
                if (prev.heightCalculated) {
                    [self assignHeight: prev.frame.size.height + FVF2R(h)];
                }
                //In order to prevent deadloop, the calculation order is top down, left right rule,
                //if prev height not calculated, wait next time
            }
            else{
                [self assignHeight:FVF2R(h)];
            }
        }
        else if(FVIsFill(h)){
            NSAssert(self.parent, @"FVFill: self.parent is nil");
            FVDeclaration *next = [self.parent nextSiblingOfChild:self];
            if (next) {
                if(!next.yCalculated){
                    [next calculateLayout];
                    NSAssert(next.yCalculated, @"FVFill for height: next y must be calculated");
                    [self assignHeight: next.frame.origin.y - self.frame.origin.y];
                }
            }
            else{
                [self assignHeight:self.parent.frame.size.height - self.frame.origin.y];
            }
        }
        else if(FVIsAuto(h)){
            if (self.subDeclarations && self.subDeclarations.count > 0){
                CGFloat height = 0.0f;
                for(FVDeclaration *declaration in self.subDeclarations){
                    [declaration calculateLayout];
                    NSAssert(declaration.yCalculated && declaration.heightCalculated, @"FVAuto: y and height must calculated");
                    CGFloat bottom = declaration.frame.origin.y + declaration.frame.size.height;
                    height = height > bottom ? height : bottom;
                }
                [self assignHeight:height];
            }
            else{
                [self assignHeight:0];
            }
        }
        else{
            NSAssert(NO, @"Code should not hit this place");
        }
    }

    for(FVDeclaration *declaration in self.subDeclarations){
        [declaration calculateLayout];
    }
}

-(FVDeclaration *)nextSiblingOfChild:(FVDeclaration *)declaration{
    NSUInteger index = [self.subDeclarations indexOfObject:declaration];
    if(index != NSNotFound && index + 1 < self.subDeclarations.count){
        return self.subDeclarations[index+1];
    }
    return nil;
}

-(FVDeclaration *)prevSiblingOfChild:(FVDeclaration *)declaration{
    NSUInteger index = [self.subDeclarations indexOfObject:declaration];
    if(index != NSNotFound && index > 0){
        return self.subDeclarations[index-1];
    }
    return nil;
}

-(FVDeclaration *)prevSibling{
    if(self.parent){
        return [self.parent prevSiblingOfChild:self];
    }
}

-(FVDeclaration *)nextSibling{
    if(self.parent){
        return [self.parent nextSiblingOfChild:self];
    }
}

-(void)assignWidth:(CGFloat)width{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
    self.widthCalculated = YES;
}

-(void)assignX:(CGFloat)x{
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
    self.xCalculated = YES;
}

-(void)assignY:(CGFloat)y{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
    self.yCalculated = YES;
}

-(void)assignHeight:(CGFloat)height{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
    self.heightCalculated = YES;
}

-(BOOL)calculated:(BOOL)recursive {

    if (!self.xCalculated || !self.yCalculated || !self.widthCalculated || !self.heightCalculated){
        return NO;
    }
    if(recursive){
        for(FVDeclaration *declaration in self.subDeclarations){
            if(![declaration calculated:recursive]){
                return NO;
            }
        }
    }

    return YES;
}

-(UIView*)loadView {
    if (![self calculated:YES]){
        NSError *error;
        [self calculateLayout];
    }

    if(!self.object){
        if(self.weakObject){
            //This declaration already bind to a view
            self.object = self.weakObject;
        }
        if (!self.object) {
            if(self.objectCreationBlock){
                self.object = self.objectCreationBlock(self.context);
            }
            else{
                self.object = [[UIView alloc] init];
                self.object.backgroundColor = [UIColor colorWithRed:(arc4random()%255)/255.0f green:(arc4random()%255)/255.0 blue:(arc4random()%255)/255.0 alpha:0.8];
            }
        }
    }
    self.object.frame = self.frame;

    for(FVDeclaration *declaration in self.subDeclarations){
        UIView *v = [declaration loadView];
        [self.object addSubview:v];
    }

    UIView * result = self.object;
    self.weakObject = self.object;
    self.object = nil; //when loadView called, we don't own the object, it is the side effect of loadView
    return result;
}

-(FVDeclaration *)assignFrame:(CGRect)frame{
    self.frame = frame;
    return self;
}

-(FVDeclaration *)process:(FVDeclarationProcessBlock)processBlock {
    processBlock(self);
    return self;
}
@end
