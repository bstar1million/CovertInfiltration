class X2StrategyElement_DefaultActivities extends X2StrategyElement;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	//
	CreateNeutralizeCommander(Templates);
	
	return Templates;
}

static function CreateNeutralizeCommander (out array<X2DataTemplate> Templates)
{
	local X2ActivityTemplate_Infiltration Activity;
	local X2CovertActionTemplate CovertAction;
	local X2RewardTemplate Reward;

	CovertAction = class'X2StrategyElement_InfiltrationActions'.static.CreateInfiltrationTemplate('CovertAction_NeutralizeCommanderInfil', true);
	Reward = class'X2StrategyElement_InfiltrationRewards'.static.CreateDummyActionRewardTemplate('ActionReward_NeutralizeCommander');
	`CREATE_X2TEMPLATE(class'X2ActivityTemplate_Infiltration', Activity, 'Activity_NeutralizeCommander');

	CovertAction.ChooseLocationFn = class'X2StrategyElement_DefaultCovertActions'.static.ChooseRandomContactedRegion;
	CovertAction.OverworldMeshPath = "UI_3D.Overwold_Final.GorillaOps"; // Yes, Firaxis did in fact call it Gorilla Ops
	
	CovertAction.Narratives.AddItem('CovertActionNarrative_NeutralizeCommanderInfil');
	CovertAction.Rewards.AddItem(Reward.DataName);

	Activity.CovertActionName = CovertAction.DataName;
}