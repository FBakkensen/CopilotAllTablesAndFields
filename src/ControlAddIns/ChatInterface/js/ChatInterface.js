/**
 * Chat Interface Control Add-in Main JavaScript
 * Handles all chat functionality and AL communication
 */

// Global variables for managing the chat state
var isProcessing = false;
var typingIndicatorVisible = false;

/**
 * Process message content to handle code blocks and improve table formatting
 * @param {string} content - The raw message content
 * @returns {string} Processed HTML content
 */
function processMessageContent(content) {
    if (!content) return content;

    let processed = content;

    // Handle triple backtick code blocks first (including potential language specifications)
    processed = processed.replace(/```(\w+)?\n?([\s\S]*?)\n?```/g, function(match, language, code) {
        const trimmedCode = code.trim();
        const escapedCode = escapeHtml(trimmedCode);

        // Check if this looks like a table (contains pipe characters in a structured way)
        if (isTableContent(trimmedCode)) {
            return formatAsTable(trimmedCode);
        }

        return `<div class="code-block">${escapedCode}</div>`;
    });

    // Handle single backtick inline code (but not if it's already inside HTML tags)
    processed = processed.replace(/(?<!<[^>]*)`([^`\n]+)`(?![^<]*>)/g, function(match, code) {
        const escapedCode = escapeHtml(code.trim());
        return `<code>${escapedCode}</code>`;
    });

    // Handle pipe-separated tables that aren't already in code blocks
    if (!processed.includes('<div class="code-block">') && !processed.includes('<div class="table-container">')) {
        if (isTableContent(processed)) {
            processed = formatAsTable(processed);
        }
    }

    return processed;
}

/**
 * Check if content looks like a table (pipe-separated values)
 * @param {string} content - Content to check
 * @returns {boolean} True if it looks like a table
 */
function isTableContent(content) {
    const lines = content.split('\n').filter(line => line.trim());
    if (lines.length < 2) return false;

    // Check if multiple lines contain pipe characters
    const linesWithPipes = lines.filter(line => {
        const trimmed = line.trim();
        // Exclude separator lines (mostly dashes and pipes)
        if (trimmed.match(/^\|[\s\-\|]*\|$/)) return false;
        return trimmed.includes('|') && trimmed.split('|').length > 2;
    });

    // Must have at least 2 lines with pipes and at least 50% of lines should have pipes
    return linesWithPipes.length >= 2 && (linesWithPipes.length / lines.length) >= 0.4;
}

/**
 * Format pipe-separated content as an HTML table
 * @param {string} content - Pipe-separated content
 * @returns {string} HTML table
 */
function formatAsTable(content) {
    const lines = content.split('\n')
        .map(line => line.trim())
        .filter(line => {
            if (!line || !line.includes('|')) return false;
            // Skip separator lines (lines that are mostly dashes and pipes)
            return !line.match(/^\|[\s\-\|]*\|$/);
        });

    if (lines.length === 0) return content;

    let tableHtml = '<div class="table-container"><table>';
    let isFirstLine = true;

    lines.forEach((line, index) => {
        const cells = line.split('|')
            .map(cell => cell.trim())
            .filter((cell, cellIndex, array) => {
                // Remove empty cells at start and end (common in pipe tables)
                return !(cellIndex === 0 && cell === '') && !(cellIndex === array.length - 1 && cell === '');
            });

        if (cells.length === 0) return;

        const tagName = isFirstLine ? 'th' : 'td';
        const row = cells
            .map(cell => `<${tagName}>${escapeHtml(cell)}</${tagName}>`)
            .join('');

        tableHtml += `<tr>${row}</tr>`;
        isFirstLine = false;
    });

    tableHtml += '</table></div>';

    return tableHtml;
}

/**
 * Escape HTML characters to prevent XSS
 * @param {string} text - Text to escape
 * @returns {string} Escaped text
 */
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

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

    // Process the message content to handle code blocks and tables
    const processedMessage = processMessageContent(messageText);
    bubbleDiv.innerHTML = processedMessage;

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
        <div class="typing-content">
            <div class="typing-avatar">🤖</div>
            <div class="typing-bubble">
                <span class="typing-text">AI is thinking</span>
                <div class="typing-dots">
                    <div class="typing-dot"></div>
                    <div class="typing-dot"></div>
                    <div class="typing-dot"></div>
                </div>
            </div>
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
