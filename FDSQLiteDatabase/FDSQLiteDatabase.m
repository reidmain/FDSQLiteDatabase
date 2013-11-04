#import "FDSQLiteDatabase.h"
#import "sqlite3.h"
#import "FDStatementResult+Private.h"
#import "NSArray+Accessing.h"


#pragma mark Constants

NSString * const FDSQLiteDatabaseErrorDomain = @"FDSQLiteDatabaseErrorDomain";


#pragma mark - Class Extension

@interface FDSQLiteDatabase ()

- (FDStatementResult *)_executeStatementWithTransformBlock: (FDSQLiteDatabaseTransformBlock)transformBlock 
	statement: (NSString *)statement 
	argumentList: (va_list)argumentList;
- (NSError *)_lastError;

@end


#pragma mark - Class Variables


#pragma mark - Class Definition

@implementation FDSQLiteDatabase
{
	@private sqlite3 *_database;
}


#pragma mark - Properties


#pragma mark - Constructors

- (id)initWithName: (NSString *)name
{
	// Abort if base initializer fails.
	if ((self = [super init]) == nil)
	{
		return nil;
	}
	
	// Get the URL for the user's documents directory.
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *documentsURL = [[fileManager URLsForDirectory: NSDocumentDirectory 
		inDomains: NSUserDomainMask] 
			firstObject];
	
	// Determine the URL of the database file.
	NSURL *databaseFileURL = [documentsURL URLByAppendingPathComponent: 
		[NSString stringWithFormat: @"%@.sqlite", name]];
	
	// If the database file does not exist at the URL but a SQLite database file of the same name exists in the bundle copy it to the URL.
	if ([fileManager fileExistsAtPath: [databaseFileURL path]] == NO)
	{
		NSBundle *mainBundle = [NSBundle mainBundle];
		NSURL *bundleDatabaseFileURL = [mainBundle URLForResource: name 
			withExtension: @"sqlite"];
		
		if(bundleDatabaseFileURL != nil)
		{
			NSError *error = nil;
			[fileManager copyItemAtURL: bundleDatabaseFileURL 
				toURL: databaseFileURL 
				error: &error];
			
			if (nil != error)
			{
				NSLog(@"Failed to copy database to documents directory: %@", 
					[error localizedDescription]);
				
				return nil;
			}
		}
	}
	
	// Open a connection to the database file.
	int resultCode = sqlite3_open([[databaseFileURL path] UTF8String], &_database);
	if (resultCode != SQLITE_OK)
	{
		NSLog(@"Failed to open connection to database: %s", 
			sqlite3_errmsg(_database));
		
		return nil;
	}
	
	// Turn on foreign key support.
	resultCode = sqlite3_exec(_database, "PRAGMA foreign_keys = ON", NULL, NULL, NULL);
	if (resultCode != SQLITE_OK)
	{
		NSLog(@"Error turning on foreign key support.\n%s", 
			sqlite3_errmsg(_database));
	}
	
	// Return initialized instance.
	return self;
}


#pragma mark - Public Methods

- (FDStatementResult *)executeStatementWithTransformBlock: (FDSQLiteDatabaseTransformBlock)transformBlock 
	statement: (NSString *)statement, ...
{
	// Get a pointer to the list of variable arguments passed into the method.
	va_list argumentList = nil;
	va_start(argumentList, statement);
	
	FDStatementResult *statementResult = [self _executeStatementWithTransformBlock: transformBlock 
		statement: statement 
		argumentList: argumentList];
	
	// Release the list of variable arguments.
	va_end(argumentList);
	
	return statementResult;
}

- (FDStatementResult *)executeStatement: (NSString *)statement, ...
{
	// Get a pointer to the list of variable arguments passed into the method.
	va_list argumentList = nil;
	va_start(argumentList, statement);
	
	FDStatementResult *statementResult = [self _executeStatementWithTransformBlock: nil 
		statement: statement 
		argumentList: argumentList];
	
	// Release the list of variable arguments.
	va_end(argumentList);
	
	return statementResult;
}


#pragma mark - Overridden Methods


#pragma mark - Private Methods

