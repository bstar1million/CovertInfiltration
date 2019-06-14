//---------------------------------------------------------------------------------------
//  AUTHOR:  Xymanek
//  PURPOSE: Represents an activity chain and acts as the centerpiece for invoking all
//           callbacks and maintaing progress. Note that currently the finished chains
//           are not deleted
//---------------------------------------------------------------------------------------
//  WOTCStrategyOverhaul Team
//---------------------------------------------------------------------------------------

class XComGameState_ActivityChain extends XComGameState_BaseObject;

enum EActivityChainEndReason
{	
	eACER_Complete, // The activity has run out of stages to throw at the player
	eACER_ProgressBlocked, // X2ActivityTemplate::ShouldProgressChain returned false. Check current stage for why that happened
};

var protected name m_TemplateName;
var protected X2ActivityChainTemplate m_Template;

// Matches 1:1 with X2ActivityChainTemplate::Stages
// Note that all stages are created when the chain is created
var array<StateObjectReference> StageRefs;

// References to objects that this chain is about
// For example: reward units, dark event, etc
var array<StateObjectReference> ChainObjectRefs;

// The faction associated with this chain, if any
var protectedwrite StateObjectReference FactionRef;

// Region(s) where this chain is taking place
var protectedwrite StateObjectReference PrimaryRegionRef;
var protectedwrite StateObjectReference SecondaryRegionRef;

// Progress tracking
var protectedwrite int iCurrentStage;
var protectedwrite bool bEnded;
var protectedwrite EActivityChainEndReason EndReason;

////////////////
/// Template ///
////////////////

static function X2StrategyElementTemplateManager GetMyTemplateManager()
{
	return class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
}

simulated function name GetMyTemplateName()
{
	return m_TemplateName;
}

simulated function X2ActivityChainTemplate GetMyTemplate()
{
	if (m_Template == none)
	{
		m_Template = X2ActivityChainTemplate(GetMyTemplateManager().FindStrategyElementTemplate(m_TemplateName));
	}

	return m_Template;
}

////////////////
/// Creation ///
////////////////

event OnCreation (optional X2DataTemplate Template)
{
	super.OnCreation(Template);

	m_Template = X2ActivityChainTemplate(Template);
	m_TemplateName = Template.DataName;
}

function SetupChain (XComGameState NewGameState)
{
	local X2StrategyElementTemplateManager TemplateManager;
	local XComGameState_Activity ActivityState;
	local X2ActivityTemplate ActivityTemplate;
	local StateObjectReference ActivityRef;
	local name ActivityTemplateName;
	local int i;

	`CI_Trace("Setting up chain" @ m_TemplateName);

	TemplateManager = GetMyTemplateManager();
	GetMyTemplate();

	// First, we choose the faction. Stages or regions may need this during setup
	if (m_Template.ChooseFaction != none)
	{
		FactionRef = m_Template.ChooseFaction(self);
	}

	// Next, choose the region(s). Stages may need this during setup
	if (m_Template.ChooseRegions != none)
	{
		m_Template.ChooseRegions(self, PrimaryRegionRef, SecondaryRegionRef);
	}

	`CI_Trace("Selected faction and regions, spawning stages");

	// Craete the stages
	StageRefs.Length = m_Template.Stages.Length;

	foreach m_Template.Stages(ActivityTemplateName, i)
	{
		ActivityTemplate = X2ActivityTemplate(TemplateManager.FindStrategyElementTemplate(ActivityTemplateName));

		if (ActivityTemplate != none)
		{
			ActivityState = XComGameState_Activity(NewGameState.CreateNewStateObject(ActivityTemplate.StateClass, ActivityTemplate));
			ActivityState.ChainRef = GetReference();
			ActivityState.OnEarlySetup(NewGameState);

			StageRefs[i] = ActivityState.GetReference();
		}
	}

	`CI_Trace("Spawned stages, calling lifecycle callbacks");

	// First the chain callback
	if (m_Template.SetupChain != none)
	{
		m_Template.SetupChain(NewGameState, self);
	}

	// Then the callbacks on the stages
	foreach StageRefs(ActivityRef)
	{
		ActivityState = XComGameState_Activity(NewGameState.GetGameStateForObjectID(ActivityRef.ObjectID));
		ActivityState.OnSetupChain(NewGameState);
	}

	`CI_Trace("Chain setup complete");
}

////////////////
/// Progress ///
////////////////

function StartNextStage (XComGameState NewGameState)
{
	local XComGameState_Activity ActivityState;

	if (bEnded)
	{
		`RedScreen("StartNextStage called but the chain has ended already");
		return;
	}

	iCurrentStage++;

	`CI_Trace("Starting stage" @ iCurrentStage @ "of" @ m_TemplateName);

	ActivityState = GetCurrentActivity();
	ActivityState.SetupStage(NewGameState);

	GetMyTemplate();
	if (m_Template.PostStageSetup != none)
	{
		m_Template.PostStageSetup(NewGameState, ActivityState);
	}
}

function CurrentStageHasCompleted (XComGameState NewGameState)
{
	local XComGameState_Activity ActivityState;
	local StateObjectReference ActivityRef;

	`CI_Trace(m_TemplateName @ "current stage has reported completion, processing chain reaction");

	// Check if can progress
	if (iCurrentStage < StageRefs.Length - 1)
	{
		`CI_Trace("Still more stages avaliable");

		ActivityState = GetCurrentActivity();

		if (ActivityState.ShouldProgressChain())
		{
			`CI_Trace("Progression not blocked by stage template");
			StartNextStage(NewGameState);
		}
		else
		{
			`CI_Trace("Progression blocked by stage template");

			bEnded = true;
			EndReason = eACER_ProgressBlocked;
		}
	}
	else
	{
		`CI_Trace("No more stages avaliable");

		bEnded = true;
		EndReason = eACER_Complete;
		iCurrentStage++; // Do not get stuck on the last stage
	}

	if (bEnded)
	{
		`CI_Trace("Chain ended, calling lifecycle callbacks");

		// First call callbacks on the stages
		foreach StageRefs(ActivityRef)
		{
			ActivityState = XComGameState_Activity(NewGameState.GetGameStateForObjectID(ActivityRef.ObjectID));
			ActivityState.OnCleanupChain(NewGameState);
		}

		// Then on the chain
		GetMyTemplate();
		if (m_Template.CleanupChain != none)
		{
			m_Template.CleanupChain(NewGameState, self);
		}
	}

	`CI_Trace("Finished handling stage completion");
}

///////////////
/// Helpers ///
///////////////

function bool HasStarted ()
{
	return iCurrentStage > -1;
}

function bool IsCompleted ()
{
	return bEnded && EndReason == eACER_Complete;
}

function XComGameState_Activity GetCurrentActivity ()
{
	return XComGameState_Activity(`XCOMHISTORY.GetGameStateForObjectID(StageRefs[iCurrentStage].ObjectID));
}

function XComGameState_ResistanceFaction GetFaction()
{
	return XComGameState_ResistanceFaction(`XCOMHISTORY.GetGameStateForObjectID(FactionRef.ObjectID));
}

function XComGameState_WorldRegion GetPrimaryRegion ()
{
	return XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(PrimaryRegionRef.ObjectID));
}

function XComGameState_WorldRegion GetSecondaryRegion ()
{
	return XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(SecondaryRegionRef.ObjectID));
}

defaultproperties
{
	iCurrentStage = -1;
}