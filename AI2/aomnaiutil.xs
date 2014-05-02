// *****************************************************************************
//
// AoMNaiUtil.xs
//
// General library utilities for scenarios
// 
//
// *****************************************************************************
//bool  configQuery( int queryID = -1, int unitType = -1, int action = -1, int state = -1, int player = -1, vector center = vector(-1,-1,-1), bool sort = false, float radius = -1 )
//bool  configQueryRelation( int queryID = -1, int unitType = -1, int action = -1, int state = -1, int playerRelation = -1, vector center = vector(-1,-1,-1), bool sort = false, float radius = -1 )
//int   getUnit3( int unitType = -1, int action = -1, vector center = vector(-1,-1,-1) )
//int   trainUnit( int unitID=-1, int qty=1, vector gatherPoint=vector(-1,-1,-1), int interval=-1)
//int   maintainUnit( int unitID=-1, int qty=1, vector gatherPoint=vector(-1,-1,-1), int interval=-1)
//int   researchTech(int techID=-1)
//int   attackRoute(string name="default attack route", string block1="", string block2="", string block3="", string block4="", string block5="")
//int getUnassignedUnitCount(vector center=vector(-1.0, -1.0, -1.0), float radius=25.0, int player=2, int unitType=cUnitTypeUnit)
//string timeString(bool trimmed=true)
//void  echoQuery(int queryID = -1)
//void initMainBase(vector center=cInvalidVector, float radius = 70.0)





// *****************************************************************************
//
// configQuery
//
// Sets up all the non-default parameters so you can config a query on a single call.
// Query must be created prior to calling, and the results reset and the query executed
// after the call.
//
// ***************************************************************************** 
bool  configQuery( int queryID = -1, int unitType = -1, int action = -1, int state = -1, int player = -1, vector center = vector(-1,-1,-1), bool sort = false, float radius = -1 )
{

   if ( queryID == -1)
   {
      return(false);
   }

   if (player != -1)
      kbUnitQuerySetPlayerID(queryID, player);
   
   if (unitType != -1)
      kbUnitQuerySetUnitType(queryID, unitType);

   if (action != -1)
      kbUnitQuerySetActionType(queryID, action);

   if (state != -1)
      kbUnitQuerySetState(queryID, state);

   if (center != vector(-1,-1,-1))
   {
      kbUnitQuerySetPosition(queryID, center);
      if (sort == true)
         kbUnitQuerySetAscendingSort(queryID, true);
      if (radius != -1)
         kbUnitQuerySetMaximumDistance(queryID, radius);
   }
   return(true);
}

// *****************************************************************************
//
// configQueryRelation
//
// Sets up all the non-default parameters so you can config a query on a single call.
// Query must be created prior to calling, and the results reset and the query executed
// after the call.
// Unlike configQuery(), this uses the PLAYER RELATION rather than the player number
//
// ***************************************************************************** 
bool  configQueryRelation( int queryID = -1, int unitType = -1, int action = -1, int state = -1, int playerRelation = -1, vector center = vector(-1,-1,-1), bool sort = false, float radius = -1 )
{

   if ( queryID == -1)
   {
      return(false);
   }

   if (playerRelation != -1)
      kbUnitQuerySetPlayerRelation(queryID, playerRelation);
   
   if (unitType != -1)
      kbUnitQuerySetUnitType(queryID, unitType);

   if (action != -1)
      kbUnitQuerySetActionType(queryID, action);

   if (state != -1)
      kbUnitQuerySetState(queryID, state);

   if (center != vector(-1,-1,-1))
   {
      kbUnitQuerySetPosition(queryID, center);
      if (sort == true)
         kbUnitQuerySetAscendingSort(queryID, true);
      if (radius != -1)
         kbUnitQuerySetMaximumDistance(queryID, radius);
   }
   return(true);
}








//==============================================================================
// getUnit3( int unitType, int action, vector center)
// 
// Returns a unit of the specified type, doing the specified action.
// Defaults = any unit, any action.
// Searches units owned by this player only, can include buildings.
// If a location is specified, the nearest matching unit is returned.
//==============================================================================

