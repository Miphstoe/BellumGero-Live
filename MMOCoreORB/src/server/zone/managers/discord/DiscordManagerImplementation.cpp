/*
 * DiscordManagerImplementation.cpp
 *
 *  Created on: 2024
 *      Author: Core3 Discord Integration
 */

#include "server/zone/managers/discord/DiscordManagerImplementation.h"

#include "server/zone/ZoneServer.h"
#include "server/chat/ChatManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "conf/ConfigManager.h"
#include "server/zone/packets/chat/ChatRoomMessage.h"

// Discord constants
#define DISCORD_MAX_MESSAGE_LENGTH 2000

#ifdef WITH_DISCORD_INTEGRATION
#include <dpp/dpp.h>
#include "engine/core/Core.h"
#include "engine/core/TaskManager.h"
#include "system/lang/System.h"

#include <algorithm>
#include <memory>
#include <mutex>
#include <thread>

namespace {

enum class DiscordLifecycleState {
    Stopped,
    Starting,
    Connected,
    Reconnecting,
    Stopping
};

constexpr uint64 DISCORD_HEALTH_CHECK_INTERVAL_MS = 30000;
constexpr uint64 DISCORD_RECONNECT_DELAY_MS = 15000;
constexpr uint64 DISCORD_RECONNECT_BASE_BACKOFF_MS = 30000;
constexpr uint64 DISCORD_RECONNECT_MAX_BACKOFF_MS = 300000;
constexpr uint64 DISCORD_STARTUP_GRACE_MS = 180000;
constexpr uint64 DISCORD_MIN_HEARTBEAT_TIMEOUT_MS = 120000;

struct DiscordRuntimeState {
    std::mutex lifecycleMutex;
    std::mutex mutex;
    std::unique_ptr<dpp::cluster> bot;
    std::thread botThread;
    bool shutdownRequested = false;
    bool reconnectTaskScheduled = false;
    bool reconnectInProgress = false;
    bool gatewayConnected = false;
    uint64 generation = 0;
    uint64 lastStartMs = 0;
    uint64 lastReadyMs = 0;
    uint64 lastResumeMs = 0;
    uint64 lastDisconnectMs = 0;
    uint64 nextReconnectAllowedMs = 0;
    uint32 reconnectAttempts = 0;
    DiscordLifecycleState state = DiscordLifecycleState::Stopped;
    String pendingReconnectReason;
};

DiscordRuntimeState discordRuntime;

uint64 getDiscordNowMs() {
    return System::getMiliTime();
}

String discordLifecycleStateToString(DiscordLifecycleState state) {
    switch (state) {
    case DiscordLifecycleState::Stopped:
        return "Stopped";
    case DiscordLifecycleState::Starting:
        return "Starting";
    case DiscordLifecycleState::Connected:
        return "Connected";
    case DiscordLifecycleState::Reconnecting:
        return "Reconnecting";
    case DiscordLifecycleState::Stopping:
        return "Stopping";
    }

    return "Unknown";
}

template <typename T>
dpp::discord_client* getShardPointer(T* shard) {
    return shard;
}

template <typename T>
dpp::discord_client* getShardPointer(const std::unique_ptr<T>& shard) {
    return shard.get();
}

uint64 getReconnectBackoffMs(uint32 attempt) {
    uint64 delay = DISCORD_RECONNECT_BASE_BACKOFF_MS;

    for (uint32 i = 1; i < attempt && delay < DISCORD_RECONNECT_MAX_BACKOFF_MS; ++i) {
        delay = std::min<uint64>(delay * 2, DISCORD_RECONNECT_MAX_BACKOFF_MS);
    }

    return delay;
}

bool shouldIgnoreDiscordCallback(uint64 generation) {
    std::lock_guard<std::mutex> lock(discordRuntime.mutex);

    return discordRuntime.generation != generation ||
        discordRuntime.shutdownRequested ||
        discordRuntime.state == DiscordLifecycleState::Stopping ||
        discordRuntime.state == DiscordLifecycleState::Stopped;
}

DiscordManagerImplementation* getDiscordImplementation(const ManagedReference<DiscordManager*>& managerRef) {
    if (managerRef == nullptr) {
        return nullptr;
    }

    return static_cast<DiscordManagerImplementation*>(managerRef->_getImplementationForRead());
}

void scheduleDiscordHealthCheck(const ManagedReference<DiscordManager*>& managerRef, uint64 generation, uint64 delayMs);
void requestDiscordReconnect(DiscordManagerImplementation* manager, const ManagedReference<DiscordManager*>& managerRef, const String& reason, uint64 minimumDelayMs = DISCORD_RECONNECT_DELAY_MS);

bool startDiscordRuntime(DiscordManagerImplementation* manager, const ManagedReference<DiscordManager*>& managerRef) {
    if (!manager->isEnabled()) {
        return false;
    }

    uint64 generation = 0;

    {
        std::lock_guard<std::mutex> stateLock(discordRuntime.mutex);

        if (discordRuntime.state == DiscordLifecycleState::Starting ||
                discordRuntime.state == DiscordLifecycleState::Connected ||
                discordRuntime.state == DiscordLifecycleState::Reconnecting) {
            if (manager->isDebugMode()) {
                manager->info("Discord start suppressed because lifecycle state is already " + discordLifecycleStateToString(discordRuntime.state), true);
            }

            return true;
        }

        discordRuntime.shutdownRequested = false;
        discordRuntime.gatewayConnected = false;
        discordRuntime.reconnectInProgress = false;
        discordRuntime.reconnectTaskScheduled = false;
        discordRuntime.pendingReconnectReason = "";
        discordRuntime.state = DiscordLifecycleState::Starting;
        discordRuntime.generation++;
        discordRuntime.lastStartMs = getDiscordNowMs();
        discordRuntime.lastReadyMs = 0;
        discordRuntime.lastResumeMs = 0;
        discordRuntime.lastDisconnectMs = 0;
        discordRuntime.nextReconnectAllowedMs = discordRuntime.lastStartMs;
        generation = discordRuntime.generation;
    }

    std::unique_ptr<dpp::cluster> bot;

    try {
        if (manager->isDebugMode()) {
            manager->info("Creating Discord cluster with DPP", true);
        }

        bot = std::make_unique<dpp::cluster>(
            manager->getBotToken().toCharArray(),
            dpp::i_default_intents | dpp::i_message_content
        );
    } catch (const std::exception& e) {
        {
            std::lock_guard<std::mutex> stateLock(discordRuntime.mutex);
            discordRuntime.state = DiscordLifecycleState::Stopped;
        }

        manager->error("Failed to create Discord cluster: " + String(e.what()));
        return false;
    }

    bot->on_ready([managerRef, generation](const dpp::ready_t& event) {
        if (managerRef == nullptr || shouldIgnoreDiscordCallback(generation)) {
            return;
        }

        DiscordManagerImplementation* manager = getDiscordImplementation(managerRef);

        if (manager == nullptr) {
            return;
        }

        if (manager->isDebugMode()) {
            manager->info("Discord on_ready callback triggered", true);
        }

        {
            std::lock_guard<std::mutex> lock(discordRuntime.mutex);

            if (discordRuntime.generation != generation || discordRuntime.shutdownRequested) {
                return;
            }

            discordRuntime.gatewayConnected = true;
            discordRuntime.state = DiscordLifecycleState::Connected;
            discordRuntime.lastReadyMs = getDiscordNowMs();
            discordRuntime.reconnectAttempts = 0;
            discordRuntime.nextReconnectAllowedMs = discordRuntime.lastReadyMs;
            discordRuntime.pendingReconnectReason = "";
        }

        manager->info("Discord Gateway connected.", true);

    });

    bot->on_resumed([managerRef, generation](const dpp::resumed_t&) {
        if (managerRef == nullptr || shouldIgnoreDiscordCallback(generation)) {
            return;
        }

        DiscordManagerImplementation* manager = getDiscordImplementation(managerRef);

        if (manager == nullptr) {
            return;
        }

        {
            std::lock_guard<std::mutex> lock(discordRuntime.mutex);

            if (discordRuntime.generation != generation || discordRuntime.shutdownRequested) {
                return;
            }

            discordRuntime.gatewayConnected = true;
            discordRuntime.state = DiscordLifecycleState::Connected;
            discordRuntime.lastResumeMs = getDiscordNowMs();
        }

        manager->info("Discord Gateway resumed.", true);
    });

    bot->on_socket_close([managerRef, generation](const dpp::socket_close_t&) {
        if (managerRef == nullptr || shouldIgnoreDiscordCallback(generation)) {
            return;
        }

        DiscordManagerImplementation* manager = getDiscordImplementation(managerRef);

        if (manager == nullptr) {
            return;
        }

        {
            std::lock_guard<std::mutex> lock(discordRuntime.mutex);

            if (discordRuntime.generation != generation || discordRuntime.shutdownRequested) {
                return;
            }

            discordRuntime.gatewayConnected = false;
            discordRuntime.state = DiscordLifecycleState::Reconnecting;
            discordRuntime.lastDisconnectMs = getDiscordNowMs();
        }

        manager->info("Discord Gateway disconnected.", true);
        requestDiscordReconnect(manager, managerRef, "Discord Gateway socket closed");
    });

    bot->on_message_create([managerRef, generation](const dpp::message_create_t& event) {
        if (managerRef == nullptr || shouldIgnoreDiscordCallback(generation)) {
            return;
        }

        if (event.msg.author.is_bot()) {
            return;
        }

        managerRef->handleDiscordMessage(
            String::valueOf(event.msg.channel_id),
            event.msg.content,
            event.msg.author.username,
            String::valueOf(event.msg.author.id)
        );
    });

    bot->on_log([managerRef, generation](const dpp::log_t& event) {
        if (managerRef == nullptr || shouldIgnoreDiscordCallback(generation)) {
            return;
        }

        DiscordManagerImplementation* manager = getDiscordImplementation(managerRef);

        if (manager == nullptr) {
            return;
        }

        if (event.severity >= dpp::ll_error) {
            manager->handleDiscordError(event.message);
        } else if (manager->isDebugMode() && event.severity >= dpp::ll_debug) {
            manager->info("Discord Debug: " + String(event.message), true);
        }
    });

    {
        std::lock_guard<std::mutex> stateLock(discordRuntime.mutex);

        if (discordRuntime.generation != generation || discordRuntime.state == DiscordLifecycleState::Stopping) {
            discordRuntime.state = DiscordLifecycleState::Stopped;
            return false;
        }

        discordRuntime.bot = std::move(bot);
    }

    std::thread botThread([managerRef, generation]() {
        if (managerRef == nullptr) {
            return;
        }

        DiscordManagerImplementation* manager = getDiscordImplementation(managerRef);

        if (manager == nullptr) {
            return;
        }

        try {
            if (manager->isDebugMode()) {
                manager->info("Discord bot thread started, calling dpp::cluster::start", true);
            }

            dpp::cluster* bot = nullptr;

            {
                std::lock_guard<std::mutex> lock(discordRuntime.mutex);

                if (discordRuntime.generation != generation || discordRuntime.bot == nullptr) {
                    return;
                }

                bot = discordRuntime.bot.get();
            }

            bot->start(dpp::st_wait);

            if (manager->isDebugMode()) {
                manager->info("Discord bot thread finished", true);
            }
        } catch (const std::exception& e) {
            manager->error("Discord bot thread exception: " + String(e.what()));
            requestDiscordReconnect(manager, managerRef, "Discord bot thread exception");
            return;
        }

        if (!shouldIgnoreDiscordCallback(generation)) {
            requestDiscordReconnect(manager, managerRef, "Discord bot thread exited unexpectedly");
        }
    });

    {
        std::lock_guard<std::mutex> stateLock(discordRuntime.mutex);
        discordRuntime.botThread = std::move(botThread);
    }

    scheduleDiscordHealthCheck(managerRef, generation, DISCORD_HEALTH_CHECK_INTERVAL_MS);

    manager->info("Discord bot started successfully.", true);
    return true;
}

void stopDiscordRuntime(DiscordManagerImplementation* manager, bool shuttingDownCore) {
    std::unique_ptr<dpp::cluster> bot;
    std::thread botThread;

    {
        std::lock_guard<std::mutex> stateLock(discordRuntime.mutex);

        if (discordRuntime.state == DiscordLifecycleState::Stopped &&
                discordRuntime.bot == nullptr &&
                !discordRuntime.botThread.joinable()) {
            if (shuttingDownCore) {
                discordRuntime.shutdownRequested = true;
            }

            return;
        }

        if (shuttingDownCore) {
            discordRuntime.shutdownRequested = true;
        }

        discordRuntime.gatewayConnected = false;
        discordRuntime.reconnectTaskScheduled = false;
        discordRuntime.reconnectInProgress = false;
        discordRuntime.pendingReconnectReason = "";
        discordRuntime.state = DiscordLifecycleState::Stopping;

        bot = std::move(discordRuntime.bot);
        botThread = std::move(discordRuntime.botThread);
    }

    if (bot != nullptr) {
        if (manager->isDebugMode()) {
            manager->info("Shutting down Discord cluster", true);
        }

        try {
            bot->shutdown();
        } catch (const std::exception& e) {
            manager->error("Discord cluster shutdown exception: " + String(e.what()));
        }
    }

    if (botThread.joinable()) {
        if (manager->isDebugMode()) {
            manager->info("Joining Discord thread", true);
        }

        botThread.join();
    }

    {
        std::lock_guard<std::mutex> stateLock(discordRuntime.mutex);
        discordRuntime.state = DiscordLifecycleState::Stopped;

        if (!shuttingDownCore) {
            discordRuntime.shutdownRequested = false;
        }
    }
}

bool isDiscordShardHealthyLocked(String& failureReason) {
    if (discordRuntime.bot == nullptr) {
        failureReason = "Discord cluster instance is missing";
        return false;
    }

    const uint64 nowMs = getDiscordNowMs();
    const auto& shards = discordRuntime.bot->get_shards();

    if (shards.empty()) {
        if (nowMs - discordRuntime.lastStartMs > DISCORD_STARTUP_GRACE_MS) {
            failureReason = "Discord cluster has no active shards after startup grace period";
            return false;
        }

        return true;
    }

    for (const auto& entry : shards) {
        dpp::discord_client* shard = getShardPointer(entry.second);

        if (shard == nullptr) {
            failureReason = "Discord shard pointer is null";
            return false;
        }

        if (!shard->ready) {
            if (nowMs - discordRuntime.lastStartMs > DISCORD_STARTUP_GRACE_MS) {
                failureReason = "Discord shard " + String::valueOf(entry.first) + " is not ready";
                return false;
            }

            continue;
        }

        const uint64 heartbeatTimeoutMs = std::max<uint64>(
            DISCORD_MIN_HEARTBEAT_TIMEOUT_MS,
            static_cast<uint64>(shard->heartbeat_interval) * 3ULL
        );
        const uint64 lastHeartbeatMs = static_cast<uint64>(shard->last_heartbeat) * 1000ULL;
        const uint64 lastHeartbeatAckMs = static_cast<uint64>(shard->last_heartbeat_ack) * 1000ULL;

        if (lastHeartbeatAckMs == 0) {
            if (discordRuntime.lastReadyMs != 0 && nowMs - discordRuntime.lastReadyMs > heartbeatTimeoutMs) {
                failureReason = "Discord shard " + String::valueOf(entry.first) + " has not acknowledged heartbeat since ready";
                return false;
            }

            continue;
        }

        if (lastHeartbeatMs > lastHeartbeatAckMs && lastHeartbeatMs - lastHeartbeatAckMs > heartbeatTimeoutMs) {
            failureReason = "Discord shard " + String::valueOf(entry.first) + " heartbeat acknowledgements are stale";
            return false;
        }

        if (nowMs > lastHeartbeatAckMs && nowMs - lastHeartbeatAckMs > heartbeatTimeoutMs) {
            failureReason = "Discord shard " + String::valueOf(entry.first) + " heartbeat acknowledgement timed out";
            return false;
        }
    }

    return true;
}

void runDiscordHealthCheck(DiscordManagerImplementation* manager, const ManagedReference<DiscordManager*>& managerRef, uint64 generation) {
    bool shouldReschedule = false;
    String failureReason;

    {
        std::lock_guard<std::mutex> lock(discordRuntime.mutex);

        if (discordRuntime.generation != generation || discordRuntime.shutdownRequested) {
            return;
        }

        if (discordRuntime.state == DiscordLifecycleState::Stopped ||
                discordRuntime.state == DiscordLifecycleState::Stopping) {
            return;
        }

        shouldReschedule = true;

        if (!discordRuntime.gatewayConnected) {
            if (getDiscordNowMs() - discordRuntime.lastStartMs > DISCORD_STARTUP_GRACE_MS) {
                failureReason = "Discord Gateway did not reach a healthy ready state";
            }
        } else {
            isDiscordShardHealthyLocked(failureReason);
        }
    }

    if (!failureReason.isEmpty()) {
        manager->info("Discord health check detected an unhealthy gateway: " + failureReason, true);
        requestDiscordReconnect(manager, managerRef, failureReason, 0);
    }

    if (shouldReschedule) {
        scheduleDiscordHealthCheck(managerRef, generation, DISCORD_HEALTH_CHECK_INTERVAL_MS);
    }
}

void scheduleDiscordHealthCheck(const ManagedReference<DiscordManager*>& managerRef, uint64 generation, uint64 delayMs) {
    auto* taskManager = Core::getTaskManager();

    if (taskManager == nullptr) {
        return;
    }

    taskManager->scheduleTask([managerRef, generation]() {
        if (managerRef == nullptr) {
            return;
        }

        DiscordManagerImplementation* manager = getDiscordImplementation(managerRef);

        if (manager == nullptr) {
            return;
        }

        runDiscordHealthCheck(manager, managerRef, generation);
    }, "DiscordHealthCheckTask", delayMs);
}

void scheduleDiscordReconnectTask(const ManagedReference<DiscordManager*>& managerRef, uint64 generation, uint64 delayMs) {
    auto* taskManager = Core::getTaskManager();

    if (taskManager == nullptr) {
        return;
    }

    taskManager->scheduleTask([managerRef, generation]() {
        if (managerRef == nullptr) {
            return;
        }

        DiscordManagerImplementation* manager = getDiscordImplementation(managerRef);

        if (manager == nullptr) {
            return;
        }

        {
            std::lock_guard<std::mutex> stateLock(discordRuntime.mutex);
            discordRuntime.reconnectTaskScheduled = false;

            if (discordRuntime.shutdownRequested || discordRuntime.generation != generation) {
                return;
            }

            if (discordRuntime.reconnectInProgress) {
                return;
            }

            discordRuntime.reconnectInProgress = true;
        }

        std::lock_guard<std::mutex> lifecycleLock(discordRuntime.lifecycleMutex);

        {
            std::lock_guard<std::mutex> stateLock(discordRuntime.mutex);

            if (discordRuntime.shutdownRequested) {
                discordRuntime.reconnectInProgress = false;
                return;
            }

            if (discordRuntime.generation != generation) {
                discordRuntime.reconnectInProgress = false;
                return;
            }
        }

        String reason;
        uint32 attempt = 0;
        uint64 retryGeneration = 0;
        uint64 retryDelayMs = 0;

        {
            std::lock_guard<std::mutex> stateLock(discordRuntime.mutex);
            reason = discordRuntime.pendingReconnectReason;
            attempt = discordRuntime.reconnectAttempts + 1;
        }

        manager->info("Discord reconnect starting. Reason: " + reason, true);

        stopDiscordRuntime(manager, false);

        const bool started = startDiscordRuntime(manager, managerRef);

        {
            std::lock_guard<std::mutex> stateLock(discordRuntime.mutex);
            discordRuntime.reconnectInProgress = false;

            if (!started) {
                discordRuntime.reconnectAttempts = attempt;

                if (!discordRuntime.shutdownRequested) {
                    const uint64 backoffMs = getReconnectBackoffMs(attempt);
                    discordRuntime.nextReconnectAllowedMs = getDiscordNowMs() + backoffMs;
                    discordRuntime.pendingReconnectReason = "Previous Discord reconnect attempt failed";

                    if (!discordRuntime.reconnectTaskScheduled) {
                        discordRuntime.reconnectTaskScheduled = true;
                        retryGeneration = discordRuntime.generation;
                        retryDelayMs = backoffMs;
                    }
                }
            }
        }

        if (started) {
            manager->info("Discord reconnect completed. Waiting for Discord Gateway ready.", true);
        } else {
            manager->error("Discord reconnect failed. A new attempt has been scheduled.");

            if (retryDelayMs != 0) {
                scheduleDiscordReconnectTask(managerRef, retryGeneration, retryDelayMs);
            }
        }
    }, "DiscordReconnectTask", delayMs);
}

void requestDiscordReconnect(DiscordManagerImplementation* manager, const ManagedReference<DiscordManager*>& managerRef, const String& reason, uint64 minimumDelayMs) {
    bool scheduleTask = false;
    bool suppressedByShutdown = false;
    uint64 generation = 0;
    uint64 delayMs = 0;

    {
        std::lock_guard<std::mutex> stateLock(discordRuntime.mutex);

        if (discordRuntime.shutdownRequested) {
            suppressedByShutdown = true;
        } else if (discordRuntime.reconnectTaskScheduled || discordRuntime.reconnectInProgress) {
            if (manager->isDebugMode()) {
                manager->info("Discord reconnect already pending; suppressed duplicate trigger: " + reason, true);
            }

            return;
        } else if (discordRuntime.state == DiscordLifecycleState::Stopping) {
            if (manager->isDebugMode()) {
                manager->info("Discord reconnect trigger ignored because lifecycle state is " + discordLifecycleStateToString(discordRuntime.state), true);
            }

            return;
        } else {
            const uint64 nowMs = getDiscordNowMs();
            discordRuntime.gatewayConnected = false;
            discordRuntime.state = DiscordLifecycleState::Reconnecting;
            discordRuntime.pendingReconnectReason = reason;
            discordRuntime.reconnectTaskScheduled = true;
            generation = discordRuntime.generation;

            if (discordRuntime.nextReconnectAllowedMs > nowMs) {
                delayMs = discordRuntime.nextReconnectAllowedMs - nowMs;
            }

            delayMs = std::max<uint64>(delayMs, minimumDelayMs);
            scheduleTask = true;
        }
    }

    if (suppressedByShutdown) {
        manager->info("Discord reconnect suppressed because Core3 is shutting down.", true);
        return;
    }

    if (!scheduleTask) {
        return;
    }

    manager->info(
        "Discord reconnect requested. Reason: " + reason +
        " Delay: " + String::valueOf(delayMs) + "ms",
        true
    );

    scheduleDiscordReconnectTask(managerRef, generation, delayMs);
}

} // namespace


