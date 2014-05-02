// *****************************************************************************
//
// AoMNaiMilitaryManager.xs
//
// Definitions, utilities and rules to implement a general attack manager with
// unit picking, training, building production, periodic attacks, etc.
//
/*
   2003/07/09: Fixed an int/float type mismatch
   2003/07/10: Added cMilitaryManagerTrainGatherPoint to control where the trained units initially gather.
   2003/07/11: Changed maxAttackSize back to a float for consistency with other calling files.
*/
//
// *****************************************************************************

extern int gLandMilitaryManager = -1;
extern int gNavalMilitaryManager = -1;


extern const int   cMilitaryManagerNumUnitTypes = 0;   // Number of different military unit types to create, i.e. 2
extern const int   cMilitaryManagerUnitTypes = 1;      // each unit type to maintain, i.e. cUnitTypeHoplite, cUnitTypeHippikon
extern const int   cMilitaryManagerNumToMaintain = 2;  // Number to maintain for each, i.e. 30 hoplites, 10 hippikons (unit count, not pop slots)
extern const int   cMilitaryManagerTrainDelay = 3;     // Seconds to wait between training units of this type, i.e. 30 seconds per hoplite
extern const int   cMilitaryManagerNumBuildings = 4;   // Number of buidings to use for this unit type
extern const int   cMilitaryManagerMaintainPlanID = 5;   // Maintain plan for this unit type
 

extern const int   cMilitaryManagerUnitPicker = 10;          // Contains ID of unit picker
extern const int   cMilitaryManagerUnitPickerFrequency = 11; // How often to check
extern const int   cMilitaryManagerUnitPickerLastTime = 12;  // When last checked

extern const int   cMilitaryManagerBaseID = 15;              // 

extern const int   cMilitaryManagerAttackInterval = 20;      // How often to attack
extern const int   cMilitaryManagerLastAttackTime = 21;      // Last time attack plan was formed
extern const int   cMilitaryManagerAttackSize = 22;          // Pop slots to use in this attack plan
extern const int   cMilitaryManagerLastAttackPlan = 23;      // ID of last attack plan launched
extern const int   cMilitaryManagerAttackSizeMultiplier = 24;// How much attack size should scale up per wave
extern const int   cMilitaryManagerMaxAttackSize = 25;       // Attacks should never be larger than this number (pop slots)
extern const int   cMilitaryManagerAttackGatherPoint = 26;   // Where groups should form up
extern const int   cMilitaryManagerTrainGatherPoint = 27;      // Where trained units go initially

extern const int   cMilitaryManagerPlayerToAttack = 30;      // ID of player to attack, -1 means attack any enemy
extern const int   cMilitaryManagerTargetTypes = 31;         // List of target types for attack plans
extern const int   cMilitaryManagerTargetAreaGroup = 32;     // Which continent/ocean to attack, -1 means current



int initUnitPicker(string name = "error")
{
   int upID=kbUnitPickCreate(name);
   if (upID < 0)
      return(-1);

   kbUnitPickResetAll(upID);
   //1 Part Preference, 2 Parts CE, 2 Parts Cost.
   kbUnitPickSetPreferenceWeight(upID, 1.0);
   kbUnitPickSetCombatEfficiencyWeight(upID, 2.0);
   kbUnitPickSetCostWeight(upID, 2.0);

/* skip, controlled in MilitaryManager   
   //Desired number units types, buildings.
   kbUnitPickSetDesiredNumberUnitTypes(upID, numberTypes, numberBuildings, true);
   //Min/Max units and Min/Max pop.
   kbUnitPickSetMinimumNumberUnits(upID, minUnits);
   kbUnitPickSetMaximumNumberUnits(upID, maxUnits);
   kbUnitPickSetMinimumPop(upID, minPop);
   kbUnitPickSetMaximumPop(upID, maxPop);
*/
   //Default to land units.
   kbUnitPickSetAttackUnitType(upID, cUnitTypeLogicalTypeLandMilitary);

   //kbUnitPickSetGoalCombatEfficiencyType(upID, cUnitTypeLogicalTypeMilitaryUnitsAndBuildings);

   kbUnitPickSetPreferenceFactor(upID, cUnitTypeLogicalTypeLandMilitary, 0.6);
   kbUnitPickSetPreferenceFactor(upID, cUnitTypeLogicalTypeGreekHeroes, 0.0);
   kbUnitPickSetEnemyPlayerID(upID, 1);
   return(upID);
}


