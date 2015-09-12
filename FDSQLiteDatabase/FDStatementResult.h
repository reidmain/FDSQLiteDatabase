@import Foundation;


#pragma mark - Enumerations

typedef NS_ENUM(NSInteger, FDStatementResultStatus)
{
	FDStatementResultStatusSucceed,
	FDStatementResultStatusFailed,
};


#pragma mark - Class Interface

@interface FDStatementResult : NSObject


#pragma mark - Properties

@property (nonatomic, assign, readonly) FDStatementResultStatus status;
@property (nonatomic, copy, readonly) NSArray *rows;
@property (nonatomic, strong, readonly) NSError *error;


@end