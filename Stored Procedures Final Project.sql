CREATE PROCEDURE uspUpdatePilot
     @intPilotID				AS INTEGER 
    ,@strFirstName				AS VARCHAR(255)
    ,@strLastName				AS VARCHAR(255)
    ,@strEmployeeID				AS VARCHAR(255)
	,@dtmDateofHire				AS DATETIME
	,@dtmDateofTermination		AS DATETIME
	,@dtmDateofLicense			AS DATETIME
	,@intPilotRoleID			AS INTEGER
       
AS
SET XACT_ABORT ON --terminate and rollback if any errors
BEGIN TRANSACTION
  
    Update  TPilots
			SET strFirstName =	@strFirstName, 
			    strLastName =	@strLastName,
				strEmployeeID =	@strEmployeeID, 
				dtmDateOfHire = @dtmDateofHire,
				dtmDateOfTermination = @dtmDateofTermination,
				dtmDateOfLicense = @dtmDateofLicense,
				intPilotRoleID = @intPilotRoleID
			
	WHERE  intPilotID = @intPilotID
COMMIT TRANSACTION
GO
CREATE PROCEDURE uspUpdateEmployee
 	 @strLoginID		AS VARCHAR(255)
	,@strPassword		AS VARCHAR(255)
	,@intEmployeeRoleID AS INTEGER
	,@intEmployeeID		AS INTEGER
       
AS
SET XACT_ABORT ON --terminate and rollback if any errors
BEGIN TRANSACTION
  
    Update  TEmployees
			SET strLoginID = @strLoginID
			,strPassword = @strPassword
			,intEmployeeRoleID = @intEmployeeRoleID
			
			
	WHERE  intEmployeeID = @intEmployeeID
COMMIT TRANSACTION
GO
CREATE PROCEDURE uspUpdateAttendant
	@intAttendantID AS INTEGER
	 ,@strFirstName AS VARCHAR(255)
     ,@strLastName AS VARCHAR(255)
     ,@strEmployeeID AS VARCHAR(255)
     ,@dtmDateofHire AS DATETIME
     ,@dtmDateofTermination AS DATETIME
                      
       
AS
SET XACT_ABORT ON --terminate and rollback if any errors
BEGIN TRANSACTION
  
    Update  TAttendants
			SET strFirstName =	@strFirstName, 
			    strLastName =	@strLastName,
				strEmployeeID =	@strEmployeeID, 
				dtmDateOfHire = @dtmDateofHire,
				dtmDateOfTermination = @dtmDateofTermination
	WHERE  intAttendantID = @intAttendantID
COMMIT TRANSACTION
GO
CREATE PROCEDURE uspUpdateAdmin
     @intAttendantID				AS INTEGER 
    ,@strFirstName				AS VARCHAR(255)
    ,@strLastName				AS VARCHAR(255)
    ,@strEmployeeID				AS VARCHAR(255)
	,@dtmDateofHire				AS DATETIME
	,@dtmDateofTermination		AS DATETIME
	
AS
SET XACT_ABORT ON --terminate and rollback if any errors
BEGIN TRANSACTION
  
    Update  TAttendants
			SET strFirstName =	@strFirstName, 
			    strLastName =	@strLastName,
				strEmployeeID =	@strEmployeeID, 
				dtmDateOfHire = @dtmDateofHire,
				dtmDateOfTermination = @dtmDateofTermination

	WHERE  intAttendantID = @intAttendantID
COMMIT TRANSACTION
GO
CREATE PROCEDURE uspSelectPilotFutureFlights 
				@intPilotID AS INTEGER
AS
BEGIN
SELECT dtmFlightDate, strFlightNumber,  dtmTimeofDeparture, dtmTimeOfLanding, intMilesFlown, intPlaneID
            FROM TFlights as TF join TPilotFlights as TPF
            ON TF.intFlightID = TPF.intFlightID 
            JOIN TPilots as TP
            ON TP.intPilotID = TPF.intPilotID 
            WHERE TP.intPilotID = @intPilotID and GETDATE() < dtmFlightDate
            ORDER BY dtmFlightDate
END
GO
CREATE PROCEDURE uspSelectEmployee(@intEmployeeID AS INTEGER)
AS 
BEGIN
	SELECT strLoginID, strPassword
    FROM TEmployees 
	WHERE intEmployeeID = @intEmployeeID
END;
GO
CREATE PROCEDURE uspSelectAttendant(@intAttendantID AS INTEGER)
AS 
BEGIN
	SELECT intAttendantID, strFirstName, strLastName, strEmployeeID, dtmDateofHire, dtmDateofTermination
    FROM TAttendants 
	WHERE intAttendantID = @intAttendantID
