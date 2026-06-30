/*
 * ArchitectRetrofitOwnerConfirmSuiCallback.h
 *
 * Sent to the structure OWNER to accept or decline a retrofit proposed by an Architect.
 * Also contains the shared persistence helpers and the actual application logic used
 * by both this callback and ArchitectRetrofitSuiCallback (same-owner fast path).
 */

#ifndef ARCHITECTRETROFITOWNERCONFIRMSUICALLBACK_H_
#define ARCHITECTRETROFITOWNERCONFIRMSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/ZoneServer.h"

#include <cstdio>
#include <sys/stat.h>
#include <sys/types.h>
#ifdef _WIN32
#include <direct.h>
#endif

class ArchitectRetrofitOwnerConfirmSuiCallback : public SuiCallback {
public:
	ArchitectRetrofitOwnerConfirmSuiCallback(ZoneServer* server, BuildingObject* bld,
	                                          CreatureObject* architect, const String& type)
		: SuiCallback(server), building(bld), architect(architect), retrofitType(type) {}

	void run(CreatureObject* owner, SuiBox* sui, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelled = (eventIndex == 1);

		if (owner == nullptr || sui == nullptr)
			return;

		if (cancelled) {
			// Notify architect if still online
			if (architect != nullptr)
				architect->sendSystemMessage("The structure owner declined your Architect Retrofit request.");
			return;
		}

		// Owner accepted
		if (building == nullptr) {
			owner->sendSystemMessage("Retrofit failed: the structure no longer exists.");
			if (architect != nullptr)
				architect->sendSystemMessage("Retrofit failed: the structure no longer exists.");
			return;
		}

		Locker buildingLocker(building);

		if (isRetrofitApplied(building->getObjectID())) {
			owner->sendSystemMessage("This structure has already received its one-time Architect retrofit.");
			if (architect != nullptr)
				architect->sendSystemMessage("Retrofit failed: the structure has already been retrofitted.");
			return;
		}

		applyRetrofit(architect.get(), owner, building.get(), retrofitType);
	}

	// -----------------------------------------------------------------------
	// Shared static helpers — used here and by ArchitectRetrofitSuiCallback
	// -----------------------------------------------------------------------

	static bool isRetrofitApplied(uint64 structureOID) {
		String path = buildFilePath(structureOID);
		struct stat st;
		return ::stat(path.toCharArray(), &st) == 0;
	}

	// Applies the chosen bonus, marks the file, and notifies both parties.
	// architect may be nullptr (shouldn't normally happen, but guard anyway).
	static void applyRetrofit(CreatureObject* architect, CreatureObject* owner,
	                          BuildingObject* building, const String& retrofitType) {
		if (building == nullptr || owner == nullptr)
			return;

		String resultMsg;

		if (retrofitType == "STORAGE") {
			// 50 items per lot the structure consumes (e.g. 2-lot = +100, 5-lot = +250).
			int lots = building->getLotSize();
			if (lots < 1) lots = 1;
			int bonus = lots * 50;
			building->setStorageBonus(bonus);

			StringBuffer sb;
			sb << "Architect retrofit complete. This structure has received its one-time upgrade: "
			   << "Storage Expansion (+" << bonus << " item capacity for " << lots << " lots).";
			resultMsg = sb.toString();
		} else {
			// 25% maintenance reduction.
			// This stacks additively with the Merchant maintenance discount (20%) via the
			// separate maintenanceReduced flag — combined cap is 50% (see getMaintenanceRate).
			// We only upgrade if the structure doesn't already have a higher bonus from crafting.
			float current = building->getMaintenanceReductionBonus();
			float newBonus = (current < 25.0f) ? 25.0f : current;
			building->setMaintenanceReductionBonus(newBonus);

			resultMsg = "Architect retrofit complete. This structure has received its one-time upgrade: "
			            "Maintenance Efficiency (25% reduction, stacks with Merchant discount up to 50% combined).";
		}

		markRetrofitApplied(building->getObjectID(), retrofitType);

		owner->sendSystemMessage(resultMsg);
		if (architect != nullptr && architect != owner)
			architect->sendSystemMessage(resultMsg);

		// Admin log
		Logger log("ArchitectRetrofit");
		StringBuffer logMsg;
		logMsg << "Architect=" << (architect != nullptr ? architect->getFirstName() : "unknown")
		       << " Owner=" << owner->getFirstName()
		       << " StructureOID=" << building->getObjectID()
		       << " UpgradeType=" << retrofitType;
		if (retrofitType == "STORAGE")
			logMsg << " FinalStorageBonus=" << building->getStorageBonus()
			       << " Lots=" << building->getLotSize();
		else
			logMsg << " FinalMaintenanceReduction=" << building->getMaintenanceReductionBonus() << "pct";
		log.info(logMsg.toString(), true);
	}

private:
	ManagedReference<BuildingObject*> building;
	ManagedReference<CreatureObject*> architect;
	String retrofitType;

	static void markRetrofitApplied(uint64 structureOID, const String& type) {
		ensureDir();
		String path = buildFilePath(structureOID);
		std::FILE* f = std::fopen(path.toCharArray(), "w");
		if (f != nullptr) {
			std::fputs(type.toCharArray(), f);
			std::fclose(f);
		}
	}

	static String buildFilePath(uint64 oid) {
		String s("structure_retrofits/");
		s += String::valueOf((int64)oid);
		s += ".retrofit";
		return s;
	}

	static void ensureDir() {
		struct stat st;
		if (::stat("structure_retrofits", &st) == 0)
			return;
#ifdef _WIN32
		::_mkdir("structure_retrofits");
#else
		::mkdir("structure_retrofits", 0755);
#endif
	}
};

#endif // ARCHITECTRETROFITOWNERCONFIRMSUICALLBACK_H_
