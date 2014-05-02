//==============================================================================
// BASICVC.xs
//
// A really, really simple victory condition script.
//==============================================================================

// this rule checks if a player's units are all dead
// run this every ~4 seconds.
// this rule operates in all gameplay modes (it is the definition of conquest victory)
rule BasicVC1
   minInterval 4
   maxInterval 5
   active
{
   // never fire VCs instantly
   if (trTimeMS() < 10000)
      return;

   int prevPlayer = xsGetContextPlayer();

   //Iterate over the players.
   for (i=1; < cNumberPlayers)
   {
      xsSetContextPlayer(i);
      //Don't check players who have already lost
      if (kbHasPlayerLost(i) == false)
      {
         int count = 0;
         count = count + kbUnitCount(i, cUnitTypeLogicalTypeNeededForVictory, cUnitStateAlive);

         //If we don't have any, this player is done.
         if (count <= 0)
         {
            //trEcho("You have lost, Player #"+i+".  You suxor.");
            
            trSetPlayerDefeated(i); // note that this func must be called synchronously on all machines
         }
      }
   }

   xsSetContextPlayer(prevPlayer);
}


// this rule checks to see if there are enemies left in the game, if not it ends the game
// we run this rule pretty quickly since it should be responsive when you win
rule BasicVC2
   minInterval 1
   maxInterval 1
   active
{
   // never fire VCs instantly
   if (trTimeMS() < 10000)
      return;

   if (kbIsGameOver() == false)
   {
      vcCheckConquestVictory();
   }   
}

void checkSettlementVictory()
{
   // never fire VCs instantly
   if (trTimeMS() < 10000)
      return;

   vcCheckSettlementVictory(120); 
}


void checkWonderVictory()
{
   // never fire VCs instantly
   if (trTimeMS() < 10000)
      return;

   int prevPlayer = xsGetContextPlayer();

   // go through all players and look for wonder timers to start
   // note the actual wonder countdown, etc is handled in C code
   // this trigger's responsibility is just starting things up
   for (p=1; < cNumberPlayers)
   {
      xsSetContextPlayer(p);
      if (kbHasPlayerLost(p) == false)
      {
         int wonder = kbUnitCount(p, cUnitTypeWonder, cUnitStateAlive);
         if (wonder > 0)
            vcStartOrUpdateWonderTimer(p, "Wonder", 600);
      }
   }
   xsSetContextPlayer(prevPlayer);
}

void resignEventHandler(int plrID=1)
{
   vcCheckConquestVictory();
}

void buildingUpgradeEventHandler(int unused=1)
{
   if (kbIsGameOver() == true)
      return;

   // only apply this in supremacy (normal) and lightning
   if ((vcGetGameplayMode() != cGameModeSupremacy) && (vcGetGameplayMode() != cGameModeLightning))
      return;

   checkSettlementVictory();
}

void allianceChangeEventHandler(int unused=1)
{
   if (kbIsGameOver() == true)
      return;

   // only apply this in supremacy (normal) and lightning
   if ((vcGetGameplayMode() != cGameModeSupremacy) && (vcGetGameplayMode() != cGameModeLightning))
      return;

   checkSettlementVictory();
}

