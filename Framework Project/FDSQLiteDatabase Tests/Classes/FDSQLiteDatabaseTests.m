@import XCTest;

@import FDSQLiteDatabase;


@interface FDSQLiteDatabaseTests : XCTestCase

@end

@implementation FDSQLiteDatabaseTests

- (void)testExample
{
	XCTAssertNotNil([FDSQLiteDatabase new]);
}

@end