#endif



void DiscordManagerImplementation::loadConfiguration() {
    ConfigManager* config = ConfigManager::instance();
    
    setEnabled(config->getDiscordEnabled());
    setBotToken(config->getDiscordBotToken());
    setRelayChannelId(config->getDiscordRelayChannelId());
    setDebugMode(config->getDiscordDebugMode());
    

    

    
    if (isDebugMode()) {
        info("Discord configuration loaded:", true);
        info("  Enabled: " + String::valueOf(isEnabled()), true);
        info("  Bot Token: " + String(getBotToken().isEmpty() ? "Not set" : "Set (hidden)"), true);
        info("  Relay Channel ID: " + getRelayChannelId(), true);
    }
}

void DiscordManagerImplementation::validateConfiguration() {
    if (!isEnabled()) {
        info("Discord integration is disabled in configuration.", true);
        return;
    }
    
    if (getBotToken().isEmpty()) {
        error("Discord bot token is not configured. Please set Core3.DiscordManager.BotToken");
        setEnabled(false);
        return;
    }
    
    if (getRelayChannelId().isEmpty()) {
        error("Discord relay channel ID is not configured. Please set Core3.DiscordManager.RelayChannelId");
        setEnabled(false);
        return;
    }
    
    info("Discord configuration validated successfully.", true);
}

