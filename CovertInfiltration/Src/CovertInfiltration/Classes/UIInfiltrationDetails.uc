// TODO: Localise all strings!!!

class UIInfiltrationDetails extends UIScreen;

var UIPanel MainGroupContainer;
var UIBGBox MainGroupBG;

var UIX2PanelHeader ScreenHeader;
var UIPanel HeaderMilestonesSeparator;
var UIList MilestonesList;

// Even if currently the infil state is not supposed to change while this screen is up, store it like this just in case
var StateObjectReference InfiltrationRef;

simulated function InitScreen (XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	BuildScreen();
	PopulateMilestones();
}

simulated protected function BuildScreen ()
{
	// TODO: Try anchoring mid-center
	MainGroupContainer = Spawn(class'UIPanel', self);
	MainGroupContainer.bAnimateOnInit = false;
	MainGroupContainer.InitPanel('MainGroupContainer');
	MainGroupContainer.SetPosition(670, 185);
	MainGroupContainer.SetSize(550, 720);

	MainGroupBG = Spawn(class'UIBGBox', MainGroupContainer);
	MainGroupBG.bAnimateOnInit = false;
	MainGroupBG.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
	MainGroupBG.InitBG('MainGroupBG', 0, 0, MainGroupContainer.Width, MainGroupContainer.Height);

	ScreenHeader = Spawn(class'UIX2PanelHeader', MainGroupContainer);
	ScreenHeader.bAnimateOnInit = false;
	ScreenHeader.InitPanelHeader('ScreenHeader', "OVER INFILTRATION", "Operation Bang Boom (123%)");
	ScreenHeader.SetHeaderWidth(MainGroupBG.Width - 20);
	ScreenHeader.SetPosition(MainGroupBG.X + 10, MainGroupBG.Y + 10);

	// Slightly modified version of class'UIUtilities_Controls'.static.CreateDividerLineBeneathControl
	HeaderMilestonesSeparator = Spawn(class'UIPanel', MainGroupContainer);
	HeaderMilestonesSeparator.bAnimateOnInit = false;
	HeaderMilestonesSeparator.InitPanel('HeaderMilestonesSeparator', class'UIUtilities_Controls'.const.MC_GenericPixel);
	HeaderMilestonesSeparator.SetPosition(ScreenHeader.X, ScreenHeader.Y + ScreenHeader.height - 4); 
	HeaderMilestonesSeparator.SetSize(ScreenHeader.headerWidth, 2);
	HeaderMilestonesSeparator.SetColor(class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR);
	HeaderMilestonesSeparator.SetAlpha(30);

	MilestonesList = Spawn(class'UIList', MainGroupContainer);
	MilestonesList.bAnimateOnInit = false;
	MilestonesList.ItemPadding = 5;
	MilestonesList.InitList('MilestonesList');
	MilestonesList.SetPosition(HeaderMilestonesSeparator.X, HeaderMilestonesSeparator.Y + 10);
	MilestonesList.SetWidth(HeaderMilestonesSeparator.Width);
}

simulated protected function PopulateMilestones ()
{
	local UIInfiltrationDetails_Milestone Milestone;

	Milestone = Spawn(class'UIInfiltrationDetails_Milestone', MilestonesList.ItemContainer);
	Milestone.InitMilestone();

	Milestone = Spawn(class'UIInfiltrationDetails_Milestone', MilestonesList.ItemContainer);
	Milestone.InitMilestone();
}

/////////////
/// Input ///
/////////////

simulated function bool OnUnrealCommand (int cmd, int arg)
{
	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	switch (cmd)
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			CloseScreen();
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	InputState = eInputState_Consume
}