// *****************************************************************************
//
// AoMNaiLoaderBalanced.xs
//
// Loader for balanced personality.  All sliders left at 0.0 with a +/- 0.2 variance.
//
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
   cvDoAutoSaves = true;              // Autosaves on

//   cvDelayStart = true;
   aiEcho("Original handicap: "+kbGetPlayerHandicap(cMyID));
   //kbSetPlayerHandicap(cMyID, 1.2 * kbGetPlayerHandicap(cMyID)); // 20% tougher
   aiEcho("     New handicap: "+kbGetPlayerHandicap(cMyID));

//   cvPrimaryMilitaryUnit = cUnitTypeToxotes;     // Main military unit must be toxotes
//   cvNumberMilitaryUnitTypes = 1;                // Only make one unit type, i.e. toxotes and nothing else

//   cvRushBoomSlider = (aiRandInt(201)-100);
//   cvRushBoomSlider = cvRushBoomSlider/100.0;            // Totally random, -1.0 to 1.0

//   cvMilitaryEconSlider = (aiRandInt(201)-100);
//   cvMilitaryEconSlider = cvMilitaryEconSlider/100.0;    // Random

//   cvOffenseDefenseSlider = (aiRandInt(201)-100);
//   cvOffenseDefenseSlider = cvOffenseDefenseSlider/100.0;// Random  

   cvSliderNoise = 0.2;    // This amount is added or subtracted to/from each slider for some game-to-game variety.

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
}


/*
rule startLate
active
minInterval 1
{
   if (xsGetTime() < 15000) // just a 15-second delay
      return;

   setDelayStart(true);
   xsDisableSelf();

}
*/