- (FDStatementResult *)_executeStatementWithTransformBlock: (FDSQLiteDatabaseTransformBlock)transformBlock 
	statement: (NSString *)statement 
	argumentList: (va_list)argumentList
{
	FDStatementResult *statementResult = [[FDStatementResult alloc] 
		init];
	
	// Attempt to prepare the statement.
	sqlite3_stmt *preparedStatement = nil;
	int resultCode = sqlite3_prepare_v2(_database, [statement UTF8String], -1, &preparedStatement, nil);
	if (resultCode != SQLITE_OK)
	{
		NSError *error = [self _lastError];
		
		NSLog(@"Error preparing statement\n\n%@\n\n%@", 
			statement, 
			[error localizedDescription]);
		
		statementResult.status = FDStatementResultStatusFailed;
		statementResult.error = error;
		
		return statementResult;
	}
	
	// Determine how many bound parameters are in the statement.
	int numberOfParameters = sqlite3_bind_parameter_count(preparedStatement);
	
	// Iterate through all the variable arguments and bind them to the paramters in the statement.
	unsigned int argumentIndex = 1;
	
	id argument = nil;
	while (argumentIndex <= numberOfParameters)
	{
		argument = va_arg(argumentList, id);
		
		if ([argument isKindOfClass: [NSData class]] == YES)
		{
			sqlite3_bind_blob(preparedStatement, argumentIndex, [argument bytes], [argument length], SQLITE_STATIC);
		}
		else if ([argument isKindOfClass: [NSDate class]] == YES)
		{
			double timeIntervalSince1970 = [argument timeIntervalSince1970];
			
			sqlite3_bind_double(preparedStatement, argumentIndex, timeIntervalSince1970);
		}
		else if ([argument isKindOfClass: [NSNumber class]] == YES)
		{
			const char *argumentType = [argument objCType];
			if (strcmp(argumentType, @encode(BOOL)) == 0)
			{
				sqlite3_bind_int(preparedStatement, argumentIndex, [argument boolValue]);
			}
			else if (strcmp(argumentType, @encode(int)) == 0)
			{
				sqlite3_bind_int(preparedStatement, argumentIndex, [argument intValue]);
			}
			else if (strcmp(argumentType, @encode(long long)) == 0)
			{
				sqlite3_bind_int64(preparedStatement, argumentIndex, [argument longLongValue]);
			}
			else if (strcmp(argumentType, @encode(float)) == 0)
			{
				sqlite3_bind_double(preparedStatement, argumentIndex, [argument floatValue]);
			}
			else if (strcmp(argumentType, @encode(double)) == 0)
			{
				sqlite3_bind_double(preparedStatement, argumentIndex, [argument doubleValue]);
			}
			else
			{
				sqlite3_bind_text(preparedStatement, argumentIndex, [[argument description] UTF8String], -1, SQLITE_STATIC);
			}
		}
		else
		{
			sqlite3_bind_text(preparedStatement, argumentIndex, [[argument description] UTF8String], -1, SQLITE_STATIC);
		}
		
		argumentIndex++;
	}
	
	// Execute the statement.
	resultCode = sqlite3_step(preparedStatement);
	
	// If the statement is done that means the statement must have just been an update and it succeeded.
	if(resultCode == SQLITE_DONE)
	{
		statementResult.status = FDStatementResultStatusSucceed;
	}
	// If the statement returned a row iterate through all the rows and return them in the result.
	else if (resultCode == SQLITE_ROW)
	{
		// Iterate over every row in the results of the statement and create a dictionary out of the columns.
		NSMutableArray *rows = [NSMutableArray array];
		while (resultCode == SQLITE_ROW)
		{
			int numberOfColumns = sqlite3_column_count(preparedStatement);
			
			NSMutableDictionary *row = [NSMutableDictionary dictionaryWithCapacity:numberOfColumns];
			
			for (int i = 0; i < numberOfColumns; i++)
			{
				const char *rawColumnName = sqlite3_column_name(preparedStatement, i);
				NSString *columnName = [NSString stringWithUTF8String: rawColumnName];
				
				int datatype = sqlite3_column_type(preparedStatement, i);
				switch (datatype)
				{
					case SQLITE_INTEGER:
					{
						long long int intValue = sqlite3_column_int64(preparedStatement, i);
						
						NSNumber *intNumber = [NSNumber numberWithLongLong: intValue];
						
						[row setValue: intNumber 
							forKey: columnName];
						
						break;
					}
					
					case SQLITE_FLOAT:
					{
						double doubleValue = sqlite3_column_double(preparedStatement, i);
						
						NSNumber *doubleNumber = [NSNumber numberWithDouble: doubleValue];
						
						[row setValue: doubleNumber 
							forKey: columnName];
						
						break;
					}
					
					case SQLITE_BLOB:
					{
						const void *bytes = sqlite3_column_blob(preparedStatement, i);
						int numberOfBytes = sqlite3_column_bytes(preparedStatement, i);
						
						NSData *data = [NSData dataWithBytes: bytes 
							length: numberOfBytes];
						
						[row setValue: data 
							forKey: columnName];
						
						break;
					}
					
					case SQLITE_TEXT:
					{
						const char *rawString = (const char *)sqlite3_column_text(preparedStatement, i);
						
						NSString *string = [NSString stringWithUTF8String: rawString];
						
						[row setValue: string 
							forKey: columnName];
						
						break;
					}
				}
			}
			
			// If the transform block exists use it to transform the row into a local entity.
			if (transformBlock != nil)
			{
				id transformedRow = transformBlock(row);
				
				if (transformedRow != nil)
				{
					[rows addObject: transformedRow];
				}
			}
			else
			{
				[rows addObject: row];
			}
			
			// Iterate to the next row.
			resultCode = sqlite3_step(preparedStatement);
			
			// If either a row or done result code is not encountered while iterating through the results log an error message.
			if (resultCode != SQLITE_ROW 
				&& resultCode != SQLITE_DONE)
			{
				const char *errorMessage = sqlite3_errmsg(_database);
				
				NSLog(@"Error stepping through results of statement\n\n%@\n\n%s", 
					statement, 
					errorMessage);
			}
		}
		
		statementResult.status = FDStatementResultStatusSucceed;
		statementResult.rows = rows;
	}
	// If a row or done code was not encountered the statement must have failed.
	else
	{
		NSError *error = [self _lastError];
		
		NSLog(@"Error executing statement\n\n%@\n\n%@", 
			statement, 
			[error localizedDescription]);
		
		statementResult.status = FDStatementResultStatusFailed;
		statementResult.error = error;
	}
	
	// Destroy the prepared statement because it is no longer needed.
	sqlite3_finalize(preparedStatement);
	
	return statementResult;
}

- (NSError *)_lastError
{
	int errorCode = sqlite3_errcode(_database);
	
	const char *rawErrorMessage = sqlite3_errmsg(_database);
	NSString *errorMessage = [NSString stringWithUTF8String: rawErrorMessage];
		
	NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorMessage };
	
	NSError *error = [NSError errorWithDomain: FDSQLiteDatabaseErrorDomain 
		code: errorCode 
		userInfo: userInfo];
	
	return error;
}


@end