void buildingConstructedEventHandler(int unused=1)
{
   if (kbIsGameOver() == true)
      return;

   // only apply this in supremacy (normal) and lightning
   if ((vcGetGameplayMode() != cGameModeSupremacy) && (vcGetGameplayMode() != cGameModeLightning))
      return;
     
   checkWonderVictory();
}
//==============================================================================
// Generic FP Setup (last updated by invent00r - 13/11/08)
//==============================================================================
int PausingReady = 0;
int WCQid = -1;
int WCQid2 = -1;
int HDQid = -1;
int HDQid2 = -1;
int HDQid3 = -1;
rule FPsetup
 active
 runImmediately
{
  xsDisableSelf();
   if (vcGetGameplayMode() == 5) // Don't change scenario gameplay
     return;
   
   // Activate Rules!
   //xsEnableRule("consoleOff");
   xsEnableRule("HDPrevention");
   xsEnableRule("HDPreventionSlowdown");
   // Config Queries
   xsSetContextPlayer(0);
   WCQid = kbUnitQueryCreate("vcUQFG");
   kbUnitQuerySetPlayerID(WCQid, 0);
   WCQid2 = kbUnitQueryCreate("vcUQFW");
   
   HDQid = kbUnitQueryCreate("vcHDQ");
   kbUnitQuerySetPlayerID(HDQid, 0);
   kbUnitQuerySetState(HDQid, 2); // cUnitStateAlive = 2
   kbUnitQuerySetUnitType(HDQid, 875); // cUnitTypeHuntable
   kbUnitQueryExecute(HDQid);
   
   HDQid2 = kbUnitQueryCreate("vcHDQ2");
   kbUnitQuerySetPlayerID(HDQid2, 0);
   kbUnitQuerySetState(HDQid2, 4); // cUnitStateDead = 4
   kbUnitQuerySetUnitType(HDQid2, 875); // cUnitTypeHuntable
   
   HDQid3 = kbUnitQueryCreate("vcHDQ3");
   kbUnitQuerySetPlayerRelation(HDQid3, 2); // cPlayerRelationEnemy = 2
   kbUnitQuerySetState(HDQid3, 1); // cUnitStateBuilding = 1
   kbUnitQuerySetUnitType(HDQid3, 803); // cUnitTypeBuilding =
   kbUnitQuerySetMaximumDistance(HDQid3, 4); // Fat elephants
   
   // FP Footprint
   // trChatSend(0, "<color=0.7,0.7,0.9>Fan Patch is active!</color>");
}
//==============================================================================
// Removing the console while playing supremacy games - invent00r @ 06/11/08
//==============================================================================
rule consoleOff
 active
{
   gadgetUnreal("console");
   gadgetUnreal("gameprotopalette");
}
//==============================================================================
// Preventing Hunt Deletion to a certain extent - invent00r @ 13/11/08
//==============================================================================
//rule HDPrevention
// active
//highFrequency
// priority 100
//{ 
//  xsSetContextPlayer(0);
//   kbLookAtAllUnitsOnMap();
//   trUnitSelectClear();
//   kbUnitQueryResetResults(HDQid3);
//   for(i=0; <kbUnitQueryExecuteOnQuery(HDQid2, HDQid))
//   {
//      if (kbUnitGetPosition(kbUnitQueryGetResult(HDQid2, i)) != cInvalidVector)
//         if (kbUnitGetNumberWorkers(kbUnitQueryGetResult(HDQid2, i)) > 0)
//         {
//            kbUnitQuerySetPosition(HDQid3, kbUnitGetPosition(kbUnitQueryGetResult(HDQid2, i)));
//            kbUnitQueryExecute(HDQid3);
//         }
//   }
//   for(j=0; <kbUnitQueryNumberResults(HDQid3))
//      trUnitSelectByID(kbUnitQueryGetResult(HDQid3, j));
//   trUnitDelete(false);
//}
//rule HDPreventionSlowdown
// inactive
// minInterval 600
//{
//   xsSetRuleMinInterval("HDPrevention", 1);
//  xsDisableSelf();
//}