int   getUnit3( int unitType = -1, int action = -1, vector center = vector(-1,-1,-1) )
{

  	int   retVal = -1;
   int   count = -1;
	int   unitQueryID = kbUnitQueryCreate("unit");

	// Define a query to get all matching units
	if (unitQueryID != -1)
	{
		kbUnitQuerySetPlayerID(unitQueryID, cMyID);         // only my units
      if (unitType != -1)
   		kbUnitQuerySetUnitType(unitQueryID, unitType);   // only if specified
      if (action != -1)
   		kbUnitQuerySetActionType(unitQueryID, action);   // only if specified
      if (center != vector(-1,-1,-1))
      {
         kbUnitQuerySetPosition(unitQueryID, center);
         kbUnitQuerySetAscendingSort(unitQueryID, true);
      }
		kbUnitQuerySetState(unitQueryID, cUnitStateAlive);
	}
	else
   {
      return(-1);
   }

	kbUnitQueryResetResults(unitQueryID);
	count = kbUnitQueryExecute(unitQueryID);
   kbUnitQuerySetState(unitQueryID, cUnitStateBuilding);     // Add buildings in process
   count = kbUnitQueryExecute(unitQueryID);

	// Pick a unit and return its ID, or return -1.
	if ( count > 0 )
      if (center != vector(-1,-1,-1))
         retVal = kbUnitQueryGetResult(unitQueryID, 0);   // closest unit
      else
   		retVal = kbUnitQueryGetResult(unitQueryID, aiRandInt(count));	// get the ID of a random unit
	else
		retVal = -1;

	return(retVal);
}


// *****************************************************************************
//
// trainUnit
//
// Train qty units of type unitID, optionally gathering at gatherPoint and 
// training at a minimum of interval seconds apart.  Returns the planID, or -1 on failure.
// *****************************************************************************
int   trainUnit( int unitID=-1, int qty=1, vector gatherPoint=vector(-1,-1,-1), int interval=-1)
{

   if (unitID == -1)
      return(-1);
   if (qty < 1)
      return(-1);
   int planID = aiPlanCreate("Train "+qty+" "+kbGetProtoUnitName(unitID), cPlanTrain);
	if (planID >= 0)
	{
		aiPlanSetVariableInt(planID, cTrainPlanUnitType, 0, unitID);
		aiPlanSetVariableInt(planID, cTrainPlanNumberToTrain, 0, qty);
      if (interval > 0)
   		aiPlanSetVariableInt(planID, cTrainPlanFrequency, 0, interval);
      if (xsVectorGetX(gatherPoint) >= 0)
   		aiPlanSetVariableVector(planID, cTrainPlanGatherPoint, 0, gatherPoint);
		aiPlanSetActive(planID);
      return(planID);
	}
   else
      return(-1);
}




// *****************************************************************************
//
// maintainUnit
//
// Maintain a total of qty units of type unitID, optionally gathering at gatherPoint and 
// training at a minimum of interval seconds apart.  Returns the planID, or -1 on failure.
// *****************************************************************************
int   maintainUnit( int unitID=-1, int qty=1, vector gatherPoint=vector(-1,-1,-1), int interval=-1)
{

   if (unitID == -1)
      return(-1);
   if (qty < 1)
      return(-1);
   int planID = aiPlanCreate("Maintain "+qty+" "+kbGetProtoUnitName(unitID), cPlanTrain);
	if (planID >= 0)
	{
		aiPlanSetVariableInt(planID, cTrainPlanUnitType, 0, unitID);
		aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, qty);
      if (interval > 0)
   		aiPlanSetVariableInt(planID, cTrainPlanFrequency, 0, interval);
      if (xsVectorGetX(gatherPoint) >= 0)
   		aiPlanSetVariableVector(planID, cTrainPlanGatherPoint, 0, gatherPoint);
		aiPlanSetActive(planID);
      return(planID);
	}
   else
      return(-1);
}

