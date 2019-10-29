//---------------------------------------------------------------------------------------
//  AUTHOR:  NotSoLoneWolf
//  PURPOSE: This class contains all the Covert Action templates
//           required for the mod, both Phase 1 and Phase 2
//---------------------------------------------------------------------------------------
//  WOTCStrategyOverhaul Team
//---------------------------------------------------------------------------------------

class X2StrategyElement_InfiltrationActions extends X2StrategyElement config(Infiltration);

var config int MINIMUM_INFILTRATORS;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> CovertActions;
	
	// TODO
	CovertActions.Length = 0;
	
	return CovertActions;
}

static function X2CovertInfiltrationTemplate CreateInfiltrationTemplate(name CovertActionName, optional bool bCreateSlots=false)
{
	local X2CovertInfiltrationTemplate Template;
	local ActionFlatRiskSitRep FlatRiskSitRep;
	local int CurrentSlots, OptionalSlots, i;
	
	`CREATE_X2TEMPLATE(class'X2CovertInfiltrationTemplate', Template, CovertActionName);

	foreach class'X2Helper_Infiltration'.default.FlatRiskSitReps(FlatRiskSitRep)
	{
		Template.Risks.AddItem(FlatRiskSitRep.FlatRiskName);
	}

	if (bCreateSlots)
	{
		CurrentSlots = 0;
		OptionalSlots = 6 - default.MINIMUM_INFILTRATORS;
		
		for(i = 0; i < (OptionalSlots / 2); i++)
		{
			Template.Slots.AddItem(CreateDefaultOptionalSlot('InfiltrationStaffSlot'));
			CurrentSlots++;
		}

		for(i = 0; i < default.MINIMUM_INFILTRATORS; i++)
		{
			Template.Slots.AddItem(CreateDefaultStaffSlot('InfiltrationStaffSlot'));
			CurrentSlots++;
		}
		
		for(i = CurrentSlots; i < 6; i++)
		{
			Template.Slots.AddItem(CreateDefaultOptionalSlot('InfiltrationStaffSlot'));
		}
	}

	return Template;
}

private static function CovertActionSlot CreateDefaultStaffSlot(name SlotName)
{
	local CovertActionSlot StaffSlot;
	
	// Same as Soldier Slot, but no rewards
	StaffSlot.StaffSlot = SlotName;
	StaffSlot.bReduceRisk = false;
	
	return StaffSlot;
}

private static function CovertActionSlot CreateDefaultOptionalSlot(name SlotName, optional int iMinRank, optional bool bFactionClass)
{
	local CovertActionSlot OptionalSlot;

	OptionalSlot.StaffSlot = SlotName;
	OptionalSlot.bChanceFame = false;
	//OptionalSlot.bReduceRisk = true;
	OptionalSlot.iMinRank = iMinRank;
	OptionalSlot.bFactionClass = bFactionClass;

	return OptionalSlot;
}

private static function StrategyCostReward CreateOptionalCostSlot(name ResourceName, int Quantity)
{
	local StrategyCostReward ActionCost;
	local ArtifactCost Resources;

	Resources.ItemTemplateName = ResourceName;
	Resources.Quantity = Quantity;
	ActionCost.Cost.ResourceCosts.AddItem(Resources);
	ActionCost.Reward = 'Reward_DecreaseRisk';
	
	return ActionCost;
}