void DiscordManagerImplementation::initialize() {
    info("Initializing Discord Manager...", true);
    
    loadConfiguration();
    validateConfiguration();
    
    if (!isEnabled()) {
        info("Discord integration disabled, skipping initialization.", true);
        return;
    }
    

    
    info("Discord Manager initialized successfully.", true);
}

void DiscordManagerImplementation::start() {
    if (!isEnabled()) {
        return;
    }
    
    info("Starting Discord bot...", true);
    
    if (isDebugMode()) {
        info("Bot token configured: " + String(getBotToken().isEmpty() ? "NO" : "YES"), true);
        info("Relay channel ID: " + getRelayChannelId(), true);
    }
    
#ifdef WITH_DISCORD_INTEGRATION
    std::lock_guard<std::mutex> lifecycleLock(discordRuntime.lifecycleMutex);
    ManagedReference<DiscordManager*> managerRef = _this.getReferenceUnsafeStaticCast();

    if (!startDiscordRuntime(this, managerRef)) {
        requestDiscordReconnect(this, managerRef, "Initial Discord start failed", 0);
    }
#else
    error("Discord integration not compiled in. Please rebuild with DPP library support.");
    setEnabled(false);
#endif
}

void DiscordManagerImplementation::restart() {
    if (!isEnabled()) {
        return;
    }

#ifdef WITH_DISCORD_INTEGRATION
    ManagedReference<DiscordManager*> managerRef = _this.getReferenceUnsafeStaticCast();
    requestDiscordReconnect(this, managerRef, "Manual Discord restart requested", 0);
#endif
}