void mmSetUnitPicker(int mm=-1, int value=-1)
{
   aiPlanSetUserVariableInt(mm, cMilitaryManagerUnitPicker, 0, value);
}


int initMilitaryManager(bool land=true)
{
   int planID = -1;
   if (land == true)
      planID = aiPlanCreate("Land Military Manager", cPlanGoal);
   else
      planID = aiPlanCreate("Naval Military Manager", cPlanGoal);
   if (planID < 0)
      return(-1);
   aiPlanSetMilitary(planID, true);
   aiPlanSetActive(planID);
   aiPlanAddUserVariableInt(planID, cMilitaryManagerNumUnitTypes, "NumUnitTypes", 1);
   aiPlanAddUserVariableInt(planID, cMilitaryManagerUnitTypes, "UnitTypes", 1);
   aiPlanAddUserVariableInt(planID, cMilitaryManagerNumToMaintain, "NumToMaintain", 1);
   aiPlanAddUserVariableInt(planID, cMilitaryManagerTrainDelay, "TrainDelay", 1);
   aiPlanAddUserVariableInt(planID, cMilitaryManagerNumBuildings, "NumBuildings", 1);
   aiPlanAddUserVariableInt(planID, cMilitaryManagerMaintainPlanID, "MaintainPlanID", 1);
   aiPlanAddUserVariableInt(planID, cMilitaryManagerUnitPicker, "UnitPicker", 1);
   aiPlanAddUserVariableInt(planID, cMilitaryManagerUnitPickerFrequency, "UnitPickerFrequency", 1);
   aiPlanAddUserVariableInt(planID, cMilitaryManagerUnitPickerLastTime, "UnitPickerLastTime", 1);
   aiPlanAddUserVariableInt(planID, cMilitaryManagerBaseID, "BaseID", 1);
   aiPlanAddUserVariableInt(planID, cMilitaryManagerAttackInterval, "AttackInterval", 1);
   aiPlanAddUserVariableInt(planID, cMilitaryManagerLastAttackTime, "LastAttackTime", 1);
   aiPlanAddUserVariableFloat(planID, cMilitaryManagerAttackSize, "AttackSize", 1);
   aiPlanAddUserVariableInt(planID, cMilitaryManagerLastAttackPlan, "LastAttackPlan", 1);
   aiPlanAddUserVariableFloat(planID, cMilitaryManagerAttackSizeMultiplier, "AttackSizeMultiplier", 1);
   aiPlanAddUserVariableFloat(planID, cMilitaryManagerMaxAttackSize, "MaxAttackSize", 1);
   aiPlanAddUserVariableVector(planID, cMilitaryManagerAttackGatherPoint, "AttackGatherPoint", 1);
   aiPlanAddUserVariableVector(planID, cMilitaryManagerTrainGatherPoint, "TrainGatherPoint", 1);
   aiPlanAddUserVariableInt(planID, cMilitaryManagerPlayerToAttack, "PlayerToAttack", 1);
   aiPlanAddUserVariableInt(planID, cMilitaryManagerTargetTypes, "TargetTypes", 1);
   aiPlanAddUserVariableInt(planID, cMilitaryManagerTargetAreaGroup, "TargetAreaGroup", 1);

   int up = -1;
   if (land == true)
   {
      up = initUnitPicker("Land Unit Picker");
      xsEnableRule("landMilitaryManagerRule");
   }
   else
   {
      up = initUnitPicker("Naval Unit Picker");
      xsEnableRule("navalMilitaryManagerRule");
   }
   aiPlanSetUserVariableInt(planID, cMilitaryManagerUnitPicker, 0, up);
   aiPlanSetUserVariableInt(planID, cMilitaryManagerBaseID, 0, kbBaseGetMainID(cMyID));
   aiPlanSetUserVariableInt(planID, cMilitaryManagerPlayerToAttack, 0, 1);
   return(planID);
}