END;
GO
CREATE PROCEDURE uspPilotPastMiles(@intPilotID AS INTEGER)
AS 
BEGIN
	SELECT SUM(intMilesFlown) as MilesTotal 
          From TFlights As TF Join TPilotFlights as TPF 
            On TF.intFlightID = TPF.intFlightID 
            Join TPilots As TP 
            On TP.intPilotID = TPF.intPilotID 
            WHERE TP.intPilotID = @intPilotID and GETDATE() > dtmFlightDate
END;
GO
CREATE PROCEDURE uspPilotPastFlights(@intPilotID AS INTEGER)
AS 
BEGIN
	SELECT dtmFlightDate, strFlightNumber,  dtmTimeofDeparture, dtmTimeOfLanding, intMilesFlown, intPlaneID
       FROM TFlights as TF join TPilotFlights as TPF
       ON TF.intFlightID = TPF.intFlightID 
       JOIN TPilots as TP 
       ON TP.intPilotID = TPF.intPilotID 
       WHERE TP.intPilotID = @intPilotID and GETDATE() > dtmFlightDate ORDER BY dtmFlightDate
END;
GO
CREATE PROCEDURE uspPilotInfo
AS 
BEGIN
	SELECT TP.strFirstName, TP.strLastName, TP.intPilotID, ISNULL(SUM(intMilesFlown), 0) as TotalMiles
    FROM TPilots as TP LEFT JOIN TPilotFlights as TPF
    ON TP.intPilotID = TPF.intPilotID
    LEFT JOIN TFlights as TF 
    ON TF.intFlightID = TPF.intFlightID
    GROUP BY TP.intPilotID, TP.strFirstName, TP.strLastName
END;
GO
CREATE PROCEDURE uspPassengerPreviousFlights
-- this procedure gets the passenger previous flights
			@intPassengerID AS INTEGER
AS
BEGIN
	SELECT COUNT(TFlightPassengers.intFlightID) as intPassengerCount
	FROM TFlightPassengers JOIN TFlights
	ON TFlights.intFlightID = TFlightPassengers.intFlightID
	WHERE dtmFlightDate < GETDATE() and intPassengerID = @intPassengerID
END
GO
CREATE PROCEDURE uspLogin
			@strLoginID			AS VARCHAR(255)	
			,@strPassword		AS VARCHAR(255)
AS 
BEGIN
	SELECT intPassengerID
	FROM TPassengers
	WHERE strLoginID = @strLoginID and
	strPassword = @strPassword
END;
GO
CREATE PROCEDURE uspInsertPilottoFlight
     @intPKID					AS INTEGER OUTPUT
    ,@intPilotSelectedIndex		AS INTEGER 
    ,@intFlightSelectedValue	AS INTEGER 
   
       
AS
SET XACT_ABORT ON --terminate and rollback if any errors
BEGIN TRANSACTION
    SELECT @intPKID = MAX(intPilotFlightID) + 1 
    FROM TPilotFlights (TABLOCKX) -- lock table until end of transaction
    -- default to 1 if table is empty
    SELECT @intPKID = COALESCE(@intPKID, 1)
    INSERT INTO TPilotFlights ( intPilotFlightID, intPilotID, intFlightID)
    VALUES (@intPKID, @intPilotSelectedIndex + 1, @intFlightSelectedValue)

COMMIT TRANSACTION
GO
CREATE PROCEDURE uspGetName
AS 
BEGIN
	SELECT intPassengerID, strFirstName + ' ' + strLastName as PassengerName 
	FROM TPassengers
	ORDER BY strFirstName
END;
GO
CREATE PROCEDURE uspGetEmpID
     @strLoginID			AS VARCHAR(255)	
	,@strPassword			AS VARCHAR(255)	
AS 
BEGIN
	SELECT intEmployeeID
	FROM TEmployees
	WHERE @strLoginID = strLoginID and
	@strPassword = strPassword
END
GO
CREATE PROCEDURE uspGetAge
				@intPassengerID AS INTEGER
AS 
BEGIN
	SELECT FLOOR(DATEDIFF(DAY, dtmDateOfBirth, GetDate()) / 365.25) as Age
	FROM TPassengers
	WHERE intPassengerID = @intPassengerID
END
GO
CREATE PROCEDURE uspFlightCostPassengerCount
-- This procedure will get the amount of people who have booked this flight
		@intFlightID AS INTEGER
AS
BEGIN
	SELECT COUNT(intPassengerID) as intPassengerCount
	FROM TFlightPassengers
	WHERE intFlightID = @intFlightID
