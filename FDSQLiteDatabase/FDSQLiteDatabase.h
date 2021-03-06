@import Foundation;

@import FDFoundationKit;

#import "FDStatementResult.h"


#pragma mark - Constants

extern NSString * const FDSQLiteDatabaseErrorDomain;


#pragma mark Type Definitions

typedef id (^FDSQLiteDatabaseTransformBlock)(NSDictionary *row);


#pragma mark - Enumerations


#pragma mark - Class Interface

@interface FDSQLiteDatabase : NSObject


#pragma mark - Properties


#pragma mark - Constructors

- (id)initWithName: (NSString *)name;


#pragma mark - Static Methods


#pragma mark - Instance Methods

- (FDStatementResult *)executeStatementWithTransformBlock: (FDSQLiteDatabaseTransformBlock)transformBlock 
	statement: (NSString *)statement, ...;
- (FDStatementResult *)executeStatement: (NSString *)statement, ...;


@end