void DiscordManagerImplementation::stop() {
    if (!isEnabled()) {
        return;
    }

    info("Stopping Discord bot...", true);

#ifdef WITH_DISCORD_INTEGRATION
    std::lock_guard<std::mutex> lifecycleLock(discordRuntime.lifecycleMutex);
    stopDiscordRuntime(this, true);
#endif

    info("Discord bot stopped.", true);
}

void DiscordManagerImplementation::shutdown() {
    stop();
}

void DiscordManagerImplementation::sendToDiscord(const String& channel, const String& message, const String& author) {
    if (isDebugMode()) {
        info("sendToDiscord called: enabled=" + String::valueOf(isEnabled()) + " connected=" + String::valueOf(isConnected()), true);
    }
    
    if (!isEnabled()) {
        if (isDebugMode()) {
            info("Discord integration is disabled", true);
        }
        return;
    }
    
    if (!isConnected()) {
        if (isDebugMode()) {
            info("Discord bot is not connected", true);
        }
        return;
    }
    
    // Use the configured relay channel
    String discordChannelId = getRelayChannelId();
    if (discordChannelId.isEmpty()) {
        if (isDebugMode()) {
            info("No Discord relay channel configured", true);
        }
        return;
    }
    
    if (isDebugMode()) {
        info("Discord relay channel ID: " + discordChannelId, true);
    }
    
    // Format and truncate the message
    if (isDebugMode()) {
        info("About to format message: [" + author + "] " + message, true);
    }
    
    String formattedMessage;
    try {
        formattedMessage = formatGameMessage(message, author);
        if (isDebugMode()) {
            info("Formatted message: " + formattedMessage, true);
        }
    } catch (const std::exception& e) {
        error("Exception in formatGameMessage: " + String(e.what()));
        return;
    } catch (...) {
        error("Unknown exception in formatGameMessage");
        return;
    }
    
    try {
        formattedMessage = truncateMessage(formattedMessage, DISCORD_MAX_MESSAGE_LENGTH);
        if (isDebugMode()) {
            info("Truncated message: " + formattedMessage, true);
        }
    } catch (const std::exception& e) {
        error("Exception in truncateMessage: " + String(e.what()));
        return;
    } catch (...) {
        error("Unknown exception in truncateMessage");
        return;
    }
    
    if (isDebugMode()) {
        info("Sending to Discord: " + formattedMessage, true);
    }
    
#ifdef WITH_DISCORD_INTEGRATION
    try {
        std::lock_guard<std::mutex> lock(discordRuntime.mutex);
        if (discordRuntime.bot && discordRuntime.gatewayConnected) {
            // Create stable string copies to avoid dangling pointer issues
            std::string channelStr = discordChannelId.toCharArray();
            std::string messageStr = formattedMessage.toCharArray();

            // Send the message asynchronously
            discordRuntime.bot->message_create(
                dpp::message(std::stoull(channelStr), messageStr)
            );
        }
    } catch (const std::exception& e) {
        error("Failed to send Discord message: " + String(e.what()));
    }
#else
    if (isDebugMode()) {
        info("Would send to Discord: " + formattedMessage, true);
    }
#endif
}

