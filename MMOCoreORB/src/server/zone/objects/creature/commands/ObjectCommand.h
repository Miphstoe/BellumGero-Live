/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef OBJECTCOMMAND_H_
#define OBJECTCOMMAND_H_

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/managers/loot/LootManager.h"
#include "server/zone/managers/crafting/CraftingManager.h"
#include "server/zone/managers/crafting/ComponentMap.h"
#include "server/zone/managers/skill/SkillModManager.h"
#include "server/zone/objects/manufactureschematic/craftingvalues/CraftingValues.h"
#include "server/zone/objects/tangible/attachment/Attachment.h"
#include "server/zone/objects/tangible/terminal/characterbuilder/CharacterBuilderTerminal.h"
#include "server/zone/objects/tangible/wearables/WearableObject.h"
#include "server/zone/objects/tangible/wearables/WearableContainerObject.h"
#include "templates/SharedTangibleObjectTemplate.h"


class ObjectCommand : public QueueCommand {
public:

	ObjectCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {

	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		StringTokenizer args(arguments.toString());

		try {
			String commandType;
			args.getStringToken(commandType);

			if (commandType.beginsWith("createitem")) {
				String objectTemplate;
				args.getStringToken(objectTemplate);

				int quantity = 1;
				int quality = 0;
				bool qualitySpecified = false;
				Vector<String> visibleComponents;

				// Preserve the original command behavior: the first numeric argument
				// after the template is still quantity/use count.
				if (args.hasMoreTokens())
					quantity = args.getIntToken();

				// The next token is quality only when the entire token is numeric.
				// Otherwise it remains the first visible-component name, preserving
				// existing createitem commands that add visible components.
				if (args.hasMoreTokens()) {
					String nextToken;
					args.getStringToken(nextToken);

					bool numericQuality = !nextToken.isEmpty();
					int firstDigit = 0;

					if (numericQuality && nextToken.charAt(0) == '-')
						firstDigit = 1;

					if (firstDigit >= nextToken.length())
						numericQuality = false;

					for (int i = firstDigit; numericQuality && i < nextToken.length(); ++i) {
						char value = nextToken.charAt(i);

						if (value < '0' || value > '9')
							numericQuality = false;
					}

					if (numericQuality) {
						quality = Integer::valueOf(nextToken);
						qualitySpecified = true;
					} else
						visibleComponents.add(nextToken);
				}

				while (args.hasMoreTokens()) {
					String visName;
					args.getStringToken(visName);
					visibleComponents.add(visName);
				}

				if (qualitySpecified && (quality < 0 || quality > 100)) {
					creature->sendSystemMessage("Quality must be between 0 and 100.");
					return INVALIDPARAMETERS;
				}

				ManagedReference<CraftingManager*> craftingManager = creature->getZoneServer()->getCraftingManager();
				if(craftingManager == nullptr) {
					return GENERALERROR;
				}

				Reference<SharedObjectTemplate*> shot = TemplateManager::instance()->getTemplate(objectTemplate.hashCode());

				if (shot == nullptr || !shot->isSharedTangibleObjectTemplate()) {
					creature->sendSystemMessage("Templates must be tangible objects, or descendants of tangible objects, only.");
					return INVALIDPARAMETERS;
				}

				SharedTangibleObjectTemplate* tangibleTemplate = dynamic_cast<SharedTangibleObjectTemplate*>(shot.get());

				if (tangibleTemplate == nullptr) {
					creature->sendSystemMessage("Unable to read the tangible template's crafting attributes.");
					return INVALIDPARAMETERS;
				}

				ManagedReference<SceneObject*> inventory = creature->getSlottedObject("inventory");

				if (inventory == nullptr || inventory->isContainerFullRecursive()) {
					creature->sendSystemMessage("Your inventory is full, so the item could not be created.");
					return INVALIDPARAMETERS;
				}

				ManagedReference<TangibleObject*> object = (server->getZoneServer()->createObject(shot->getServerObjectCRC(), 1)).castTo<TangibleObject*>();

				if (object == nullptr) {
					creature->sendSystemMessage("The object '" + commandType + "' could not be created because the template could not be found.");
					return INVALIDPARAMETERS;
				}

				Locker locker(object);

				object->createChildObjects();

				// Set Crafter name and generate serial number
				String name = "Generated with Object Command";
				object->setCraftersName(name);

				StringBuffer customName;
				customName << object->getDisplayedName() <<  " (System Generated)";

				object->setCustomObjectName(customName.toString(), false);

				String serial = craftingManager->generateSerial();
				object->setSerialNumber(serial);

				bool qualityApplied = false;
				int appliedAttributes = 0;

				if (qualitySpecified) {
					// Safe first-pass allowlist: ordinary crafted component objects.
					// These implementations consume their own template attributes and do
					// not require a ManufactureSchematic, installed child components, or
					// a live crafting session.
					bool supportedComponent = objectTemplate.contains("object/tangible/component/");

					// These component families have specialized generation semantics that
					// a single 0-100 percentage cannot safely reconstruct.
					bool specializedComponent =
						objectTemplate.contains("/component/dna/") ||
						objectTemplate.contains("/component/genetic/") ||
						objectTemplate.contains("/component/lightsaber/");

					// Socket banks require installed child modules and must not be
					// generated as quality-only empty shells.
					bool socketBankComponent = objectTemplate.contains("socket_bank");
					bool qualitySupported =
						supportedComponent &&
						!specializedComponent &&
						!socketBankComponent;

					if (qualitySupported) {
						const Vector<String>* attributes = tangibleTemplate->getExperimentalAttributes();
						const Vector<String>* groups = tangibleTemplate->getExperimentalGroups();
						const Vector<float>* minimums = tangibleTemplate->getExperimentalMin();
						const Vector<float>* maximums = tangibleTemplate->getExperimentalMax();
						const Vector<short>* precisions = tangibleTemplate->getExperimentalPrecision();

						bool validTemplateData =
							attributes != nullptr &&
							groups != nullptr &&
							minimums != nullptr &&
							maximums != nullptr &&
							precisions != nullptr &&
							groups->size() >= attributes->size() &&
							minimums->size() >= attributes->size() &&
							maximums->size() >= attributes->size() &&
							precisions->size() >= attributes->size();

						if (validTemplateData) {
							CraftingValues generatedValues;
							float qualityRatio = quality / 100.0f;

							for (int i = 0; i < attributes->size(); ++i) {
								const String& attribute = attributes->get(i);

								// Positional fillers and session-dependent values are not
								// synthesized by the admin quality command.
								if (attribute.isEmpty() ||
									attribute == "null" ||
									attribute == "useCount" ||
									attribute == "sockets") {
									continue;
								}

								const String& group = groups->get(i);
								float minimum = minimums->get(i);
								float maximum = maximums->get(i);
								int precision = precisions->get(i);
								bool hidden = group.isEmpty() || group == "null";

								generatedValues.addExperimentalAttribute(
									attribute,
									group,
									minimum,
									maximum,
									precision,
									hidden,
									1
								);

								float generatedValue = minimum + ((maximum - minimum) * qualityRatio);

								generatedValues.setCurrentValue(
									attribute,
									generatedValue,
									minimum,
									maximum
								);

								generatedValues.setCurrentPercentage(
									attribute,
									qualityRatio,
									1.0f
								);

								++appliedAttributes;
							}

							if (appliedAttributes > 0) {
								try {
									object->updateCraftingValues(&generatedValues, true);
									qualityApplied = true;
								} catch (Exception& e) {
									object->destroyObjectFromDatabase(true);
									creature->sendSystemMessage("The item could not safely accept generated crafting values.");
									return GENERALERROR;
								}
							}
						}

						if (qualityApplied) {
							creature->sendSystemMessage(
								"Generated component at " + String::valueOf(quality) +
								"% quality using " + String::valueOf(appliedAttributes) +
								" crafting attribute(s)."
							);
						} else {
							creature->sendSystemMessage(
								"This component has no compatible crafting-quality attributes. The item was created normally."
							);
						}
					} else if (socketBankComponent) {
						creature->sendSystemMessage(
							"Quality is not supported for socket-bank shells. The item was created normally."
						);
					} else {
						creature->sendSystemMessage(
							"Quality is not supported for this object type. The item was created normally."
						);
					}
				}

				// Quantity remains independent of generated quality and retains the
				// original command's 1-100 behavior.
				if(quantity > 1 && quantity <= 100)
					object->setUseCount(quantity);

				// Load visible components.
				for (int i = 0; i < visibleComponents.size(); ++i) {
					const String& visName = visibleComponents.get(i);
					uint32 visId = visName.hashCode();

					if (ComponentMap::instance()->getFromID(visId).getId() == 0)
						continue;

					object->addVisibleComponent(visId, false);
				}

				if (inventory->transferObject(object, -1, true)) {
					inventory->broadcastObject(object, true);
					creature->info(true) << "/object createitem " << objectTemplate << " created oid: " << object->getObjectID() << " \"" << object->getDisplayedName() << "\"";

					if (qualityApplied)
						creature->info(true) << " quality=" << quality;
				} else {
					object->destroyObjectFromDatabase(true);
					creature->sendSystemMessage("Error transferring object to inventory.");
				}
			} else if (commandType.beginsWith("createwearable")) {
				// Like createitem, but sets SEA socket count (createitem leaves sockets at 0).
				String objectTemplate;
				args.getStringToken(objectTemplate);
				int maxSockets = WearableObject::MAXSOCKETS;
				if (args.hasMoreTokens())
					maxSockets = args.getIntToken();

				ManagedReference<CraftingManager*> craftingManager = creature->getZoneServer()->getCraftingManager();
				if (craftingManager == nullptr) {
					return GENERALERROR;
				}

				Reference<SharedObjectTemplate*> shot = TemplateManager::instance()->getTemplate(objectTemplate.hashCode());

				if (shot == nullptr || !shot->isSharedTangibleObjectTemplate()) {
					creature->sendSystemMessage("Templates must be tangible objects, or descendants of tangible objects, only.");
					return INVALIDPARAMETERS;
				}

				ManagedReference<SceneObject*> inventory = creature->getSlottedObject("inventory");

				if (inventory == nullptr || inventory->isContainerFullRecursive()) {
					creature->sendSystemMessage("Your inventory is full, so the item could not be created.");
					return INVALIDPARAMETERS;
				}

				ManagedReference<TangibleObject*> object = (server->getZoneServer()->createObject(shot->getServerObjectCRC(), 1)).castTo<TangibleObject*>();

				if (object == nullptr) {
					creature->sendSystemMessage("The object could not be created because the template could not be found.");
					return INVALIDPARAMETERS;
				}

				Locker locker(object);

				object->createChildObjects();

				String name = "Generated with Object Command";
				object->setCraftersName(name);

				StringBuffer customName;
				customName << object->getDisplayedName() << " (Socketed)";
				object->setCustomObjectName(customName.toString(), false);

				String serial = craftingManager->generateSerial();
				object->setSerialNumber(serial);

				bool socketsApplied = false;
				if (object->isWearableObject()) {
					ManagedReference<WearableObject*> wear = object.castTo<WearableObject*>();
					if (wear != nullptr) {
						wear->setMaxSockets(maxSockets);
						socketsApplied = true;
					}
				} else if (object->isWearableContainerObject()) {
					ManagedReference<WearableContainerObject*> wearC = object.castTo<WearableContainerObject*>();
					if (wearC != nullptr) {
						wearC->setMaxSockets(maxSockets);
						socketsApplied = true;
					}
				}

				if (!socketsApplied) {
					creature->sendSystemMessage("Warning: template is not a wearable type; sockets were not applied (item still created).");
				}

				if (inventory->transferObject(object, -1, true)) {
					inventory->broadcastObject(object, true);
					creature->info(true) << "/object createwearable " << objectTemplate << " sockets=" << maxSockets
						<< " oid: " << object->getObjectID() << " \"" << object->getDisplayedName() << "\"";
					creature->sendSystemMessage("Created wearable with " + String::valueOf(maxSockets) + " attachment socket(s).");
				} else {
					object->destroyObjectFromDatabase(true);
					creature->sendSystemMessage("Error transferring object to inventory.");
				}
			} else if (commandType.beginsWith("createattachment")) {
				String attachmentType;
				args.getStringToken(attachmentType);

				String statName;
				args.getStringToken(statName);

				int statValue = 25; // default value
				if (args.hasMoreTokens())
					statValue = args.getIntToken();

				// Validate stat value range (1-25)
				if (statValue < 1 || statValue > 25) {
					creature->sendSystemMessage("Stat value must be between 1 and 25.");
					return INVALIDPARAMETERS;
				}

				// Determine template and validate stat name
				String objectTemplate;
				bool isValidStat = false;

				if (attachmentType == "AA" || attachmentType == "aa") {
					objectTemplate = "object/tangible/gem/armor.iff";

					// Validate against exact armor attachment stat list
					if (statName == "blind_defense" || statName == "block" || statName == "camouflage" ||
						statName == "carbine_accuracy" || statName == "carbine_hit_while_moving" || statName == "carbine_speed" ||
						statName == "combat_bleeding_defense" || statName == "counterattack" || statName == "dizzy_defense" ||
						statName == "dodge" || statName == "droid_find_chance" || statName == "droid_find_speed" ||
						statName == "droid_track_chance" || statName == "droid_track_speed" || statName == "foraging" ||
						statName == "group_slope_move" || statName == "heavy_rifle_lightning_accuracy" || statName == "heavy_rifle_lightning_speed" ||
						statName == "intimidate" || statName == "intimidate_defense" || statName == "keep_creature" ||
						statName == "knockdown_defense" || statName == "melee_defense" || statName == "onehandmelee_accuracy" ||
						statName == "onehandmelee_speed" || statName == "pistol_accuracy" || statName == "pistol_hit_while_moving" ||
						statName == "pistol_speed" || statName == "pistol_accuracy_while_standing" || statName == "polearm_accuracy" ||
						statName == "polearm_speed" || statName == "posture_change_down_defense" || statName == "posture_change_up_defense" ||
						statName == "ranged_defense" || statName == "rescue" || statName == "resistance_bleeding" ||
						statName == "resistance_disease" || statName == "resistance_fire" || statName == "resistance_poison" ||
						statName == "rifle_accuracy" || statName == "rifle_hit_while_moving" || statName == "rifle_speed" ||
						statName == "slope_move" || statName == "stun_defense" || statName == "tame_aggro" ||
						statName == "tame_bonus" || statName == "tame_non_aggro" || statName == "thrown_accuracy" ||
						statName == "thrown_speed" || statName == "twohandmelee_accuracy" || statName == "twohandmelee_speed" ||
						statName == "unarmed_accuracy" || statName == "unarmed_speed") {
						isValidStat = true;
					}
				} else if (attachmentType == "CA" || attachmentType == "ca") {
					objectTemplate = "object/tangible/gem/clothing.iff";

					// Validate against exact clothing attachment stat list
					if (statName == "armor_assembly" || statName == "armor_experimentation" || statName == "armor_repair" ||
						statName == "blind_defense" || statName == "block" || statName == "camouflage" ||
						statName == "carbine_accuracy" || statName == "carbine_hit_while_moving" || statName == "carbine_speed" ||
						statName == "clothing_assembly" || statName == "clothing_repair" || statName == "combat_bleeding_defense" ||
						statName == "combat_medicine_assembly" || statName == "combat_medicine_experimentation" || statName == "counterattack" ||
						statName == "dizzy_defense" || statName == "dodge" || statName == "droid_assembly" ||
						statName == "droid_experimentation" || statName == "droid_find_chance" || statName == "droid_find_speed" ||
						statName == "droid_track_chance" || statName == "droid_track_speed" || statName == "food_assembly" ||
						statName == "food_experimentation" || statName == "foraging" || statName == "general_assembly" ||
						statName == "general_experimentation" || statName == "group_slope_move" || statName == "healing_dance_mind" ||
						statName == "healing_dance_shock" || statName == "healing_dance_wound" || statName == "healing_injury_speed" ||
						statName == "healing_injury_treatment" || statName == "healing_music_mind" || statName == "healing_music_shock" ||
						statName == "healing_music_wound" || statName == "healing_range" || statName == "healing_range_speed" ||
						statName == "healing_wound_speed" || statName == "healing_wound_treatment" || statName == "heavy_rifle_lightning_accuracy" ||
						statName == "heavy_rifle_lightning_speed" || statName == "intimidate" || statName == "intimidate_defense" ||
						statName == "knockdown_defense" || statName == "medicine_assembly" || statName == "medicine_experimentation" ||
						statName == "melee_defense" || statName == "onehandmelee_accuracy" || statName == "onehandmelee_speed" ||
						statName == "pistol_accuracy" || statName == "pistol_hit_while_moving" || statName == "pistol_speed" ||
						statName == "pistol_accuracy_while_standing" || statName == "polearm_accuracy" || statName == "polearm_speed" ||
						statName == "posture_change_down_defense" || statName == "posture_change_up_defense" || statName == "ranged_defense" ||
						statName == "rescue" || statName == "resistance_bleeding" || statName == "resistance_disease" ||
						statName == "resistance_fire" || statName == "resistance_poison" || statName == "rifle_accuracy" ||
						statName == "rifle_hit_while_moving" || statName == "rifle_speed" || statName == "slope_move" ||
						statName == "structure_assembly" || statName == "structure_experimentation" || statName == "stun_defense" ||
						statName == "surveying" || statName == "tame_aggro" || statName == "tame_bonus" ||
						statName == "tame_non_aggro" || statName == "thrown_accuracy" || statName == "thrown_speed" ||
						statName == "twohandmelee_accuracy" || statName == "twohandmelee_speed" || statName == "unarmed_accuracy" ||
						statName == "unarmed_speed" || statName == "weapon_assembly" || statName == "weapon_experimentation" ||
						statName == "weapon_repair" || statName == "jedi_saber_assembly" || statName == "jedi_saber_experimentation" ||
						statName == "jedi_force_power_regen" || statName == "jedi_force_power_max" || statName == "onehandlightsaber_accuracy" ||
						statName == "onehandlightsaber_speed" || statName == "polearmlightsaber_accuracy" || statName == "polearmlightsaber_speed" ||
						statName == "twohandlightsaber_accuracy" || statName == "twohandlightsaber_speed" || statName == "force_assembly" ||
						statName == "force_experimentation" || statName == "force_choke" || statName == "forcethrow_accuracy" ||
						statName == "force_failure_reduction" || statName == "force_repair_bonus" || statName == "lightsaber_toughness" ||
						statName == "jedi_state_defense" || statName == "forceintimidate_accuracy" || statName == "forceknockdown_accuracy" ||
						statName == "forcelightning_accuracy" || statName == "forceweaken_accuracy") {
						isValidStat = true;
					}
				} else {
					creature->sendSystemMessage("Attachment type must be 'AA' (armor) or 'CA' (clothing).");
					return INVALIDPARAMETERS;
				}

				if (!isValidStat) {
					creature->sendSystemMessage("Invalid stat name '" + statName + "' for " + attachmentType + " attachment.");
					return INVALIDPARAMETERS;
				}

				ManagedReference<SceneObject*> inventory = creature->getSlottedObject("inventory");
				if (inventory == nullptr || inventory->isContainerFullRecursive()) {
					creature->sendSystemMessage("Your inventory is full, so the attachment could not be created.");
					return INVALIDPARAMETERS;
				}

				// Create the attachment object
				ManagedReference<TangibleObject*> attachment = (server->getZoneServer()->createObject(objectTemplate.hashCode(), 1)).castTo<TangibleObject*>();

				if (attachment == nullptr) {
					creature->sendSystemMessage("Failed to create attachment object.");
					return INVALIDPARAMETERS;
				}

				Locker locker(attachment);

				attachment->createChildObjects();

				// Set crafter name and serial number
				String name = "Generated with Object Command";
				attachment->setCraftersName(name);

				ManagedReference<CraftingManager*> craftingManager = creature->getZoneServer()->getCraftingManager();
				if (craftingManager != nullptr) {
					String serial = craftingManager->generateSerial();
					attachment->setSerialNumber(serial);
				}

				// Cast to Attachment and add the specific skill mod
				ManagedReference<Attachment*> attachmentObj = attachment.castTo<Attachment*>();
				if (attachmentObj != nullptr) {
					VectorMap<String, int>* skillMods = attachmentObj->getSkillMods();
					if (skillMods != nullptr) {
						skillMods->put(statName, statValue);
					}
				}

				// Set the custom name for the attachment
				String attachmentTypePrefix = (attachmentType == "AA" || attachmentType == "aa") ? "AA" : "CA";
				StringBuffer customName;
				customName << attachmentTypePrefix << " - (" << statValue << ") " << statName;
				attachment->setCustomObjectName(customName.toString(), false);

				// Add magic bit to show it has modifiers
				attachment->addMagicBit(false);

				if (inventory->transferObject(attachment, -1, true)) {
					inventory->broadcastObject(attachment, true);
					creature->info(true) << "/object createattachment " << attachmentType << " " << statName << " " << statValue 
										  << " created oid: " << attachment->getObjectID() << " \"" << attachment->getDisplayedName() << "\"";
					creature->sendSystemMessage("Created " + attachmentType + " attachment with +" + String::valueOf(statValue) + " " + statName + ".");
				} else {
					attachment->destroyObjectFromDatabase(true);
					creature->sendSystemMessage("Error transferring attachment to inventory.");
				}
			} else if (commandType.beginsWith("createloot")) {
				String lootGroup;
				args.getStringToken(lootGroup);

				int level = 1;

				if (args.hasMoreTokens())
					level = args.getIntToken();

				ManagedReference<SceneObject*> inventory = creature->getSlottedObject("inventory");

				if (inventory == nullptr || inventory->isContainerFullRecursive()) {
					creature->sendSystemMessage("Your inventory is full, so the item could not be created.");
					return INVALIDPARAMETERS;
				}

				ManagedReference<LootManager*> lootManager = creature->getZoneServer()->getLootManager();

				if (lootManager == nullptr)
					return INVALIDPARAMETERS;

				TransactionLog trx(TrxCode::ADMINCOMMAND, creature);
				trx.addState("commandType", commandType);
				if (lootManager->createLoot(trx, inventory, lootGroup, level) > 0) {
					creature->info(true) << "/object creatloot " << lootGroup << " trxId: " << trx.getTrxID();
					trx.commit(true);
				} else {
					trx.abort() << "createLoot failed for lootGroup " << lootGroup << " level " << level;
				}
			} else if (commandType.beginsWith("createresource")) {
				String resourceName;
				args.getStringToken(resourceName);

				int quantity = 100000;

				if (args.hasMoreTokens())
					quantity = args.getIntToken();

				ManagedReference<ResourceManager*> resourceManager = server->getZoneServer()->getResourceManager();
				resourceManager->givePlayerResource(creature, resourceName, quantity);
			} else if (commandType.beginsWith("createarealoot")) {
				String lootGroup;
				args.getStringToken(lootGroup);

				int range = 32;
				if (args.hasMoreTokens())
					range = args.getIntToken();

				if( range < 0 )
					range = 32;

				if( range > 128 )
					range = 128;

				int level = 1;
				if (args.hasMoreTokens())
					level = args.getIntToken();

				ManagedReference<LootManager*> lootManager = creature->getZoneServer()->getLootManager();
				if (lootManager == nullptr)
					return INVALIDPARAMETERS;

				Zone* zone = creature->getZone();
				if (zone == nullptr)
					return GENERALERROR;

				// Find all objects in range
				SortedVector<TreeEntry*> closeObjects;
				CloseObjectsVector* closeObjectsVector = (CloseObjectsVector*) creature->getCloseObjects();
				if (closeObjectsVector == nullptr) {
					zone->getInRangeObjects(creature->getPositionX(), creature->getPositionZ(), creature->getPositionY(), range, &closeObjects, true);
				} else {
					closeObjectsVector->safeCopyTo(closeObjects);
				}

				// Award loot group to all players in range
				for (int i = 0; i < closeObjects.size(); i++) {
					SceneObject* targetObject = static_cast<SceneObject*>(closeObjects.get(i));

					if (targetObject->isPlayerCreature() && creature->isInRange(targetObject, range)) {

						CreatureObject* targetPlayer = cast<CreatureObject*>(targetObject);
						Locker tlock( targetPlayer, creature );

						ManagedReference<SceneObject*> inventory = targetPlayer->getSlottedObject("inventory");
						if (inventory != nullptr) {
							TransactionLog trx(creature, targetPlayer, nullptr, TrxCode::ADMINCOMMAND);
							trx.addState("commandType", commandType);
							if (lootManager->createLoot(trx, inventory, lootGroup, level) > 0) {
								creature->info(true) << "/object creatlootarea " << lootGroup << " trxId: " << trx.getTrxID();
								trx.commit(true);
								targetPlayer->sendSystemMessage( "You have received a loot item!");
							} else {
								trx.abort() << "createLoot failed for lootGroup " << lootGroup << " level " << level;
							}
						}

						tlock.release();
					}
				}
			} else if (commandType.beginsWith("checklooted")) {
				ManagedReference<LootManager*> lootManager = creature->getZoneServer()->getLootManager();
				if (lootManager == nullptr)
					return INVALIDPARAMETERS;

				creature->sendSystemMessage("Number of Legendaries Looted: " + String::valueOf(lootManager->getLegendaryLooted()));
				creature->sendSystemMessage("Number of Exceptionals Looted: " + String::valueOf(lootManager->getExceptionalLooted()));
				creature->sendSystemMessage("Number of Magical Looted: " + String::valueOf(lootManager->getYellowLooted()));

			} else if (commandType.beginsWith("characterbuilder")) {
				if (!ConfigManager::instance()->getBool("Core3.CharacterBuilderEnabled", true)) {
					creature->sendSystemMessage("characterbuilder is not enabled on this server.");
					return GENERALERROR;
				}

				ZoneServer* zserv = server->getZoneServer();

				String blueFrogTemplate = "object/tangible/terminal/terminal_character_builder.iff";
				ManagedReference<CharacterBuilderTerminal*> blueFrog = ( zserv->createObject(blueFrogTemplate.hashCode(), 0)).castTo<CharacterBuilderTerminal*>();

				if (blueFrog == nullptr)
					return GENERALERROR;

				Locker clocker(blueFrog, creature);

				float x = creature->getPositionX();
				float y = creature->getPositionY();
				float z = creature->getPositionZ();

				ManagedReference<SceneObject*> parent = creature->getParent().get();

				blueFrog->initializePosition(x, z, y);
				blueFrog->setDirection(creature->getDirectionW(), creature->getDirectionX(), creature->getDirectionY(), creature->getDirectionZ());

				if (parent != nullptr && parent->isCellObject())
					parent->transferObject(blueFrog, -1);
				else
					creature->getZone()->transferObject(blueFrog, -1, true);

				creature->info(true) << "/object characterbuilder " << " created oid: " << blueFrog->getObjectID() << " \"" << blueFrog->getDisplayedName() << "\" as " << creature->getWorldPosition() << " on " << creature->getZone()->getZoneName();
			}

		} catch (Exception& e) {
			creature->sendSystemMessage("SYNTAX: /object createitem <objectTemplatePath> [<quantity>] [<quality 0-100>] [<visible components...>]");
			creature->sendSystemMessage("SYNTAX: /object createattachment <AA|CA> <statname> <value>");
			creature->sendSystemMessage("SYNTAX: /object createresource <resourceName> [<quantity>]");
			creature->sendSystemMessage("SYNTAX: /object createloot <loottemplate> [<level>]");
			creature->sendSystemMessage("SYNTAX: /object createarealoot <loottemplate> [<range>] [<level>]");
			creature->sendSystemMessage("SYNTAX: /object checklooted");
			creature->sendSystemMessage("SYNTAX: /object characterbuilder");

			return INVALIDPARAMETERS;
		}

		return SUCCESS;
	}

};

#endif //OBJECTCOMMAND_H_