// *****************************************************************************
//
// researchTech
// 
// Creates a research plan to research the tech at an appropriate building
//
// *****************************************************************************
int   researchTech(int techID=-1)
{
	int planID = aiPlanCreate("Research "+kbGetTechName(techID), cPlanProgression);
	if(planID < 0)
		return(-1);

	aiPlanSetVariableInt(planID, cProgressionPlanGoalTechID, 0, techID);
	aiPlanSetActive(planID);
   return(planID);
}







// *****************************************************************************
//
// attackRoute()
//
// Makes an attack route from a series of block names.  Must have 2-5 block names.
//
// *****************************************************************************
int   attackRoute(string name="default attack route", string block1="", string block2="", string block3="", string block4="", string block5="")
{
   string end="";
   int numPoints=0;

   
   // Start at block 5, find the last one
   if (block5 != "")
   {
      numPoints=5;
      end=block5;
   }
   
   if ( (block4 != "") && (numPoints == 0) )
   {
      numPoints=4;
      end=block4;
   }
  
   if ( (block3 != "") && (numPoints == 0) )
   {
      numPoints=3;
      end=block3;
   }

   if ( (block2 != "") && (numPoints == 0) )
   {
      numPoints=2;
      end=block2;
   }
   
   if ( (block1 != "") && (numPoints == 0) )
   {
      numPoints=1;
      end=block1;
   }

   if (numPoints < 2)
      return(-1);

   int pathID = kbPathCreate(name+" path");
   if (pathID < 0)
      return(-1);

   if (numPoints > 2)
       kbPathAddWaypoint(pathID, kbGetBlockPosition(block2));
   if (numPoints > 3)
       kbPathAddWaypoint(pathID, kbGetBlockPosition(block3));
   if (numPoints > 4)
       kbPathAddWaypoint(pathID, kbGetBlockPosition(block4));


   int attackRouteID = kbCreateAttackRouteWithPath(name, kbGetBlockPosition(block1), kbGetBlockPosition(end));
   if (attackRouteID < 0)
      return(-1);
   if (numPoints > 2)
   kbAttackRouteAddPath(attackRouteID, pathID);

   return(attackRouteID);
}


// *****************************************************************************
//
// int getUnassignedUnitCount(vector center, float radius, int player, int unitType)
//
// Counts the number of player's units of type unitType that don't belong to 
// a plan.  Count is limited to a distance of radius around point center.
//
// Generally used to count newly spawned units in order to set appropriate want/max
// levels for an attack plan.
// *****************************************************************************

int getUnassignedUnitCount(vector center=vector(-1.0, -1.0, -1.0), float radius=25.0, int player=2, int unitType=cUnitTypeUnit)
{
   int unassigned=0;       // Number of unassigned units found by traversing the query results
   int query=-1;           // Query to find the units of unitType within radius of center.
   int count=-1;           // Number of units found by the query.
   int i=-1;

   query = kbUnitQueryCreate("Unassigned units");
   if (query < 0)
      return(-1);

   configQuery(query, unitType, -1, cUnitStateAlive, player, center, true, radius);
   kbUnitQueryResetResults(query);
   count = kbUnitQueryExecute(query);

   for (i=0; <count)
   {
      if (kbUnitGetPlanID(kbUnitQueryGetResult(query,i)) == -1)      // if not a member of a plan...
         unassigned = unassigned + 1;
   }
   return(unassigned);
}