void DiscordManagerImplementation::sendToGame(const String& channel, const String& message, const String& author) {
    if (!chatManager) {
        error("sendToGame: ChatManager is null - cannot send message to game");
        return;
    }
    
    try {
        // Create a system message that appears to come from Discord
        String systemMessage = author + ": " + message;
        
        // Get the General chat room using the full path
        String generalRoomPath = "SWG." + chatManager->getZoneServer()->getGalaxyName() + ".General";
        
        ManagedReference<ChatRoom*> generalRoom = chatManager->getChatRoomByFullPath(generalRoomPath);
        
        if (generalRoom != nullptr) {
            // Create the chat message for the General channel - sender will show as "Discord"
            UnicodeString unicodeMessage(message);
            BaseMessage* msg = new ChatRoomMessage("Discord", chatManager->getZoneServer()->getGalaxyName(), unicodeMessage, generalRoom->getRoomID());
            
            // Broadcast the message to all players in the General channel
            generalRoom->broadcastMessage(msg);
            
        } else {
            error("sendToGame: Could not find General chat room at path: " + generalRoomPath);
            
            // Fallback to galaxy broadcast if General room not found
            String fallbackMessage = "[Discord] " + author + ": " + message;
            chatManager->broadcastGalaxy(fallbackMessage, "");
        }
        
    } catch (const std::exception& e) {
        error("sendToGame: Exception occurred: " + String(e.what()));
        
        try {
            String fallbackMessage = "[Discord] " + author + ": " + message;
            chatManager->broadcastGalaxy(fallbackMessage, "");
        } catch (...) {
            error("sendToGame: Fallback galaxy broadcast also failed");
        }
        
    } catch (...) {
        error("sendToGame: Unknown exception occurred");
        
        try {
            String fallbackMessage = "[Discord] " + author + ": " + message;
            chatManager->broadcastGalaxy(fallbackMessage, "");
        } catch (...) {
            error("sendToGame: Fallback galaxy broadcast also failed");
        }
    }
}

