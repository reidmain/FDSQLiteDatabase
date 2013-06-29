#import "FDStatementResult.h"


#pragma mark Class Interface

@interface FDStatementResult ()


#pragma mark - Properties

@property (nonatomic, assign) FDStatementResultStatus status;
@property (nonatomic, copy) NSArray *rows;
@property (nonatomic, strong) NSError *error;


@end