// *****************************************************************************
//
// string timeString(bool trimmed=true)
// 
// Returns the current time in h:mm:ss format.  If trimmed is true, it suppresses
// leading spaces or zeros.  If false, string is always 7 characters.  
// Not responible for games over 10 hours.  ;-)
//
// *****************************************************************************
string timeString(bool trimmed=true)
{
   int hour = 0;
   int min = 0;
   int sec = 0;
   int time = 0;
   string retval = "";

   time = xsGetTime()/1000;   // Seconds
   hour = time/3600;
   time = time - (hour*3600);
   min = time/60;
   time = time -(min*60);
   sec = time;

   if (trimmed == true)
   {
      if (hour > 0)     // start with h:
      {
         retval = hour+":";
         if (min >= 10)
            retval = retval+min+":";
         else
            retval = retval+0+min+":";
         if (sec >=10)
            retval = retval+sec;
         else
            retval = retval+0+sec;
      }
      else
      {                 // start with min
         retval = min+":";
         if (sec >=10)
            retval = retval+sec;
         else
            retval = retval+0+sec;
      }
   }
   else  // non-trimmed
   {
      retval = hour+":";
     if (min >= 10)
         retval = retval+min+":";
      else
         retval = retval+0+min+":";
      if (sec >=10)
         retval = retval+sec;
      else
         retval = retval+0+sec;
   }
   return(retval);
}



/*
// *****************************************************************************
//
// build(int BuildingID, int areaID) 
//
// *****************************************************************************

int build(int building=-1, int escrow=0, int areaID=-1)
{
   int plan=aiPlanCreate("Build "+kbGetProtoUnitName(building), cPlanProgression);
   if (plan < 0)
      return(-1);

   //Set it for the building that we get our unit from.
   aiPlanSetVariableInt(plan, cProgressionPlanGoalUnitID, 0, building);
   //Build it in our town.
   aiPlanSetVariableInt(plan, cProgressionPlanBuildAreaID, 0, areaID);
   //Go.
   aiPlanSetActive(plan);
   return(plan);
}
*/




// *****************************************************************************
//
// echoQuery(int queryID)
//
// aiEchos the list of items in the query result space, with ID numbers and unit types.
//
// *****************************************************************************
void  echoQuery(int queryID = -1)
{
   if (queryID < 0)
   {
      aiEcho("Invalid query");
      return;
   }

   int i = 0;
   int id = 0;
   for (i=0; < kbUnitQueryNumberResults(queryID))
   {
      id = kbUnitQueryGetResult(queryID, i);
      aiEcho("    "+id+" ("+kbGetProtoUnitName(kbGetUnitBaseTypeID(id))+")");
   }

}




// *****************************************************************************
//
// Destroy bases, start over
//
// *****************************************************************************
int initMainBase(vector center=cInvalidVector, float radius=70.0)
{
   // Nuke bases, add one base to rule them all
   kbBaseDestroyAll(cMyID);

   int mainBase = kbBaseCreate(cMyID, "Base "+kbBaseGetNextID(), center, radius);
   if (mainBase < 0)
   {
      aiEcho("***** Main base creation failed. *****");
      return(-1);
   }

   vector baseFront=xsVectorNormalize(kbGetMapCenter()-kbBaseGetLocation(cMyID, mainBase));     // Set front
   kbBaseSetFrontVector(cMyID, mainBase, baseFront);       
	kbBaseSetMilitaryGatherPoint(cMyID, mainBase, (baseFront*25.0) + kbBaseGetLocation(cMyID, mainBase) );
   kbBaseSetMaximumResourceDistance(cMyID, mainBase, radius+20);                    // Gather up to 20m beyond base perimeter
   kbBaseSetMain(cMyID, mainBase, true);     // Make this the main base

   // Add the buildings
   int buildingQuery = -1;
   int count = 0;
   buildingQuery = kbUnitQueryCreate("Building Query");     // All buildings in the base
   configQuery(buildingQuery, cUnitTypeBuilding, -1, cUnitStateAliveOrBuilding, cMyID, center, false, radius);
   kbUnitQueryResetResults(buildingQuery);
   count = kbUnitQueryExecute(buildingQuery);

   int i = 0;
   int buildingID = -1;
   for (i=0; < count)
   {
      buildingID = kbUnitQueryGetResult(buildingQuery, i);
      // Add it to the base
      kbBaseAddUnit( cMyID, mainBase, buildingID );
   }

   kbSetTownLocation(center);

   return(mainBase);
}