void DiscordManagerImplementation::handleGameMessage(const String& channel, const String& message, const String& author, CreatureObject* player) {
    if (!isEnabled() || !shouldRelayChannel(channel)) {
        return;
    }
    
    if (isDebugMode()) {
        info("Game message received: [" + channel + "] [" + author + "] " + message, true);
    }
    
    // Send the message to Discord
    sendToDiscord(channel, message, author);
}



void DiscordManagerImplementation::handleDiscordMessage(const String& channelId, const String& message, const String& author, const String& userId) {
    if (!isEnabled() || !isConnected()) {
        return;
    }
    
    // Only process messages from the relay channel
    if (channelId != getRelayChannelId()) {
        return;
    }
    
    // Ignore empty messages
    if (message.isEmpty()) {
        return;
    }
    
    if (isDebugMode()) {
        info("Discord message received: [" + author + "] " + message, true);
    }
    
    // Format the message for the game
    String gameMessage = formatDiscordMessage(message, author);
    
    // Send to game chat
    sendToGame("general", gameMessage, author);
}

void DiscordManagerImplementation::handleDiscordReady() {
    std::lock_guard<std::mutex> lock(discordRuntime.mutex);
    discordRuntime.gatewayConnected = true;
    discordRuntime.state = DiscordLifecycleState::Connected;
    discordRuntime.lastReadyMs = getDiscordNowMs();
    info("Discord Gateway connected.", true);
}