END
GO
CREATE PROCEDURE uspFlightCost
-- this procedure gets some of the information needed to calculate the flight cost from the TFlights table
			@intFlightID AS INTEGER
AS
BEGIN
	SELECT intMilesFlown, intPlaneID, intToAirportID
	FROM TFlights
	WHERE intFlightID = @intFlightID
END
GO
CREATE PROCEDURE uspEmployeeLogin
			@strLoginID			AS VARCHAR(255)	
			,@strPassword		AS VARCHAR(255)
AS 
BEGIN
	SELECT intEmployeeID, intEmployeeRoleID, intPilotID, intAttendantID
	FROM TEmployees left JOIN TPilots
	ON TEmployees.intEmployeeID = TPilots.strEmployeeID
	left JOIN TAttendants 
	ON TEmployees.intEmployeeID = TAttendants.strEmployeeID
	WHERE strLoginID = @strLoginID and
	strPassword = @strPassword
END;
GO
CREATE PROCEDURE uspDeletePilot
     @intPilotID				AS INTEGER  
    
       
AS
SET XACT_ABORT ON --terminate and rollback if any errors
BEGIN TRANSACTION
  
    Delete  FROM TPilots
	WHERE  intPilotID = @intPilotID

COMMIT TRANSACTION
GO
CREATE PROCEDURE uspAttendantInfo
AS 
BEGIN
	SELECT TA.strFirstName, TA.strLastName, TA.intAttendantID, ISNULL(SUM(intMilesFlown), 0) as TotalMiles
			FROM TAttendants as TA LEFT JOIN TAttendantFlights as TAF
            ON TA.intAttendantID = TAF.intAttendantID
            LEFT JOIN TFlights as TF 
            ON TF.intFlightID = TAF.intFlightID
            GROUP BY TA.intAttendantID, TA.strFirstName, TA.strLastName
END;
GO
CREATE PROCEDURE uspAddFlight
    @intFlightID			AS INTEGER	OUTPUT		
	,@dtmFlightDate			AS DATETIME
	,@strFlightNumber		AS VARCHAR(255)	OUTPUT
	,@dtmTimeofDeparture	AS DATETIME
	,@dtmTimeofLanding		AS DATETIME
	,@intFromAirportID		AS INTEGER
	,@intToAirportID		AS INTEGER
	,@intMilesFlown			AS INTEGER
	,@intPlaneID			AS INTEGER 
       
AS
SET XACT_ABORT ON --terminate and rollback if any errors
BEGIN TRANSACTION
    SELECT @intFlightID = MAX(intFlightID) + 1, 
	@strFlightNumber = MAX(strFlightNumber) + 1
    FROM TFlights (TABLOCKX) -- lock table until end of transaction
    -- default to 1 if table is empty
    SELECT @intFlightID = COALESCE(@intFlightID, 1), 
		@strFlightNumber = COALESCE(@strFlightNumber, '1')
    INSERT INTO TFlights (intFlightID, dtmFlightDate, strFlightNumber,  dtmTimeofDeparture, dtmTimeOfLanding, intFromAirportID, intToAirportID, intMilesFlown, intPlaneID)
    VALUES (@intFlightID, @dtmFlightDate, @strFlightNumber, @dtmTimeofDeparture, @dtmTimeofLanding, @intFromAirportID, @intToAirportID, @intMilesFlown, @intPlaneID)
COMMIT TRANSACTION
GO
CREATE PROCEDURE uspAddEmployee
    @intEmployeePKID			AS INTEGER	OUTPUT		
	,@strLoginID			AS VARCHAR(255)	
	,@strPassword			AS VARCHAR(255)	
	,@intRoleID				AS INTEGER	
	,@intEmployeeID			AS INTEGER OUTPUT
       
AS
SET XACT_ABORT ON --terminate and rollback if any errors
BEGIN TRANSACTION
    SELECT @intEmployeePKID = MAX(intEmployeePKID) + 1, 
	@intEmployeeID = MAX(intEmployeeID) + 1
    FROM TEmployees (TABLOCKX) -- lock table until end of transaction
    -- default to 1 if table is empty
    SELECT @intEmployeePKID = COALESCE(@intEmployeePKID, 1), 
		@intEmployeeID = COALESCE(@intEmployeeID, 1)
    INSERT INTO TEmployees (intEmployeePKID, strLoginID, strPassword, intEmployeeRoleID, intEmployeeID)
    VALUES (@intEmployeePKID, @strLoginID, @strPassword, @intRoleID, @intEmployeeID)
COMMIT TRANSACTION
GO