-- Legacy disk template still references this component. Trials no longer use the disk.

MandoSpynetContractWaypointDiskMenuComponent = {}

function MandoSpynetContractWaypointDiskMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
end

function MandoSpynetContractWaypointDiskMenuComponent:handleObjectMenuSelect(pObject, pPlayer, selectedID)
	if (pPlayer ~= nil) then
		CreatureObject(pPlayer):sendSystemMessage(
			"[Spynet trial] Coordinate disks are retired. Use the yellow Spynet bounty camp waypoint on your datapad, or speak to the operative on Corellia."
		)
	end
	return 0
end
