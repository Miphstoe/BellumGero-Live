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
#include <memory>
#include <thread>
#include <mutex>

// Global Discord bot instance and related variables
static std::unique_ptr<dpp::cluster> discordBot;
static std::thread discordThread;
static std::mutex discordMutex;
static bool discordConnected = false;
static bool shutdownRequested = false;


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
    try {
        std::lock_guard<std::mutex> lock(discordMutex);
        
        if (isDebugMode()) {
            info("Creating Discord cluster with DPP library", true);
        }
        
        // Create the Discord bot with required intents
        discordBot = std::make_unique<dpp::cluster>(getBotToken().toCharArray(), dpp::i_default_intents | dpp::i_message_content);
        
        // Set up event handlers
        discordBot->on_ready([this](const dpp::ready_t& event) {
            if (isDebugMode()) {
                info("Discord on_ready callback triggered", true);
            }
            
            std::lock_guard<std::mutex> lock(discordMutex);
            discordConnected = true;
            info("Discord bot connected and ready!", true);
            
            if (isDebugMode()) {
                info("Connected as: " + String(discordBot->me.username), true);
                info("Bot ID: " + String::valueOf(discordBot->me.id), true);
            }
        });
        
        discordBot->on_message_create([this](const dpp::message_create_t& event) {
            if (event.msg.author.is_bot()) {
                return; // Ignore bot messages
            }
            
            handleDiscordMessage(
                String::valueOf(event.msg.channel_id), 
                event.msg.content,
                event.msg.author.username,
                String::valueOf(event.msg.author.id)
            );
        });
        
        discordBot->on_log([this](const dpp::log_t& event) {
            if (event.severity >= dpp::ll_error) {
                handleDiscordError(event.message);
            } else if (isDebugMode() && event.severity >= dpp::ll_debug) {
                info("Discord Debug: " + String(event.message), true);
            }
        });
        
        // Start the bot in a separate thread
        if (isDebugMode()) {
            info("Starting Discord bot thread", true);
        }
        
        discordThread = std::thread([this]() {
            try {
                if (isDebugMode()) {
                    info("Discord bot thread started, calling dpp::cluster::start", true);
                }
                discordBot->start(dpp::st_wait);
                if (isDebugMode()) {
                    info("Discord bot thread finished", true);
                }
            } catch (const std::exception& e) {
                error("Discord bot thread exception: " + String(e.what()));
            }
        });
        
        info("Discord bot started successfully.", true);
        
    } catch (const std::exception& e) {
        error("Failed to start Discord bot: " + String(e.what()));
        setEnabled(false);
    }
#else
    error("Discord integration not compiled in. Please rebuild with DPP library support.");
    setEnabled(false);
#endif
}

void DiscordManagerImplementation::stop() {
    if (!isEnabled()) {
        return;
    }
    
    info("Stopping Discord bot...", true);
    
#ifdef WITH_DISCORD_INTEGRATION
    {
        std::lock_guard<std::mutex> lock(discordMutex);
        shutdownRequested = true;
        discordConnected = false;
    }
    
    if (discordThread.joinable()) {
        discordThread.join();
    }
    
    {
        std::lock_guard<std::mutex> lock(discordMutex);
        discordBot.reset();
    }
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
        std::lock_guard<std::mutex> lock(discordMutex);
        if (discordBot && discordConnected) {
            // Send the message asynchronously
            discordBot->message_create(
                dpp::message(std::stoull(discordChannelId.toCharArray()), formattedMessage.toCharArray())
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
    std::lock_guard<std::mutex> lock(discordMutex);
    discordConnected = true;
    info("Discord bot connected and ready!", true);
}

void DiscordManagerImplementation::handleDiscordError(const String& error) {
    this->error("Discord error: " + error);
    
    // If it's a critical error, mark as disconnected
    if (error.indexOf("connection") != -1 || error.indexOf("websocket") != -1) {
        std::lock_guard<std::mutex> lock(discordMutex);
        discordConnected = false;
        // The bot will automatically try to reconnect
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
    std::lock_guard<std::mutex> lock(discordMutex);
    bool result = isEnabled() && discordConnected;
    if (isDebugMode()) {
        info("isConnected check: enabled=" + String::valueOf(isEnabled()) + " discordConnected=" + String::valueOf(discordConnected) + " result=" + String::valueOf(result), true);
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
    } else if (isConnected()) {
        return "Connected";
    } else {
        return "Disconnected";
    }
}



// Helper method to check if a channel should be relayed
bool DiscordManagerImplementation::shouldRelayChannel(const String& channel) {
    // Simple relay - relay all channels since we're using a single Discord channel
    return true;
}