void DiscordManagerImplementation::handleDiscordError(const String& error) {
    this->error("Discord error: " + error);
    
    if (error.indexOf("connection") != -1 || error.indexOf("websocket") != -1 || error.indexOf("heartbeat") != -1) {
        ManagedReference<DiscordManager*> managerRef = _this.getReferenceUnsafeStaticCast();

        {
            std::lock_guard<std::mutex> lock(discordRuntime.mutex);
            discordRuntime.gatewayConnected = false;

            if (discordRuntime.state != DiscordLifecycleState::Stopped &&
                    discordRuntime.state != DiscordLifecycleState::Stopping) {
                discordRuntime.state = DiscordLifecycleState::Reconnecting;
            }
        }

        requestDiscordReconnect(this, managerRef, "Discord error reported by DPP");
    }
}

String DiscordManagerImplementation::formatGameMessage(const String& message, const String& author) {
    if (isDebugMode()) {
        info("formatGameMessage: author='" + author + "' message='" + message + "'", true);
    }
    
    try {
        String escapedMessage = escapeDiscordMarkdown(message);
        if (isDebugMode()) {
            info("formatGameMessage: escaped message='" + escapedMessage + "'", true);
        }
        
        String result = "**[" + author + "]** " + escapedMessage;
        if (isDebugMode()) {
            info("formatGameMessage: final result='" + result + "'", true);
        }
        
        return result;
    } catch (const std::exception& e) {
        error("Exception in formatGameMessage: " + String(e.what()));
        throw;
    } catch (...) {
        error("Unknown exception in formatGameMessage");
        throw;
    }
}

