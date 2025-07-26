/**
 * Chat Interface Control Add-in Main JavaScript
 * Handles all chat functionality and AL communication
 */

// Global variables for managing the chat state
var isProcessing = false;
var typingIndicatorVisible = false;

/**
 * Send a message from the chat interface to AL
 */
function sendMessage() {
    const input = document.getElementById('messageInput');
    const message = input.value.trim();

    if (!message || isProcessing) return;

    // Clear the input and adjust height
    input.value = '';
    adjustTextareaHeight(input);

    // Set processing state
    isProcessing = true;
    const sendBtn = document.getElementById('sendBtn');
    if (sendBtn) {
        sendBtn.disabled = true;
    }

    // Send message to AL using the control add-in interface
    try {
        if (typeof Microsoft !== 'undefined' && Microsoft.Dynamics && Microsoft.Dynamics.NAV && Microsoft.Dynamics.NAV.InvokeExtensibilityMethod) {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('MessageSent', [message]);
        } else {
            console.error('Microsoft.Dynamics.NAV.InvokeExtensibilityMethod not available');
            resetProcessingState();
        }
    } catch (error) {
        console.error('Error sending message to AL:', error);
        resetProcessingState();
    }
}

/**
 * Clear all messages from the chat
 */
function clearChat() {
    try {
        if (typeof Microsoft !== 'undefined' && Microsoft.Dynamics && Microsoft.Dynamics.NAV && Microsoft.Dynamics.NAV.InvokeExtensibilityMethod) {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ChatCleared', null);
        } else {
            console.error('Microsoft.Dynamics.NAV.InvokeExtensibilityMethod not available');
        }
    } catch (error) {
        console.error('Error clearing chat:', error);
    }
}

/**
 * Add a message to the chat interface (called from AL)
 * @param {string} messageType - Type of message (User, Assistant, System)
 * @param {string} messageText - The message content
 * @param {string} messageTime - Formatted time string
 */
function AddMessage(messageType, messageText, messageTime) {
    const messagesContainer = document.getElementById('chatMessages');
    if (!messagesContainer) return;

    // Create message element
    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${messageType.toLowerCase()}`;

    // Create message bubble
    const bubbleDiv = document.createElement('div');
    bubbleDiv.className = 'message-bubble';
    bubbleDiv.innerHTML = messageText; // Using innerHTML to support HTML formatting from AI

    // Create message meta information
    const metaDiv = document.createElement('div');
    metaDiv.className = 'message-meta';

    const senderSpan = document.createElement('span');
    senderSpan.className = 'message-sender';
    senderSpan.textContent = getSenderName(messageType);

    const timeSpan = document.createElement('span');
    timeSpan.textContent = messageTime;

    metaDiv.appendChild(senderSpan);
    metaDiv.appendChild(timeSpan);

    // Assemble message
    messageDiv.appendChild(bubbleDiv);
    messageDiv.appendChild(metaDiv);

    // Remove typing indicator if visible
    if (typingIndicatorVisible) {
        hideTypingIndicator();
    }

    // Add to messages container
    messagesContainer.appendChild(messageDiv);

    // Scroll to bottom
    messagesContainer.scrollTop = messagesContainer.scrollHeight;

    // Reset processing state
    resetProcessingState();
}

/**
 * Clear all messages from the interface (called from AL)
 */
function ClearMessages() {
    const messagesContainer = document.getElementById('chatMessages');
    if (messagesContainer) {
        messagesContainer.innerHTML = '';
    }

    // Hide typing indicator
    if (typingIndicatorVisible) {
        hideTypingIndicator();
    }

    // Reset processing state
    resetProcessingState();
}

/**
 * Load chat history from JSON (called from AL)
 * @param {string} messagesJson - JSON array of messages
 */
function LoadChatHistory(messagesJson) {
    try {
        const messages = JSON.parse(messagesJson);
        const messagesContainer = document.getElementById('chatMessages');

        if (!messagesContainer) return;

        // Clear existing messages
        messagesContainer.innerHTML = '';

        // Add each message
        messages.forEach(function(msg) {
            if (msg.messageType && msg.messageText && msg.messageDateTime) {
                const formattedTime = formatTime(msg.messageDateTime);
                AddMessage(msg.messageType, msg.messageText, formattedTime);
            }
        });

    } catch (error) {
        console.error('Error loading chat history:', error);
    }
}

/**
 * Show or hide the typing indicator (called from AL)
 * @param {boolean} show - Whether to show the typing indicator
 */
function ShowTypingIndicator(show) {
    if (show) {
        showTypingIndicator();
    } else {
        hideTypingIndicator();
    }
}

/**
 * Show the typing indicator
 */
function showTypingIndicator() {
    if (typingIndicatorVisible) return;

    const messagesContainer = document.getElementById('chatMessages');
    if (!messagesContainer) return;

    const typingDiv = document.createElement('div');
    typingDiv.className = 'typing-indicator';
    typingDiv.id = 'typingIndicator';
    typingDiv.innerHTML = `
        <span>AI is thinking</span>
        <div class="typing-dots">
            <div class="typing-dot"></div>
            <div class="typing-dot"></div>
            <div class="typing-dot"></div>
        </div>
    `;

    messagesContainer.appendChild(typingDiv);
    messagesContainer.scrollTop = messagesContainer.scrollHeight;

    typingIndicatorVisible = true;
}

/**
 * Hide the typing indicator
 */
function hideTypingIndicator() {
    const typingIndicator = document.getElementById('typingIndicator');
    if (typingIndicator) {
        typingIndicator.remove();
    }
    typingIndicatorVisible = false;
}

/**
 * Reset the processing state
 */
function resetProcessingState() {
    isProcessing = false;
    const sendBtn = document.getElementById('sendBtn');
    if (sendBtn) {
        sendBtn.disabled = false;
    }
}

/**
 * Adjust textarea height based on content
 * @param {HTMLTextAreaElement} textarea - The textarea element
 */
function adjustTextareaHeight(textarea) {
    textarea.style.height = 'auto';
    textarea.style.height = Math.min(textarea.scrollHeight, 120) + 'px';
}

/**
 * Get the display name for a message sender
 * @param {string} messageType - The message type
 * @returns {string} The display name
 */
function getSenderName(messageType) {
    switch (messageType) {
        case 'User':
            return 'You';
        case 'Assistant':
            return 'AI Assistant';
        case 'System':
            return 'System';
        default:
            return 'Unknown';
    }
}

/**
 * Format a datetime string to HH:MM format
 * @param {string} dateTimeText - The datetime string
 * @returns {string} Formatted time
 */
function formatTime(dateTimeText) {
    try {
        const date = new Date(dateTimeText);
        return date.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
            hour12: false
        });
    } catch (error) {
        return '--:--';
    }
}

// Debug function for testing
function testConnection() {
    console.log('Testing connection to AL...');
    if (typeof Microsoft !== 'undefined' && Microsoft.Dynamics && Microsoft.Dynamics.NAV && Microsoft.Dynamics.NAV.InvokeExtensibilityMethod) {
        console.log('Microsoft.Dynamics.NAV.InvokeExtensibilityMethod is available');
        try {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('MessageSent', ['Test message from JavaScript']);
        } catch (error) {
            console.error('Error calling AL method:', error);
        }
    } else {
        console.error('Microsoft.Dynamics.NAV.InvokeExtensibilityMethod not available');
    }
}