//==============================================================================
// rules for the game start - started 22-09-2013, last on 23-09-2013 (Ramasakis)
//==============================================================================
rule ExGameStart4
 active
{
   bool pl1 = ((trPlayerUnitCountSpecific(0, "Detect NOP") == 1) && trPlayerUnitCountSpecific(0, "Detect Gaia") == 1);
   bool pl2 = ((trPlayerUnitCountSpecific(0, "Detect NOP") == 2) && trPlayerUnitCountSpecific(0, "Detect Gaia") == 2);
   bool pl3 = ((trPlayerUnitCountSpecific(0, "Detect NOP") == 3) && trPlayerUnitCountSpecific(0, "Detect Gaia") == 3);
   bool pl4 = ((trPlayerUnitCountSpecific(0, "Detect NOP") == 4) && trPlayerUnitCountSpecific(0, "Detect Gaia") == 4);
   bool pl5 = ((trPlayerUnitCountSpecific(0, "Detect NOP") == 5) && trPlayerUnitCountSpecific(0, "Detect Gaia") == 5);
   bool pl6 = ((trPlayerUnitCountSpecific(0, "Detect NOP") == 6) && trPlayerUnitCountSpecific(0, "Detect Gaia") == 6);
   bool pl7 = ((trPlayerUnitCountSpecific(0, "Detect NOP") == 7) && trPlayerUnitCountSpecific(0, "Detect Gaia") == 7);
   bool pl8 = ((trPlayerUnitCountSpecific(0, "Detect NOP") == 8) && trPlayerUnitCountSpecific(0, "Detect Gaia") == 8);
   bool pl9 = ((trPlayerUnitCountSpecific(0, "Detect NOP") == 9) && trPlayerUnitCountSpecific(0, "Detect Gaia") == 9);
   bool pl10 = ((trPlayerUnitCountSpecific(0, "Detect NOP") == 10) && trPlayerUnitCountSpecific(0, "Detect Gaia") == 10);
   bool pl11 = ((trPlayerUnitCountSpecific(0, "Detect NOP") == 11) && trPlayerUnitCountSpecific(0, "Detect Gaia") == 11);
   bool pl12 = ((trPlayerUnitCountSpecific(0, "Detect NOP") == 12) && trPlayerUnitCountSpecific(0, "Detect Gaia") == 12);

   bool pl = (pl1 || pl2 || pl3 || pl4 || pl5 || pl6 || pl7 || pl8 || pl9 || pl10 || pl11 || pl12);

   if (pl)
   {
      xsEnableRule("ExGameStart3");
      xsDisableSelf();
   trChatSend(0, "<color=0.7,0.7,0.9>Console disabled and The Natives Expansion installed!</color>");
   }
}

rule ExGameStart3
 inactive
{
   bool time = ((trTime()-cActivationTime) >= 1);

   if (time)
   {
      trOverlayText("Game Starts in: 3", 1.5, -1, -1, -1);
      xsEnableRule("ExGameStart2");
      xsDisableSelf();
   }
}

rule ExGameStart2
 inactive
{
   bool time = ((trTime()-cActivationTime) >= 1);

   if (time)
   {
      trOverlayText("Game Starts in: 2", 1.5, -1, -1, -1);
      xsEnableRule("ExGameStart1");
      xsDisableSelf();
   }
}

rule ExGameStart1
 inactive
{
   bool time = ((trTime()-cActivationTime) >= 1);

   if (time)
   {
      trOverlayText("Game Starts in: 1", 1.5, -1, -1, -1);
      xsEnableRule("ExGameStart0");
      xsDisableSelf();
   }
}

rule ExGameStart0
 inactive
{
   bool time = ((trTime()-cActivationTime) >= 1);

   if (time)
   {
      trOverlayText("Game Starts Now", 1.0, -1, -1, -1);
      for (i=1; < cNumberPlayers)
      {
         trTechSetStatus(i, 1, 4);
      }
      unitTransform("Settlement Level 1","Random Settlement Level 1");
      unitTransform("Pig","Pig Creator");
      unitTransform("Goat","Goat Creator");
      unitTransform("Cow","Cow Creator");
      xsDisableSelf();
   }
}
//==============================================================================
// rules for the start - started 04-10-2013, last on 04-10-2013 (Ramasakis)
//==============================================================================

rule ExStartTut
 active
 runImmediately
{
  xsDisableSelf();

   // Instructions
   trChatSend(0, "<color=0.7,0.7,0.9>To start the game select the statue to choose a major god. AI's wont work properly. </color>");
}