String DiscordManagerImplementation::formatDiscordMessage(const String& message, const String& author) {
    // Format: Author: message
    return author + ": " + message;
}

String DiscordManagerImplementation::escapeDiscordMarkdown(const String& text) {
    if (isDebugMode()) {
        info("escapeDiscordMarkdown: input='" + text + "'", true);
    }
    
    try {
        // Character-by-character escaping to avoid regex issues
        String result = "";
        
        for (int i = 0; i < text.length(); i++) {
            char c = text.charAt(i);
            
            switch (c) {
                case '\\':
                    result += "\\\\";
                    break;
                case '*':
                    result += "\\*";
                    break;
                case '_':
                    result += "\\_";
                    break;
                case '`':
                    result += "\\`";
                    break;
                default:
                    result += c;
                    break;
            }
        }
        
        if (isDebugMode()) {
            info("escapeDiscordMarkdown: final result='" + result + "'", true);
        }
        
        return result;
    } catch (const std::exception& e) {
        error("Exception in escapeDiscordMarkdown: " + String(e.what()));
        throw;
    } catch (...) {
        error("Unknown exception in escapeDiscordMarkdown");
        throw;
    }
}

String DiscordManagerImplementation::truncateMessage(const String& message, int maxLength) {
    if (isDebugMode()) {
        info("truncateMessage: message length=" + String::valueOf(message.length()) + " maxLength=" + String::valueOf(maxLength), true);
    }
    
    try {
        if (maxLength <= 0) {
            if (isDebugMode()) {
                info("truncateMessage: maxLength <= 0, returning empty string", true);
            }
            return "";
        }
        
        if (message.isEmpty() || message.length() <= maxLength) {
            if (isDebugMode()) {
                info("truncateMessage: message fits, returning as-is", true);
            }
            return message;
        }
        
        if (maxLength <= 3) {
            String result = message.subString(0, maxLength);
            if (isDebugMode()) {
                info("truncateMessage: maxLength <= 3, result='" + result + "'", true);
            }
            return result;
        }
        
        String result = message.subString(0, maxLength - 3) + "...";
        if (isDebugMode()) {
            info("truncateMessage: truncated result='" + result + "'", true);
        }
        
        return result;
    } catch (const std::exception& e) {
        error("Exception in truncateMessage: " + String(e.what()));
        throw;
    } catch (...) {
        error("Unknown exception in truncateMessage");
        throw;
    }
}





bool DiscordManagerImplementation::isConnected() {
#ifdef WITH_DISCORD_INTEGRATION
    std::lock_guard<std::mutex> lock(discordRuntime.mutex);
    bool result = isEnabled() &&
        discordRuntime.gatewayConnected &&
        discordRuntime.state == DiscordLifecycleState::Connected &&
        !discordRuntime.shutdownRequested;
    if (isDebugMode()) {
        info(
            "isConnected check: enabled=" + String::valueOf(isEnabled()) +
            " gatewayConnected=" + String::valueOf(discordRuntime.gatewayConnected) +
            " lifecycle=" + discordLifecycleStateToString(discordRuntime.state) +
            " result=" + String::valueOf(result),
            true
        );
    }
    return result;
#else
    if (isDebugMode()) {
        info("isConnected: Discord integration not compiled in", true);
    }
    return false;
#endif
}

String DiscordManagerImplementation::getConnectionStatus() {
    if (!isEnabled()) {
        return "Disabled";
    }

#ifdef WITH_DISCORD_INTEGRATION
    std::lock_guard<std::mutex> lock(discordRuntime.mutex);
    return discordLifecycleStateToString(discordRuntime.state);
#else
    return "Disconnected";
#endif
}



// Helper method to check if a channel should be relayed
bool DiscordManagerImplementation::shouldRelayChannel(const String& channel) {
    // Simple relay - relay all channels since we're using a single Discord channel
    return true;
}
