// *****************************************************************************
// AoMNaiLoader.xs
//
// 
// Loader file v1.0 for AoMN.
//
// Use this file's name in ai XML files to choose this personality. 
// 
// Make a copy of this file for each AI player in each scenario
// if you want to use the general-purpose AI for that player.  DO NOT make
// changes to the original copies of the other files, as they may be updated in the future.
// 
// You may edit copies of this file.  Typically, this will be done three ways.
//
// First, you may want to set parameters before the AI starts up.  For example,
// a line below would tell the AI to make Toxotes as the main unit if the
// comment slashes were removed.  The setParameters() function runs before the
// AI files do most of their initial setup work.
//
// Second, you may want to override some specific initial decisions made by the 
// AI at startup.  This is done in the setOverrides() function.  One of the 
// commented-out lines shows how to force the AI to use dwarves instead of 
// norse villagers, although that would not be good to do "as is" because the
// economy would not have enough gold without further adjustment.
//
// Finally, you could add rules at the bottom.  For example, the commented-out
// okToAgeUp rule below would set remove the age-upgrade restriction at the 20 
// minute mark.
//
// Review aomMKcv.xs to see which control variables are provided, and how and
// where to use them.
//
// *****************************************************************************

// *****************************************************************************
// 
// 
// Loader for Random personality.  
// Chooses randomly from balanced and the other 5 personalities
// *****************************************************************************


include "AoMNaiCV.xs";      // The control variable definitions
include "AoMNai.xs";        // The whole AI complex
include "AoMNaiCVFuncs.xs"; // Control Variable set functions.


// *****************************************************************************
//
// setParameters()
//
// Do most of the control variable (cv) initial declarations here.
//
// *****************************************************************************
void setParameters(void)   // This function is called from main() before init() is run.
{
   aiEcho("Starting setParameters()");
   cvDoAutoSaves = false;              // Autosaves on
   cvOkToResign = false;

// This AI randomly chooses from one of the six other personalities, and sets the 
// variables accordingly.
   int choice = -1;
   choice = aiRandInt(6);     // 0..5
   switch(choice)
   {
      case 0:  // Balanced
      {
         aiEcho("Choosing personality:  Balanced (Standard)");
         cvRushBoomSlider = 0.0;            
         cvMilitaryEconSlider = 0.0;
         cvOffenseDefenseSlider = 0.0;
         cvSliderNoise = 0.2;    
         break;
      }
      case 1:  // Aggressive Rusher (attacker)
      {
         aiEcho("Choosing personality:  Aggressive Rusher (Attacker)");
         cvRushBoomSlider = 0.9;
         cvMilitaryEconSlider = 0.9;
         cvOffenseDefenseSlider = 0.9;
         cvSliderNoise = 0.2;    
         break;
      }
      case 2:  // Aggressive Boomer (conqueror)
      {
         aiEcho("Choosing personality:  Aggressive Boomer (Conqueror)");
         cvRushBoomSlider = -0.9;
         cvMilitaryEconSlider = 0.3;
         cvOffenseDefenseSlider = 0.9;
         cvSliderNoise = 0.2; 
         break;
      }
      case 3:  // Economic Boomer (builder)
      {
         aiEcho("Choosing personality:  Economic Boomer (Builder)");
         cvRushBoomSlider = -0.9;
         cvMilitaryEconSlider = -0.9;
         cvOffenseDefenseSlider = 0.0;
         cvSliderNoise = 0.2; 
         break;
      }
      case 4:  // Defensive Rusher (defender)
      {
         aiEcho("Choosing personality:  Defensive Rusher (Defender)");
         cvRushBoomSlider = 0.9;
         cvMilitaryEconSlider = 0.9;
         cvOffenseDefenseSlider = -0.9;
         cvSliderNoise = 0.2;
         break;
      }
      case 5:  // Defensive Boomer (protector)
      {
         aiEcho("Choosing personality:  Defensive Boomer (Protector)");
         cvRushBoomSlider = -0.9;
         cvMilitaryEconSlider = 0.3;
         cvOffenseDefenseSlider = -0.9;
         cvSliderNoise = 0.1; 
         break;
      }
   }


   aiEcho("In setParameters, sliders are...");
   aiEcho("RushBoom "+cvRushBoomSlider+", MilitaryEcon "+cvMilitaryEconSlider+", OffenseDefense "+cvOffenseDefenseSlider);


}


// *****************************************************************************
//
// setOverrides()
//
// Override certain defaults here as indicated in the aomMKcv.xs file.
//
// *****************************************************************************
void setOverrides(void)    // This function is called from main() after init() is run.  Use it to 
                           // override any initial settings done in the main scripts.
{
   aiEcho("Starting setOverrides()");

   // aiSetDefaultStance(cUnitStanceDefensive); // Makes military units use defensive stance.

   // gGathererTypeID = cUnitTypeDwarf;         // Use dwarves instead of villagers...but you'd have to 
                                                // modify the early economy code to get more gold.
}






// *****************************************************************************
//
// Rules section
//
// *****************************************************************************
// Add scenario-specific rules and aiFuncs here


/*
rule okToAgeUp
active
minInterval 9  // run every 9 seconds or so 
{
   if ( (xsGetTime()/60000) < 20 )
      return;     // Not yet 20 minutes, bail out

   setMaxAge(cAge4);      // Let this player age up
   xsDisableSelf();        // Turn off this rule
}
*/

/*
rule setAge3Units
active
minInterval 5
{
   if (kbGetAge() < cAge3)
      return;
   aiEcho("Setting mix to inf/cav.");
   setNumberMilitaryUnitTypes(2);
   setMilitaryUnitPrefs(cUnitTypeHoplite, cUnitTypeHippikon);
   xsDisableSelf();
   xsEnableRule("setAge4Units");
}

rule setAge4Units
inactive
minInterval 5
{
   if (kbGetAge() < cAge4)
      return;
   aiEcho("Setting mix to cav/counterArcher/siege.");
   setNumberMilitaryUnitTypes(3);
   setMilitaryUnitPrefs(cUnitTypeHippikon, cUnitTypePeltast, cUnitTypePetrobolos);
   xsDisableSelf();
   xsEnableRule("setFinalUnits");
}

rule setFinalUnits
inactive
minInterval 5
{
   static int targetTime = -1;
   if (targetTime == -1)
      targetTime = xsGetTime() + 600000;   // 10 minutes from now

   if (xsGetTime() < targetTime)
      return;

   aiEcho("Turning off unit choices.");
   setNumberMilitaryUnitTypes();
   setMilitaryUnitPrefs();
   xsDisableSelf();
}
*/