rule landMilitaryManagerRule
inactive
minInterval 25
{
   if (kbGetAge() < cAge2) 
      return;

   int mm = gLandMilitaryManager;
   int up = aiPlanGetUserVariableInt(mm, cMilitaryManagerUnitPicker, 0);
   // Time to check unit picker?
   int lastTime = aiPlanGetUserVariableInt(mm, cMilitaryManagerUnitPickerLastTime, 0);
   int timeElapsed = (xsGetTime()/1000) - lastTime;
   int interval = aiPlanGetUserVariableInt(mm, cMilitaryManagerUnitPickerFrequency, 0);
   int numUnitTypes = aiPlanGetUserVariableInt(mm, cMilitaryManagerNumUnitTypes, 0);
   int i=0;

   static int enemyUnitQuery = -1;
   int enemyUnitType = -1;

   if ( (up >= 0) && ( (lastTime == -1) || (timeElapsed > interval) ) )
   {  // We need to run the unitpicker

      // First, figure out what we're going to fight against
      if (enemyUnitQuery < 0)
      {
         enemyUnitQuery = kbUnitQueryCreate("EnemyUnitQuery");    
         configQuery(enemyUnitQuery, cUnitTypeLogicalTypeMilitaryUnitsAndBuildings, -1, cUnitStateAliveOrBuilding, 1);
      }
      kbUnitQueryResetResults(enemyUnitQuery);
      int count = kbUnitQueryExecute(enemyUnitQuery);
      aiEcho("Found "+count+" enemy units and buildings.");
      enemyUnitType = -1;
      int attempt = 0;
      int testUnit = -1;
      int testType = -1;
      if (count > 3)    // Make a few attempts to find a unit that is in widespread use
      {
         for(attempt = 0; < 5)
         {
            testUnit = kbUnitQueryGetResult(enemyUnitQuery, aiRandInt(count));
            testType = kbGetUnitBaseTypeID(testUnit);

            if ( kbUnitCount(1, testType, cUnitStateAliveOrBuilding) > (count/3) )  // There are a lot of these guys
            {
               enemyUnitType = testType;
               aiEcho("Targeting unit type "+testType+" "+kbGetUnitTypeName(testType));
               break;
            }
         }
      }
      kbUnitPickResetCombatEfficiencyTypes(up);
      if (enemyUnitType >= 0)
         kbUnitPickAddCombatEfficiencyType(up, enemyUnitType, 1.0);

      // Now, figure out what we're making
      kbUnitPickResetResults(up);
      kbUnitPickRun(up);
      aiPlanSetUserVariableInt(mm, cMilitaryManagerUnitPickerLastTime, 0, xsGetTime()/1000);
      aiEcho("We want "+numUnitTypes+" unit types.");

      for (i=0; < numUnitTypes)
      {
         aiEcho("    "+i+": "+kbUnitPickGetResult(up, i)+" "+kbGetUnitTypeName(kbUnitPickGetResult(up,i)) );
      }
   }


   // Check for changes. (Compare number of units to number of var slots.)  If any:
   int oldNumUnitTypes = aiPlanGetNumberUserVariableValues(mm, cMilitaryManagerUnitTypes);
   bool needReset = false;
   if (oldNumUnitTypes != numUnitTypes)
      needReset = true;
   else
   {

      for (i=0; < numUnitTypes)
      {
         if (up >= 0)
            if ( aiPlanGetUserVariableInt(mm,cMilitaryManagerUnitTypes, i) != kbUnitPickGetResult(up, i) )
               needReset = true;
      }
   }
   if (needReset == true)
   {
      aiEcho("Resetting maintain plans");
      for (i=0; < oldNumUnitTypes)  // Destroy old plans
      {
         int oldPlan = aiPlanGetUserVariableInt(mm, cMilitaryManagerMaintainPlanID, i);
         if (oldPlan >= 0)
            aiPlanDestroy(oldPlan);
         aiPlanSetUserVariableInt(mm, cMilitaryManagerMaintainPlanID, i, -1);
      }
      aiPlanSetNumberUserVariableValues(mm, cMilitaryManagerUnitTypes, numUnitTypes, false); // save the old info for non-UP cases
      aiPlanSetNumberUserVariableValues(mm, cMilitaryManagerMaintainPlanID, numUnitTypes, false);
      aiPlanSetNumberUserVariableValues(mm, cMilitaryManagerNumToMaintain, numUnitTypes, false);
   }
   for (i=0; < numUnitTypes)
   {     // Set the new info
      int unitType = 0;
      if (needReset == true)
      {
         unitType = kbUnitPickGetResult(up, i);
         aiPlanSetUserVariableInt(mm, cMilitaryManagerUnitTypes, i, unitType);
      }
      else
         unitType = aiPlanGetUserVariableInt(mm, cMilitaryManagerUnitTypes, i);

      float percent = 1.0;    // What percent of my military should this unit be?
      float iFloat = i;
      if (numUnitTypes == 2)
         percent = 0.67 / (1.0+iFloat);   // .67 or .33
      if (numUnitTypes == 3)
      {
         if (i == 0)
            percent = 0.50;
         if (i == 1)
            percent = 0.33;
         if (i == 2)
            percent = 0.17;
      }
      int numToTrain = 0;
      int planID = -1;
      numToTrain = percent * aiGetMilitaryPop();
      numToTrain = numToTrain / kbGetPopSlots(cMyID, unitType);
      aiPlanSetUserVariableInt(mm, cMilitaryManagerNumToMaintain, i, numToTrain);
      int delay = 0;
      delay = aiPlanGetUserVariableInt(mm, cMilitaryManagerTrainDelay, i);
      if ( aiPlanGetUserVariableInt(mm, cMilitaryManagerMaintainPlanID, i) < 0 )
      {
         aiEcho("   Starting train plan to make "+numToTrain+" of unit type "+kbGetUnitTypeName(unitType)+" at "+delay+" second intervals.");
         aiPlanSetUserVariableInt(mm,cMilitaryManagerMaintainPlanID, i, 
            maintainUnit( unitType, numToTrain, cInvalidVector, delay));
      }
      else
      {
         planID = aiPlanGetUserVariableInt(mm, cMilitaryManagerMaintainPlanID, i);
         aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, i, numToTrain);
         aiPlanSetVariableInt(planID, cTrainPlanFrequency, i, delay);
      }
      if (aiPlanGetUserVariableVector(mm, cMilitaryManagerTrainGatherPoint, 0) != cInvalidVector)  // We have a train gather point defined, add it to plan
      {
         planID = aiPlanGetUserVariableInt(mm, cMilitaryManagerMaintainPlanID, i);
         aiPlanSetVariableVector(planID, cTrainPlanGatherPoint, 0, aiPlanGetUserVariableVector(mm, cMilitaryManagerTrainGatherPoint, 0));
      }
   }
         
   // Check # buildings, add build plans as needed
   int k = 0;
   for (k=0; < numUnitTypes)
   {
      int numWanted = 0;      // How many do I want?
      int numExisting = 0;    // How many do I need?
      int type = 0;       // What am I training?
      int buildingType = 0;   // What building is used to train these guys?

      numWanted = aiPlanGetUserVariableInt(mm, cMilitaryManagerNumBuildings, k);
      type = aiPlanGetUserVariableInt(mm, cMilitaryManagerUnitTypes, k);
      buildingType = kbTechTreeGetUnitIDByTrain(type, cMyCiv);
      numExisting = kbUnitCount(cMyID, buildingType, cUnitStateAliveOrBuilding);

      if ( numExisting < numWanted )   // Build some
      {
	      int planID2=aiPlanCreate("SimpleBuild "+kbGetUnitTypeName(buildingType)+" "+1, cPlanBuild);
         if (planID2 < 0)
            return;
         aiPlanSetVariableInt(planID2, cBuildPlanBuildingTypeID, 0, buildingType);
         //Border layers.
	      aiPlanSetVariableInt(planID2, cBuildPlanNumAreaBorderLayers, 1, kbAreaGetIDByPosition(kbBaseGetLocation(kbBaseGetMainID(cMyID))) );
         //Priority.
         aiPlanSetDesiredPriority(planID2, 90);
         //Mil vs. Econ.
         aiPlanSetMilitary(planID2, true);
         aiPlanSetEconomy(planID2, false);
         //Escrow.
         aiPlanSetEscrowID(planID2, cMilitaryEscrowID);
         //Builders.

         if (cMyCulture == cCultureNorse)
	         aiPlanAddUnitType(planID2, cUnitTypeAbstractInfantry, 1, 1, 1);
         else
   	      aiPlanAddUnitType(planID2, kbTechTreeGetUnitIDTypeByFunctionIndex(cUnitFunctionBuilder, 0), 1, 1, 1);

         //Base ID.
         aiPlanSetBaseID(planID2, kbBaseGetMainID(cMyID));

         //Go.
         aiPlanSetActive(planID2);
      }

   }



   // Time to attack?  If so, create new attack plan

   int timeNow = -1;
   
   interval = aiPlanGetUserVariableInt(mm, cMilitaryManagerAttackInterval, 0);
   if (interval > 0)
   {
      lastTime = aiPlanGetUserVariableInt(mm, cMilitaryManagerLastAttackTime, 0);
      timeNow = xsGetTime()/1000;
      if ( (timeNow - lastTime) > interval ) // Time to attack
      {
         aiPlanSetUserVariableInt(mm, cMilitaryManagerLastAttackTime, 0, timeNow);
         int   attackID=aiPlanCreate("Attack at "+timeString(true)+" ", cPlanAttack);
         if (attackID < 0)
            return;

         if (aiPlanSetVariableInt(attackID, cAttackPlanPlayerID, 0, aiPlanGetUserVariableInt(mm, cMilitaryManagerPlayerToAttack, 0)) == false)
            return;


         if ( aiPlanGetUserVariableInt(mm, cMilitaryManagerTargetTypes, 0) < 0 )    // No targets specified, go with the defaults
         {
            aiPlanSetNumberVariableValues(attackID, cAttackPlanTargetTypeID, 3, true);
            aiPlanSetVariableInt(attackID, cAttackPlanTargetTypeID, 0, cUnitTypeUnit);
            aiPlanSetVariableInt(attackID, cAttackPlanTargetTypeID, 1, cUnitTypeBuilding);
            aiPlanSetVariableInt(attackID, cAttackPlanTargetTypeID, 2, cUnitTypeAbstractWall);
         }
         else     // Targets specified...find out how many, configure them in attack plan
         {
            int numTargetTypes = aiPlanGetNumberUserVariableValues(mm, cMilitaryManagerTargetTypes);
            aiPlanSetNumberVariableValues(attackID, cAttackPlanTargetTypeID, numTargetTypes, true);
            int j=-1;
            for (j=0; < numTargetTypes)
               aiPlanSetVariableInt(attackID, cAttackPlanTargetTypeID, j, aiPlanGetUserVariableInt(mm, cMilitaryManagerTargetTypes, j));
         }

         // Specify other continent so that armies will transport
         if ( aiPlanGetUserVariableInt(mm, cMilitaryManagerTargetAreaGroup, 0) >= 0 )
         {
            aiPlanSetNumberVariableValues( attackID, cAttackPlanTargetAreaGroups,  1, true);  
            aiPlanSetVariableInt(attackID, cAttackPlanTargetAreaGroups, 0, aiPlanGetUserVariableInt(mm, cMilitaryManagerTargetAreaGroup, 0));
         }
   
         aiPlanSetVariableFloat(attackID, cAttackPlanGatherDistance, 0, 15.0);

         float size = -1;
         size = aiPlanGetUserVariableFloat(mm, cMilitaryManagerAttackSize, 0);
         aiPlanAddUnitType(attackID, cUnitTypeLogicalTypeLandMilitary, 1, size, size);

         if (aiPlanGetUserVariableVector(mm, cMilitaryManagerAttackGatherPoint, 0) != cInvalidVector)
         {
            aiPlanSetInitialPosition(attackID, aiPlanGetUserVariableVector(mm, cMilitaryManagerAttackGatherPoint, 0));
            aiPlanSetVariableVector(attackID, cAttackPlanGatherPoint, 0, aiPlanGetUserVariableVector(mm, cMilitaryManagerAttackGatherPoint, 0));
         }
         else
            aiPlanSetInitialPosition(attackID, kbBaseGetLocation(cMyID, aiPlanGetUserVariableInt(mm, cMilitaryManagerBaseID, 0)));
         aiPlanSetRequiresAllNeedUnits(attackID, false);
         aiPlanSetDesiredPriority(attackID, 50);   // Less than scouting, more than defense
         aiPlanSetActive(attackID);
         aiEcho("Activating attack plan "+attackID+" with appx "+size+" units.");

         // Update time
         aiPlanSetUserVariableInt(mm, cMilitaryManagerLastAttackTime, 0, timeNow);

         // Update attack size, check limit
         aiPlanSetUserVariableInt(mm, cMilitaryManagerLastAttackPlan, 0, attackID);
         aiPlanSetUserVariableFloat(mm, cMilitaryManagerAttackSize, 0, size * aiPlanGetUserVariableFloat(mm,cMilitaryManagerAttackSizeMultiplier, 0));
         if ( aiPlanGetUserVariableFloat(mm, cMilitaryManagerAttackSize, 0) > aiPlanGetUserVariableFloat(mm, cMilitaryManagerMaxAttackSize, 0) )
            aiPlanSetUserVariableFloat(mm, cMilitaryManagerAttackSize, 0, aiPlanGetUserVariableFloat(mm, cMilitaryManagerMaxAttackSize, 0) );
      }
   }
}
